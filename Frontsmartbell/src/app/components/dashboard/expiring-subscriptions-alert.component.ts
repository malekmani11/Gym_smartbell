import {
  Component,
  OnInit,
  signal,
  computed,
  inject,
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { ToastService } from '../../services/toast.service';
import { environment } from '../../../environments/environment';

interface ExpiringSubscription {
  id: number;
  user: {
    id: number;
    firstName: string;
    lastName: string;
  };
  plan: {
    name: string;
  };
  endDate: string;
  status: string;
}

@Component({
  selector: 'app-expiring-subscriptions-alert',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './expiring-subscriptions-alert.component.html',
  styleUrl: './expiring-subscriptions-alert.component.css',
})
export class ExpiringSubscriptionsAlertComponent implements OnInit {
  private http  = inject(HttpClient);
  private toast = inject(ToastService);

  // ── State ──────────────────────────────────────────────────────────────────
  isLoading      = signal(true);
  hasError       = signal(false);
  expiring       = signal<ExpiringSubscription[]>([]);
  notifyingIds   = signal<Set<number>>(new Set());
  notifiedIds    = signal<Set<number>>(new Set());
  isNotifyingAll = signal(false);

  // ── Computed ───────────────────────────────────────────────────────────────
  count = computed(() => this.expiring().length);

  criticalCount = computed(() =>
    this.expiring().filter(s => this.getDaysLeft(s.endDate) <= 2).length
  );

  skeletonRows = [1, 2, 3];

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  ngOnInit(): void {
    this.loadSubscriptions();
  }

  // ── Data ───────────────────────────────────────────────────────────────────
  private loadSubscriptions(): void {
    this.isLoading.set(true);
    this.hasError.set(false);

    this.http
      .get<any>(`${environment.apiUrl}/subscriptions`, {
        params: { size: '200', sort: 'endDate,asc' },
      })
      .subscribe({
        next: (res) => {
          const all: ExpiringSubscription[] =
            res?.content ?? (Array.isArray(res) ? res : []);

          const today    = new Date();
          today.setHours(0, 0, 0, 0);
          const horizon  = new Date(today);
          horizon.setDate(horizon.getDate() + 7);

          const filtered = all
            .filter(s => {
              if (s.status?.toUpperCase() !== 'ACTIVE') return false;
              const end = new Date(s.endDate);
              end.setHours(0, 0, 0, 0);
              return end >= today && end <= horizon;
            })
            .sort((a, b) =>
              new Date(a.endDate).getTime() - new Date(b.endDate).getTime()
            );

          this.expiring.set(filtered);
          this.isLoading.set(false);
        },
        error: () => {
          this.hasError.set(false);
          this.isLoading.set(false);
          console.warn('Expiring subscriptions: load failed');
        },
      });
  }

  retry(): void {
    this.loadSubscriptions();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  getDaysLeft(endDate: string): number {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const end = new Date(endDate);
    end.setHours(0, 0, 0, 0);
    const diff = Math.round((end.getTime() - today.getTime()) / 86_400_000);
    return diff < 0 ? 0 : diff;
  }

  getUrgencyColor(days: number): 'red' | 'orange' | 'amber' {
    if (days <= 2) return 'red';
    if (days <= 5) return 'orange';
    return 'amber';
  }

  getInitials(sub: ExpiringSubscription): string {
    const f = sub.user?.firstName?.[0] ?? '';
    const l = sub.user?.lastName?.[0] ?? '';
    return (f + l).toUpperCase() || '?';
  }

  formatDate(dateStr: string): string {
    const d = new Date(dateStr);
    return d.toLocaleDateString('fr-FR', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    });
  }

  isNotifying(userId: number): boolean {
    return this.notifyingIds().has(userId);
  }

  isNotified(userId: number): boolean {
    return this.notifiedIds().has(userId);
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  sendReminder(sub: ExpiringSubscription): void {
    const memberId = sub.user.id;
    if (this.isNotifying(memberId) || this.isNotified(memberId)) return;

    const days = this.getDaysLeft(sub.endDate);
    this.notifyingIds.update(s => new Set([...s, memberId]));

    this.http
      .post(`${environment.apiUrl}/notifications`, {
        title:    'Abonnement expirant',
        message:  `Bonjour ${sub.user.firstName}, votre abonnement "${sub.plan?.name ?? 'Gym'}" expire dans ${days} jour(s). Renouvelez-le dès maintenant.`,
        type:     'REMINDER',
        targetAll: false,
        userId:   memberId,
      })
      .subscribe({
        next: () => {
          this.notifyingIds.update(s => { const n = new Set(s); n.delete(memberId); return n; });
          this.notifiedIds.update(s => new Set([...s, memberId]));
          this.toast.success('Notification envoyée', `Rappel envoyé à ${sub.user.firstName} ${sub.user.lastName}.`);
        },
        error: () => {
          this.notifyingIds.update(s => { const n = new Set(s); n.delete(memberId); return n; });
          this.toast.error('Échec', 'Impossible d\'envoyer la notification.');
        },
      });
  }

  sendReminderAll(): void {
    if (this.isNotifyingAll()) return;
    const pending = this.expiring().filter(
      s => !this.isNotified(s.user.id) && !this.isNotifying(s.user.id)
    );
    if (!pending.length) return;

    this.isNotifyingAll.set(true);
    let done = 0;

    for (const sub of pending) {
      const days = this.getDaysLeft(sub.endDate);
      this.http
        .post(`${environment.apiUrl}/notifications`, {
          title:    'Abonnement expirant',
          message:  `Bonjour ${sub.user.firstName}, votre abonnement "${sub.plan?.name ?? 'Gym'}" expire dans ${days} jour(s). Renouvelez-le dès maintenant.`,
          type:     'REMINDER',
          targetAll: false,
          userId:   sub.user.id,
        })
        .subscribe({
          next: () => {
            this.notifiedIds.update(s => new Set([...s, sub.user.id]));
            done++;
            if (done === pending.length) {
              this.isNotifyingAll.set(false);
              this.toast.success('Notifications envoyées', `${done} membre${done > 1 ? 's' : ''} notifié${done > 1 ? 's' : ''}.`);
            }
          },
          error: () => {
            done++;
            if (done === pending.length) this.isNotifyingAll.set(false);
          },
        });
    }
  }
}
