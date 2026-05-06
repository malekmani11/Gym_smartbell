import { Component, OnInit, signal, computed, output, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';

export interface PendingPayment {
  id: string;
  memberName: string;
  memberAvatar: string;
  plan: string;
  amount: number;
  daysOverdue: number;
  lastReminder?: Date;
  reminderSent: boolean;
}

export type PaymentActionType = 'REMINDER' | 'ALL_REMINDER';
export interface PaymentActionEvent {
  type: PaymentActionType;
  memberId: string;
}

@Component({
  selector: 'app-pending-payments',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './pending-payments.component.html',
})
export class PendingPaymentsComponent implements OnInit {
  private http = inject(HttpClient);

  paymentAction = output<PaymentActionEvent>();

  payments  = signal<PendingPayment[]>([]);
  isLoading = signal(true);

  totalUnpaid = computed(() => this.payments().reduce((s, p) => s + p.amount, 0));
  pendingCount = computed(() => this.payments().filter(p => !p.reminderSent).length);
  criticalCount = computed(() => this.payments().filter(p => p.daysOverdue > 14).length);

  ngOnInit() {
    this.http.get<any>(`${environment.apiUrl}/payments?size=100&sort=paymentDate,asc`).subscribe({
      next: (page) => {
        const list: PendingPayment[] = (page.content ?? [])
          .filter((p: any) => p.status === 'PENDING')
          .map((p: any) => ({
            id:          String(p.id),
            memberName:  p.memberName || 'Membre inconnu',
            memberAvatar:`https://i.pravatar.cc/150?u=pay${p.id}`,
            plan:        'Abonnement',
            amount:      Number(p.amount),
            daysOverdue: Math.max(0, Math.floor(
              (Date.now() - new Date(p.paymentDate).getTime()) / 86_400_000
            )),
            reminderSent: false,
          }));
        this.payments.set(list);
        this.isLoading.set(false);
      },
      error: () => this.isLoading.set(false),
    });
  }

  getOverdueBadgeClass(days: number): string {
    if (days > 14) return 'bg-red-500/15 text-red-400 border-red-500/30';
    if (days >= 7)  return 'bg-orange-500/15 text-orange-400 border-orange-500/30';
    return 'bg-[#D4AF37]/15 text-[#D4AF37] border-[#D4AF37]/30';
  }

  getRowUrgencyClass(days: number): string {
    if (days > 14) return 'border-l-2 border-l-red-500/60';
    if (days >= 7)  return 'border-l-2 border-l-orange-500/60';
    return 'border-l-2 border-l-[#D4AF37]/60';
  }

  canRelance(p: PendingPayment): boolean {
    if (!p.reminderSent || !p.lastReminder) return true;
    return Date.now() - p.lastReminder.getTime() >= 24 * 3600 * 1000;
  }

  formatReminderDate(date: Date): string {
    const diff = Math.floor((Date.now() - date.getTime()) / 3600000);
    if (diff < 1)  return 'À l\'instant';
    if (diff < 24) return `Il y a ${diff}h`;
    const days = Math.floor(diff / 24);
    return `Il y a ${days} jour${days > 1 ? 's' : ''}`;
  }

  sendReminder(payment: PendingPayment) {
    this.payments.update(list =>
      list.map(p => p.id === payment.id ? { ...p, reminderSent: true, lastReminder: new Date() } : p)
    );
    this.paymentAction.emit({ type: 'REMINDER', memberId: payment.id });
  }

  sendAllReminders() {
    this.payments.update(list => list.map(p => ({ ...p, reminderSent: true, lastReminder: new Date() })));
    this.payments().forEach(p => this.paymentAction.emit({ type: 'ALL_REMINDER', memberId: p.id }));
  }
}
