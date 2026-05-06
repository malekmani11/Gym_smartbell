import { Component, OnInit, OnDestroy, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { NotificationApiService } from '../../services/notification-api.service';
import { MemberApiService } from '../../services/member-api.service';
import { NotificationDTO, NotificationType, CreateNotificationRequest } from '../../models/api.models';
import { ToastService } from '../../services/toast.service';

@Component({
  selector: 'app-notifications',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './notifications.component.html',
  styleUrl: './notifications.component.css'
})
export class NotificationsComponent implements OnInit, OnDestroy {
  private notifApi   = inject(NotificationApiService);
  private memberApi  = inject(MemberApiService);
  private toast      = inject(ToastService);

  notifications = signal<NotificationDTO[]>([]);
  members       = signal<any[]>([]);
  loading       = signal(true);
  
  // Filters
  filterType   = signal<string>('ALL');
  filterUnread = signal<boolean>(false);

  // Modal
  showCreateModal = signal(false);
  
  // Create Form
  newNotif = signal<CreateNotificationRequest>({
    title: '',
    message: '',
    type: 'INFO',
    targetAll: true
  });
  targetType = signal<'ALL' | 'ROLE' | 'MEMBER'>('ALL');

  private refreshInterval: any;

  filteredNotifications = computed(() => {
    let list = this.notifications();
    
    if (this.filterUnread()) {
      list = list.filter(n => !n.isRead);
    }
    
    if (this.filterType() !== 'ALL') {
      list = list.filter(n => n.type === this.filterType());
    }
    
    return list.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  });

  stats = computed(() => {
    const all = this.notifications();
    const today = new Date().setHours(0,0,0,0);
    return {
      total: all.length,
      unread: all.filter(n => !n.isRead).length,
      today: all.filter(n => new Date(n.createdAt).setHours(0,0,0,0) === today).length
    };
  });

  ngOnInit() {
    this.loadNotifications();
    this.loadMembers();
    
    // Auto-refresh every 30s
    this.refreshInterval = setInterval(() => {
      this.loadNotifications(false);
    }, 30000);
  }

  ngOnDestroy() {
    if (this.refreshInterval) clearInterval(this.refreshInterval);
  }

  loadNotifications(showLoader = true) {
    if (showLoader) this.loading.set(true);
    this.notifApi.getAll().subscribe({
      next: (data) => {
        this.notifications.set(data);
        this.loading.set(false);
      },
      error: () => {
        console.warn('Notifications: load failed');
        this.loading.set(false);
      }
    });
  }

  loadMembers() {
    this.memberApi.getAll().subscribe({
      next: (res) => this.members.set(res.content),
      error: () => console.error('Could not load members for notification target')
    });
  }

  markAsRead(id: number) {
    this.notifApi.markAsRead(id).subscribe({
      next: () => {
        this.notifications.update(list => 
          list.map(n => n.id === id ? { ...n, isRead: true } : n)
        );
      }
    });
  }

  markAllAsRead() {
    this.notifApi.markAllAsRead().subscribe({
      next: () => {
        this.notifications.update(list => list.map(n => ({ ...n, isRead: true })));
        this.toast.success('Succès', 'Toutes les notifications sont marquées comme lues');
      }
    });
  }

  deleteNotification(id: number) {
    this.notifApi.delete(id).subscribe({
      next: () => this.notifications.update(list => list.filter(n => n.id !== id))
    });
  }

  deleteAll() {
    if (!confirm('Supprimer toutes les notifications ?')) return;
    this.notifApi.deleteAll().subscribe({
      next: () => {
        this.notifications.set([]);
        this.toast.success('Supprimé', 'Toutes les notifications ont été supprimées');
      }
    });
  }

  openCreateModal() {
    this.newNotif.set({
      title: '',
      message: '',
      type: 'INFO',
      targetAll: true
    });
    this.targetType.set('ALL');
    this.showCreateModal.set(true);
  }

  sendNotification() {
    const req = { ...this.newNotif() };
    
    // Adjust request based on target type
    if (this.targetType() === 'ALL') {
      req.targetAll = true;
      delete req.userId;
      delete req.roleName;
    } else if (this.targetType() === 'ROLE') {
      req.targetAll = false;
      delete req.userId;
    } else {
      req.targetAll = false;
      delete req.roleName;
    }

    if (!req.title || !req.message) {
      this.toast.warning('Champs requis', 'Veuillez remplir le titre et le message');
      return;
    }

    this.notifApi.send(req).subscribe({
      next: (created) => {
        this.notifications.update(list => [...created, ...list]);
        this.toast.success('Succès', `Notification envoyée à ${created.length} utilisateur(s)`);
        this.showCreateModal.set(false);
      },
      error: () => this.toast.error('Erreur', 'Échec de l\'envoi')
    });
  }

  getTimeAgo(dateStr: string): string {
    const date = new Date(dateStr);
    const now = new Date();
    const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

    if (diffInSeconds < 60) return `il y a ${diffInSeconds}s`;
    
    const diffInMinutes = Math.floor(diffInSeconds / 60);
    if (diffInMinutes < 60) return `il y a ${diffInMinutes}min`;
    
    const diffInHours = Math.floor(diffInMinutes / 60);
    if (diffInHours < 24) return `il y a ${diffInHours}h`;
    
    const diffInDays = Math.floor(diffInHours / 24);
    return `il y a ${diffInDays}j`;
  }

  getTypeIcon(type: NotificationType): string {
    switch (type) {
      case 'INFO':    return '🔵';
      case 'WARNING': return '🟠';
      case 'ALERT':   return '🔴';
      case 'REMINDER':return '🟣';
      default:        return '⚪';
    }
  }

  targetLabel(n: NotificationDTO): string {
    if (n.targetAll) return '📢 Tous les utilisateurs';
    if (n.targetRole === 'ROLE_MEMBER') return '👥 Membres uniquement';
    if (n.targetRole === 'ROLE_COACH')  return '🏋️ Coachs uniquement';
    if (n.targetRole === 'ROLE_ADMIN')  return '🔑 Admins uniquement';
    if (n.targetUserId)                 return '👤 Membre spécifique';
    return '—';
  }

  getTypeColor(type: NotificationType): string {
    switch (type) {
      case 'INFO':    return '#3b82f6';
      case 'WARNING': return '#EF9F27';
      case 'ALERT':   return '#ef4444';
      case 'REMINDER':return '#a855f7';
      default:        return '#9ca3af';
    }
  }

  getFaIcon(type: NotificationType): string {
    switch (type) {
      case 'INFO':    return 'fas fa-info-circle';
      case 'WARNING': return 'fas fa-exclamation-triangle';
      case 'ALERT':   return 'fas fa-exclamation-circle';
      case 'REMINDER':return 'fas fa-bell';
      default:        return 'fas fa-info';
    }
  }
}
