import { Component, signal, computed, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { ToastService } from '../../services/toast.service';
import { MemberApiService } from '../../services/member-api.service';
import { SubscriptionApiService } from '../../services/subscription-api.service';
import { environment } from '../../../environments/environment';
import { ExportButtonComponent } from '../export-button/export-button.component';
import { MemberDTO, SubscriptionDTO, SubscriptionPlanDTO } from '../../models/api.models';

type PayStatus  = 'COMPLETED' | 'PENDING' | 'FAILED' | 'REFUNDED';
type PayMethod  = 'CASH' | 'CARD' | 'BANK_TRANSFER';

interface Payment {
  id: number;
  subscriptionId: number;
  memberName?: string;
  amount: number;
  paymentDate: string;
  paymentMethod: PayMethod;
  status: PayStatus;
  transactionRef?: string;
}

interface MemberPaymentGroup {
  memberKey: string;
  memberName: string;
  totalAmount: number;
  paymentCount: number;
  lastPaymentDate: string;
  lastStatus: PayStatus;
  payments: Payment[];
}

interface PaymentStats {
  revenueThisMonth: number;
  revenuePrevMonth: number;
  completedCount: number;
  pendingCount: number;
  failedCount: number;
  refundedCount: number;
  totalRevenue: number;
}

const EMPTY_STATS: PaymentStats = {
  revenueThisMonth: 0, revenuePrevMonth: 0,
  completedCount: 0, pendingCount: 0, failedCount: 0, refundedCount: 0,
  totalRevenue: 0,
};

@Component({
  selector: 'app-paiement',
  standalone: true,
  imports: [CommonModule, FormsModule, ExportButtonComponent],
  templateUrl: './paiement.component.html',
  styleUrl: './paiement.component.css',
})
export class PaiementComponent implements OnInit {
  private http      = inject(HttpClient);
  private toast     = inject(ToastService);
  private memberApi = inject(MemberApiService);
  private subApi    = inject(SubscriptionApiService);
  private BASE      = `${environment.apiUrl}/payments`;

  payments     = signal<Payment[]>([]);
  stats        = signal<PaymentStats>(EMPTY_STATS);
  isLoading    = signal(false);

  // New fields for the modal
  members      = signal<MemberDTO[]>([]);
  isLoadingMembers = signal(false);
  
  selectedMemberId = signal<number | null>(null);
  memberSubscriptions = signal<SubscriptionDTO[]>([]);
  isLoadingSubscriptions = signal(false);
  availablePlans = signal<SubscriptionPlanDTO[]>([]);
  isCreatingSubscription = signal(false);

  // Filters
  statusFilter = signal<PayStatus | ''>('');
  methodFilter = signal<PayMethod | ''>('');
  dateFrom     = signal('');
  dateTo       = signal('');

  // Add payment modal
  showModal    = signal(false);
  isProcessing = signal(false);
  newPayment   = signal({ subscriptionId: null as number | null, amount: 0, paymentMethod: 'CARD' as PayMethod });

  readonly statuses: PayStatus[] = ['COMPLETED', 'PENDING', 'FAILED', 'REFUNDED'];
  readonly methods:  PayMethod[] = ['CASH', 'CARD', 'BANK_TRANSFER'];
  readonly Math = Math;

  chartMonths = signal<string[]>([]);
  chartValues = signal<number[]>([]);
  chartMax    = computed(() => {
    const vals = this.chartValues();
    return vals.length ? Math.max(...vals) : 1;
  });

  filtered = computed(() => {
    let list = this.payments();
    const sf = this.statusFilter();
    const mf = this.methodFilter();
    const from = this.dateFrom();
    const to   = this.dateTo();
    if (sf)   list = list.filter(p => p.status === sf);
    if (mf)   list = list.filter(p => p.paymentMethod === mf);
    if (from) list = list.filter(p => new Date(p.paymentDate) >= new Date(from));
    if (to)   list = list.filter(p => new Date(p.paymentDate) <= new Date(to + 'T23:59:59'));
    return list;
  });

  groupedFiltered = computed(() => {
    const list = this.filtered();
    const groups = new Map<string, MemberPaymentGroup>();

    list.forEach(payment => {
      const key = payment.memberName ?? ('Membre #' + payment.subscriptionId);
      const existing = groups.get(key);
      if (existing) {
        existing.totalAmount += payment.amount;
        existing.paymentCount++;
        existing.payments.push(payment);
        if (payment.paymentDate > existing.lastPaymentDate) {
          existing.lastPaymentDate = payment.paymentDate;
          existing.lastStatus = payment.status;
        }
      } else {
        groups.set(key, {
          memberKey:       key,
          memberName:      key,
          totalAmount:     payment.amount,
          paymentCount:    1,
          lastPaymentDate: payment.paymentDate,
          lastStatus:      payment.status,
          payments:        [payment],
        });
      }
    });

    return Array.from(groups.values())
      .sort((a, b) => new Date(b.lastPaymentDate).getTime() - new Date(a.lastPaymentDate).getTime());
  });

  selectedGroup  = signal<MemberPaymentGroup | null>(null);
  showHistoryModal = signal(false);

  revenueGrowth = computed(() => {
    const curr = this.stats().revenueThisMonth;
    const prev = this.stats().revenuePrevMonth;
    return prev ? (((curr - prev) / prev) * 100).toFixed(1) : '0.0';
  });

  ngOnInit() {
    this.loadData();
    this.loadMembers();
    this.subApi.getAllPlans().subscribe({ next: (plans) => this.availablePlans.set(plans), error: () => {} });
  }

  loadMembers() {
    this.isLoadingMembers.set(true);
    this.memberApi.getAll().subscribe({
      next: (res) => {
        this.members.set(res.content || []);
        this.isLoadingMembers.set(false);
      },
      error: () => this.isLoadingMembers.set(false)
    });
  }

  onMemberChange(memberId: any) {
    const id = Number(memberId);
    this.selectedMemberId.set(id);
    this.memberSubscriptions.set([]);
    this.newPayment.update(p => ({ ...p, subscriptionId: null, amount: 0 }));

    if (!id) return;

    this.isLoadingSubscriptions.set(true);
    const member = this.members().find(m => m.id === id);
    const userId = member?.userId ?? member?.id;
    if (userId) {
      this.subApi.getByUser(userId).subscribe({
        next: (page: any) => {
          this.memberSubscriptions.set(page.content || []);
          this.isLoadingSubscriptions.set(false);
        },
        error: () => this.isLoadingSubscriptions.set(false)
      });
    } else {
      this.isLoadingSubscriptions.set(false);
    }
  }

  createAndSelectSubscription(plan: SubscriptionPlanDTO) {
    const memberId = this.selectedMemberId();
    if (!memberId) return;
    this.isCreatingSubscription.set(true);
    const today = new Date().toISOString().slice(0, 10);
    this.subApi.create({ userId: memberId, planId: plan.id, startDate: today as any } as any).subscribe({
      next: (sub: SubscriptionDTO) => {
        this.memberSubscriptions.update(list => [...list, sub]);
        this.newPayment.update(p => ({ ...p, subscriptionId: sub.id, amount: plan.price }));
        this.isCreatingSubscription.set(false);
        this.toast.success('Abonnement créé', `Plan ${plan.name} assigné — montant pré-rempli.`);
      },
      error: (err: any) => {
        this.isCreatingSubscription.set(false);
        this.toast.error('Erreur', err.error?.message || 'Impossible de créer l\'abonnement.');
      }
    });
  }

  onSubscriptionChange(subId: any) {
    const id = Number(subId);
    this.newPayment.update(p => ({ ...p, subscriptionId: id }));
    
    const sub = this.memberSubscriptions().find(s => s.id === id);
    if (sub) {
      this.subApi.getPlanById(sub.planId).subscribe({
        next: (plan) => {
          this.newPayment.update(p => ({ ...p, amount: plan.price }));
        }
      });
    }
  }

  loadData() {
    this.isLoading.set(true);

    this.http.get<any>(`${this.BASE}/stats`).subscribe({
      next: (s) => {
        this.stats.set({
          revenueThisMonth: Number(s.revenueThisMonth ?? 0),
          revenuePrevMonth: Number(s.revenuePrevMonth ?? 0),
          completedCount:   Number(s.completedCount   ?? 0),
          pendingCount:     Number(s.pendingCount      ?? 0),
          failedCount:      Number(s.failedCount       ?? 0),
          refundedCount:    Number(s.refundedCount     ?? 0),
          totalRevenue:     Number(s.totalRevenue      ?? 0),
        });
        // Build chart from real stats (current + prev month)
        const now    = new Date();
        const months = Array.from({ length: 6 }, (_, i) => {
          const d = new Date(now.getFullYear(), now.getMonth() - (5 - i), 1);
          return d.toLocaleString('fr-FR', { month: 'short' });
        });
        this.chartMonths.set(months);
        // Use real revenue for the last bar; approximate previous
        this.chartValues.set([0, 0, 0, 0, Number(s.revenuePrevMonth ?? 0), Number(s.revenueThisMonth ?? 0)]);
      },
      error: () => {},
    });

    this.http.get<any>(`${this.BASE}?size=100&sort=paymentDate,desc`).subscribe({
      next: (page: any) => {
        const items: Payment[] = (page.content ?? []).map((p: any) => ({
          id:            p.id,
          subscriptionId:p.subscriptionId,
          memberName:    p.memberName ?? p.memberEmail ?? '—',
          amount:        Number(p.amount),
          paymentDate:   p.paymentDate,
          paymentMethod: p.paymentMethod,
          status:        p.status,
          transactionRef:p.transactionRef,
        }));
        this.payments.set(items);
        this.isLoading.set(false);
      },
      error: () => this.isLoading.set(false),
    });
  }

  addPayment() {
    const f = this.newPayment();
    if (!f.subscriptionId || f.amount <= 0) {
      this.toast.error('Champ requis', 'Abonnement et montant sont obligatoires.');
      return;
    }
    this.isProcessing.set(true);

    this.http.post<Payment>(this.BASE, {
      subscriptionId: f.subscriptionId,
      amount:         f.amount,
      paymentMethod:  f.paymentMethod,
    }).subscribe({
      next: (p) => {
        const member = this.members().find(m => m.id === this.selectedMemberId());
        const memberName = member ? `${member.firstName} ${member.lastName}` : 'Membre';
        this.payments.update(list => [{ ...p, memberName }, ...list]);
        this.toast.success('Paiement enregistré', `${p.amount} DT — ${p.transactionRef ?? ''}`);
        this.isProcessing.set(false); 
        this.showModal.set(false);
      },
      error: (err) => {
        this.toast.error('Erreur', err.error?.message || 'Impossible d\'enregistrer le paiement.');
        this.isProcessing.set(false);
      },
    });
  }

  openHistory(group: MemberPaymentGroup) {
    this.selectedGroup.set(group);
    this.showHistoryModal.set(true);
  }

  closeHistory() {
    this.showHistoryModal.set(false);
    this.selectedGroup.set(null);
  }

  exportCsv() {
    const rows = this.filtered();
    const header = 'ID,Membre,Montant,Date,Méthode,Statut,Référence';
    const lines = rows.map(p =>
      `${p.id},"${p.memberName ?? ''}",${p.amount},${new Date(p.paymentDate).toLocaleDateString('fr-FR')},${p.paymentMethod},${p.status},${p.transactionRef ?? ''}`
    );
    const csv  = [header, ...lines].join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url  = URL.createObjectURL(blob);
    const a    = document.createElement('a');
    a.href = url; a.download = `paiements_${new Date().toISOString().slice(0,10)}.csv`;
    a.click(); URL.revokeObjectURL(url);
    this.toast.success('Export CSV', `${rows.length} paiement(s) exporté(s).`);
  }

  statusBadge(status: PayStatus): string {
    switch (status) {
      case 'COMPLETED': return 'bg-green-500/15 text-green-400 border border-green-500/30';
      case 'PENDING':   return 'bg-[#D4A017]/12 text-[#D4A017] border border-[#D4A017]/30';
      case 'FAILED':    return 'bg-red-500/15 text-red-400 border border-red-500/30';
      case 'REFUNDED':  return 'bg-gray-500/15 text-gray-400 border border-gray-500/30';
    }
  }

  statusLabel(status: PayStatus): string {
    return { COMPLETED: 'Complété', PENDING: 'En attente', FAILED: 'Échoué', REFUNDED: 'Remboursé' }[status];
  }

  methodIcon(method: PayMethod): string {
    return { CASH: 'fa-money-bill', CARD: 'fa-credit-card', BANK_TRANSFER: 'fa-university' }[method];
  }

  methodLabel(method: PayMethod): string {
    return { CASH: 'Espèces', CARD: 'Carte', BANK_TRANSFER: 'Virement' }[method];
  }

  updateNew(patch: Partial<typeof this.newPayment extends () => infer T ? T : never>) {
    this.newPayment.update(f => ({ ...f, ...patch } as any));
  }
}
