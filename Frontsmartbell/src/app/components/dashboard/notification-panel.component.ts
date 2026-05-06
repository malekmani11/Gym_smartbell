import { Component, signal, computed, output } from '@angular/core';
import { CommonModule } from '@angular/common';

export interface Notification {
  id: string;
  type: 'expiry' | 'payment' | 'member' | 'ai' | 'alert';
  title: string;
  message: string;
  time: string;
  read: boolean;
  actionLabel?: string;
}

@Component({
  selector: 'app-notification-panel',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './notification-panel.component.html',
})
export class NotificationPanelComponent {

  actionTriggered = output<{ type: string; notification: Notification }>();

  isOpen = signal(false);

  notifications = signal<Notification[]>([
    {
      id: 'n1',
      type: 'expiry',
      title: 'Abonnement expirant',
      message: 'Jean Dupont — Plan Standard expire dans 3 jours.',
      time: 'Il y a 5 min',
      read: false,
      actionLabel: 'Envoyer rappel'
    },
    {
      id: 'n2',
      type: 'payment',
      title: 'Paiement reçu',
      message: 'Marie Curie a renouvelé son abonnement Yoga Premium.',
      time: 'Il y a 22 min',
      read: false,
      actionLabel: 'Voir reçu'
    },
    {
      id: 'n3',
      type: 'member',
      title: 'Nouveau membre',
      message: "Lucas Martin vient de s'inscrire au plan CrossFit Elite.",
      time: 'Il y a 1h',
      read: false,
      actionLabel: 'Voir profil'
    },
    {
      id: 'n4',
      type: 'ai',
      title: 'Alerte Gemini AI',
      message: '3 membres à risque de churn détectés cette semaine.',
      time: 'Il y a 2h',
      read: true,
      actionLabel: 'Voir analyse'
    },
    {
      id: 'n5',
      type: 'alert',
      title: 'Cours complet',
      message: 'CrossFit WOD 18h00 — Capacité maximale atteinte (20/20).',
      time: 'Il y a 3h',
      read: true,
      actionLabel: 'Gérer le planning'
    }
  ]);

  unreadCount = computed(() => this.notifications().filter(n => !n.read).length);

  toggle() {
    this.isOpen.update(v => !v);
  }

  close() {
    this.isOpen.set(false);
  }

  markAllRead() {
    this.notifications.update(list => list.map(n => ({ ...n, read: true })));
  }

  onAction(notification: Notification) {
    this.notifications.update(list =>
      list.map(n => n.id === notification.id ? { ...n, read: true } : n)
    );
    this.actionTriggered.emit({ type: notification.type, notification });
    this.close();
  }

  getTypeIcon(type: string): string {
    switch (type) {
      case 'expiry':  return 'fas fa-clock text-yellow-400';
      case 'payment': return 'fas fa-check-circle text-green-400';
      case 'member':  return 'fas fa-user-plus text-blue-400';
      case 'ai':      return 'fas fa-robot text-purple-400';
      case 'alert':   return 'fas fa-exclamation-circle text-red-400';
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
      default:        return 'bg-white/5 border-white/10';
    }
  }
}
