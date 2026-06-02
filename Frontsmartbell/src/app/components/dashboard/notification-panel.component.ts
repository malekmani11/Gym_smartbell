import { Component, signal, computed, output, inject, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { NotificationApiService } from '../../services/notification-api.service';
import { NotificationDTO } from '../../models/api.models';

export interface Notification {
  id: string;
  type: 'expiry' | 'payment' | 'member' | 'ai' | 'alert' | 'info';
  title: string;
  message: string;
  time: string;
  read: boolean;
  actionLabel?: string;
  actionRoute?: string;
}

@Component({
  selector: 'app-notification-panel',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './notification-panel.component.html',
})
export class NotificationPanelComponent implements OnInit, OnDestroy {
  private notifApi = inject(NotificationApiService);
  private router   = inject(Router);

  actionTriggered = output<{ type: string; notification: Notification }>();

  isOpen       = signal(false);
  loading      = signal(true);
  notifications = signal<Notification[]>([]);

  unreadCount = computed(() => this.notifications().filter(n => !n.read).length);

  private refreshInterval: any;

  ngOnInit() {
    this.load();
    // Auto-refresh toutes les 30 secondes
    this.refreshInterval = setInterval(() => this.load(false), 30_000);
  }

  ngOnDestroy() {
    if (this.refreshInterval) clearInterval(this.refreshInterval);
  }

  load(showLoader = true) {
    if (showLoader) this.loading.set(true);
    this.notifApi.getAll().subscribe({
      next: (dtos) => {
        const mapped = dtos
          .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
          .slice(0, 15)
          .map(d => this._map(d));
        this.notifications.set(mapped);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  toggle() { this.isOpen.update(v => !v); }
  close()  { this.isOpen.set(false); }

  markAllRead() {
    this.notifApi.markAllAsRead().subscribe({
      next: () => {
        this.notifications.update(list => list.map(n => ({ ...n, read: true })));
      }
    });
  }

  onAction(notif: Notification) {
    this.notifApi.markAsRead(Number(notif.id)).subscribe();
    this.notifications.update(list =>
      list.map(n => n.id === notif.id ? { ...n, read: true } : n)
    );
    if (notif.actionRoute) this.router.navigate([notif.actionRoute]);
    this.actionTriggered.emit({ type: notif.type, notification: notif });
    this.close();
  }

  onDelete(id: string, event: MouseEvent) {
    event.stopPropagation();
    this.notifApi.delete(Number(id)).subscribe({
      next: () => this.notifications.update(list => list.filter(n => n.id !== id))
    });
  }

  viewAll() {
    this.router.navigate(['/notifications']);
    this.close();
  }

  getTypeIcon(type: string): string {
    switch (type) {
      case 'expiry':  return 'fas fa-clock text-yellow-400';
      case 'payment': return 'fas fa-check-circle text-green-400';
      case 'member':  return 'fas fa-user-plus text-blue-400';
      case 'ai':      return 'fas fa-robot text-purple-400';
      case 'alert':   return 'fas fa-exclamation-circle text-red-400';
      case 'info':    return 'fas fa-info-circle text-blue-400';
      default:        return 'fas fa-bell text-gray-400';
    }
  }

  getTypeBg(type: string): string {
    switch (type) {
      case 'expiry':  return 'bg-yellow-500/10 border-yellow-500/20';
      case 'payment': return 'bg-green-500/10 border-green-500/20';
      case 'member':  return 'bg-blue-500/10 border-blue-500/20';
      case 'ai':      return 'bg-purple-500/10 border-purple-500/20';
      case 'alert':   return 'bg-red-500/10 border-red-500/20';
      case 'info':    return 'bg-blue-500/10 border-blue-500/20';
      default:        return 'bg-white/5 border-white/10';
    }
  }

  getActionColor(type: string): string {
    switch (type) {
      case 'ai':      return 'text-purple-400 hover:text-purple-300';
      case 'payment': return 'text-green-400 hover:text-green-300';
      case 'alert':   return 'text-red-400 hover:text-red-300';
      case 'expiry':  return 'text-yellow-400 hover:text-yellow-300';
      default:        return 'text-gold-main hover:text-gold-light';
    }
  }

  private _map(dto: NotificationDTO): Notification {
    const title   = (dto.title   ?? '').toLowerCase();
    const message = (dto.message ?? '').toLowerCase();
    const text    = title + ' ' + message;

    // Détecter le type selon les mots-clés
    let type: Notification['type'] = 'info';
    let actionLabel = 'Voir →';
    let actionRoute = '/notifications';

    if (dto.type === 'WARNING' || text.includes('expir') || text.includes('renouveler')) {
      type = 'expiry';
      actionLabel = 'Envoyer rappel →';
      actionRoute = '/members';
    } else if (dto.type === 'ALERT') {
      type = 'alert';
      actionLabel = 'Voir →';
      actionRoute = '/notifications';
    } else if (dto.type === 'REMINDER' || text.includes('paiement') || text.includes('payment')) {
      type = 'payment';
      actionLabel = 'Voir paiement →';
      actionRoute = '/payments';
    } else if (text.includes('membre') || text.includes('inscri') || text.includes('member')) {
      type = 'member';
      actionLabel = 'Voir profil →';
      actionRoute = '/members';
    } else if (text.includes('coach')) {
      type = 'member';
      actionLabel = 'Voir coach →';
      actionRoute = '/coaches';
    } else if (text.includes('cours') || text.includes('complet') || text.includes('planning')) {
      type = 'alert';
      actionLabel = 'Voir planning →';
      actionRoute = '/schedule';
    }

    return {
      id:          String(dto.id),
      type,
      title:       dto.title,
      message:     dto.message,
      time:        this._timeAgo(dto.createdAt),
      read:        dto.isRead,
      actionLabel,
      actionRoute,
    };
  }

  private _timeAgo(dateStr: string): string {
    const diff = Math.floor((Date.now() - new Date(dateStr).getTime()) / 1000);
    if (diff < 60)    return `il y a ${diff}s`;
    if (diff < 3600)  return `il y a ${Math.floor(diff / 60)}min`;
    if (diff < 86400) return `il y a ${Math.floor(diff / 3600)}h`;
    return `il y a ${Math.floor(diff / 86400)}j`;
  }
}
