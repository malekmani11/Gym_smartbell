import { Component, signal, computed, inject, OnInit } from '@angular/core';
import { CommonModule, DecimalPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { SubscriptionApiService } from '../../services/subscription-api.service';
import { MemberApiService } from '../../services/member-api.service';
import { ToastService } from '../../services/toast.service';

interface Plan {
  id: string;
  name: string;
  price: number;
  duration: 'Mensuel' | 'Trimestriel' | 'Annuel';
  color: 'gold' | 'blue' | 'purple' | 'green';
  access: string[];
  subscribersCount: number;
  revenue: number;
  popular?: boolean;
}

interface MemberSub {
  id: string;
  name: string;
  avatar: string;
  plan: string;
  status: 'Actif' | 'Expire bientôt' | 'Expiré' | 'En attente';
  paymentStatus: 'Payé' | 'En attente' | 'Échoué';
  paymentMethod: 'Carte' | 'Cash' | 'Virement';
  expiry: Date;
  startDate: Date;
  amount: number;
}

const PLAN_COLORS: Plan['color'][] = ['blue', 'gold', 'purple', 'green'];

@Component({
  selector: 'app-subscriptions',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule, DecimalPipe],
  templateUrl: './subscriptions.html',
})
export class Subscriptions implements OnInit {
  private subApi    = inject(SubscriptionApiService);
  private memberApi = inject(MemberApiService);
  private toast     = inject(ToastService);

  ngOnInit() {
    this.loadPlans();
    this.loadMembers();
  }

  loadMembers() {
    this.memberApi.getAll().subscribe({
      next: (response) => {
        const list = response.content || [];
        if (list.length === 0) return;
        const mapped: MemberSub[] = list.map(m => {
          const status = this._mapStatus(m.membershipStatus || 'ACTIVE');
          return {
            id:            String(m.id),
            name:          `${m.firstName} ${m.lastName}`,
            avatar:        `https://i.pravatar.cc/150?u=member${m.id}`,
            plan:          'Standard',
            status,
            paymentStatus: status === 'Expiré' ? 'Échoué' as const : 'Payé' as const,
            paymentMethod: 'Carte' as const,
            expiry:        new Date(Date.now() + 30 * 864e5),
            startDate:     m.joinDate ? new Date(m.joinDate) : new Date(),
            amount:        49,
          };
        });
        this.members.set(mapped);
      },
      error: () => {}
    });
  }

  private _mapStatus(s: string): MemberSub['status'] {
    const map: Record<string, MemberSub['status']> = {
      ACTIVE:    'Actif',
      INACTIVE:  'Expiré',
      EXPIRED:   'Expiré',
      SUSPENDED: 'Expiré',
      PENDING:   'En attente',
    };
    return map[s] ?? 'Actif';
  }

  loadPlans() {
    this.subApi.getAllPlans().subscribe({
      next: (apiPlans) => {
        if (!apiPlans.length) return;
        const mapped = apiPlans.map((p, i) => ({
          id:              String(p.id),
          name:            p.name,
          price:           p.price,
          duration:        p.durationMonths <= 1 ? 'Mensuel' : p.durationMonths <= 3 ? 'Trimestriel' : 'Annuel',
          color:           PLAN_COLORS[i % PLAN_COLORS.length],
          access:          p.description ? [p.description] : ['Accès salle'],
          subscribersCount: 0,
          revenue:          0,
        } as Plan));
        this.plans.set(mapped);
      },
      error: () => {
        // Keep mock plans on error
      }
    });
  }

  // ── Plans ──────────────────────────────────────────────────
  plans = signal<Plan[]>([
    {
      id: 'p1',
      name: 'Standard',
      price: 49,
      duration: 'Mensuel',
      color: 'blue',
      access: ['Accès salle complète', 'Vestiaires & douches',
               'Cours collectifs de base', 'Application mobile'],
      subscribersCount: 420,
      revenue: 20580,
    },
    {
      id: 'p2',
      name: 'Premium',
      price: 89,
      duration: 'Mensuel',
      color: 'gold',
      popular: true,
      access: ['Tout Standard inclus', 'Cours collectifs premium',
               'Accès piscine & spa', '1 séance coach/mois',
               'Bilan nutritionnel'],
      subscribersCount: 310,
      revenue: 27590,
    },
    {
      id: 'p3',
      name: 'Elite CrossFit',
      price: 129,
      duration: 'Mensuel',
      color: 'purple',
      access: ['Tout Premium inclus', 'CrossFit illimité',
               'Coach dédié', 'Nutrition personnalisée',
               'Accès 24h/24'],
      subscribersCount: 238,
      revenue: 30702,
    },
    {
      id: 'p4',
      name: 'VIP Annuel',
      price: 799,
      duration: 'Annuel',
      color: 'green',
      access: ['Tout Elite inclus', 'Invités illimités',
               'Casier privatif', 'Parking réservé',
               'Événements exclusifs', 'Support prioritaire'],
      subscribersCount: 80,
      revenue: 63920,
    },
  ]);

  // ── Members ────────────────────────────────────────────────
  members = signal<MemberSub[]>([
    { id:'1', name:'Sophie Laurent',  avatar:'https://i.pravatar.cc/150?u=s1', plan:'Premium',       status:'Actif',          paymentStatus:'Payé',       paymentMethod:'Carte',    expiry:new Date(Date.now()+45*864e5), startDate:new Date('2024-01-15'), amount:89  },
    { id:'2', name:'Lucas Martin',    avatar:'https://i.pravatar.cc/150?u=s2', plan:'Elite CrossFit',status:'Actif',          paymentStatus:'Payé',       paymentMethod:'Virement', expiry:new Date(Date.now()+60*864e5), startDate:new Date('2024-02-01'), amount:129 },
    { id:'3', name:'Emma Bernard',    avatar:'https://i.pravatar.cc/150?u=s3', plan:'Standard',      status:'Actif',          paymentStatus:'Payé',       paymentMethod:'Cash',     expiry:new Date(Date.now()+30*864e5), startDate:new Date('2024-03-10'), amount:49  },
    { id:'4', name:'Thomas Renard',   avatar:'https://i.pravatar.cc/150?u=s4', plan:'Premium',       status:'Expire bientôt', paymentStatus:'Payé',       paymentMethod:'Carte',    expiry:new Date(Date.now()+5*864e5),  startDate:new Date('2024-01-01'), amount:89  },
    { id:'5', name:'Camille Morin',   avatar:'https://i.pravatar.cc/150?u=s5', plan:'VIP Annuel',    status:'Expire bientôt', paymentStatus:'En attente', paymentMethod:'Virement', expiry:new Date(Date.now()+3*864e5),  startDate:new Date('2023-06-01'), amount:799 },
    { id:'6', name:'Antoine Faure',   avatar:'https://i.pravatar.cc/150?u=s6', plan:'Standard',      status:'Expiré',         paymentStatus:'Échoué',     paymentMethod:'Carte',    expiry:new Date(Date.now()-10*864e5), startDate:new Date('2023-11-01'), amount:49  },
    { id:'7', name:'Nadia Ferhat',    avatar:'https://i.pravatar.cc/150?u=s7', plan:'Elite CrossFit',status:'Expiré',         paymentStatus:'Échoué',     paymentMethod:'Cash',     expiry:new Date(Date.now()-20*864e5), startDate:new Date('2023-12-01'), amount:129 },
    { id:'8', name:'Karim Aziz',      avatar:'https://i.pravatar.cc/150?u=s8', plan:'Premium',       status:'En attente',     paymentStatus:'En attente', paymentMethod:'Carte',    expiry:new Date(Date.now()+28*864e5), startDate:new Date('2024-03-20'), amount:89  },
  ]);

  // ── Filters ────────────────────────────────────────────────
  searchTerm    = signal('');
  statusFilter  = signal('Tous');
  showAddPlan   = signal(false);
  showAddMember = signal(false);
  isProcessing  = signal(false);

  showEditPlan   = signal(false);
  editingPlan    = signal<Plan | null>(null);
  showDeleteConfirm = signal<string | null>(null); // holds plan id to delete

  newPlan = { name: '', price: 49, duration: 'Mensuel', color: 'gold', access: '' };
  editPlan = { name: '', price: 49, duration: 'Mensuel' as Plan['duration'], color: 'gold' as Plan['color'], access: '' };
  newMemberName = '';
  newMemberPlan = 'Standard';

  // ── Computed ───────────────────────────────────────────────
  totalRevenue = computed(() =>
    this.plans().reduce((s, p) => s + p.revenue, 0)
  );

  totalMembers = computed(() => this.members().length);

  activeCount = computed(() =>
    this.members().filter(m => m.status === 'Actif').length
  );

  expiringCount = computed(() =>
    this.members().filter(m => m.status === 'Expire bientôt').length
  );

  expiredCount = computed(() =>
    this.members().filter(m => m.status === 'Expiré').length
  );

  recoveryRate = computed(() => {
    const total = this.members().length;
    const paid  = this.members().filter(m => m.paymentStatus === 'Payé').length;
    return total ? Math.round((paid / total) * 100) : 0;
  });

  filteredMembers = computed(() => {
    const q = this.searchTerm().toLowerCase().trim();
    const s = this.statusFilter();
    return this.members().filter(m => {
      const matchQ = !q || m.name.toLowerCase().includes(q)
                        || m.plan.toLowerCase().includes(q);
      const matchS = s === 'Tous' || m.status === s;
      return matchQ && matchS;
    });
  });

  maxRevenue = computed(() =>
    Math.max(...this.plans().map(p => p.revenue))
  );

  // ── Helpers ────────────────────────────────────────────────
  planColorClass(color: string): string {
    const m: Record<string, string> = {
      gold:   'border-[#D4AF37]/30 bg-[#D4AF37]/5',
      blue:   'border-blue-500/30 bg-blue-500/5',
      purple: 'border-purple-500/30 bg-purple-500/5',
      green:  'border-green-500/30 bg-green-500/5',
    };
    return m[color] ?? '';
  }

  planAccentColor(color: string): string {
    const m: Record<string, string> = {
      gold:   '#D4AF37',
      blue:   '#3b82f6',
      purple: '#a855f7',
      green:  '#22c55e',
    };
    return m[color] ?? '#D4AF37';
  }

  planBadgeClass(color: string): string {
    const m: Record<string, string> = {
      gold:   'bg-[#D4AF37]/15 text-[#D4AF37] border-[#D4AF37]/30',
      blue:   'bg-blue-500/15 text-blue-400 border-blue-500/30',
      purple: 'bg-purple-500/15 text-purple-400 border-purple-500/30',
      green:  'bg-green-500/15 text-green-400 border-green-500/30',
    };
    return m[color] ?? '';
  }

  statusBadgeClass(status: string): string {
    switch (status) {
      case 'Actif':          return 'bg-green-500/15 text-green-400 border border-green-500/30';
      case 'Expire bientôt': return 'bg-yellow-500/15 text-yellow-400 border border-yellow-500/30';
      case 'Expiré':         return 'bg-red-500/15 text-red-400 border border-red-500/30';
      case 'En attente':     return 'bg-blue-500/15 text-blue-400 border border-blue-500/30';
      default: return '';
    }
  }

  paymentBadgeClass(status: string): string {
    switch (status) {
      case 'Payé':       return 'bg-green-500/15 text-green-400 border border-green-500/30';
      case 'En attente': return 'bg-orange-500/15 text-orange-400 border border-orange-500/30';
      case 'Échoué':     return 'bg-red-500/15 text-red-400 border border-red-500/30';
      default: return '';
    }
  }

  methodIcon(method: string): string {
    switch (method) {
      case 'Carte':    return 'fas fa-credit-card';
      case 'Cash':     return 'fas fa-money-bill';
      case 'Virement': return 'fas fa-university';
      default: return 'fas fa-circle-question';
    }
  }

  daysUntilExpiry(expiry: Date): number {
    return Math.ceil((new Date(expiry).getTime() - Date.now()) / 864e5);
  }

  renewMember(id: string) {
    const member = this.members().find(m => m.id === id);
    const plan   = this.plans().find(p => p.name === member?.plan);
    if (!plan) return;

    this.subApi.create({
      userId:    Number(id),
      planId:    Number(plan.id),
      startDate: new Date().toISOString().split('T')[0],
      endDate:   new Date(Date.now() + 30 * 864e5).toISOString().split('T')[0],
      status:    'ACTIVE',
    }).subscribe({
      next: () => {
        this.members.update(list => list.map(m =>
          m.id === id ? {
            ...m,
            status:        'Actif' as const,
            expiry:        new Date(Date.now() + 30 * 864e5),
            paymentStatus: 'Payé' as const,
          } : m
        ));
        this.toast.success('Abonnement renouvelé', `L'abonnement de ${member?.name} a été renouvelé.`);
      },
      error: (err) => {
        this.toast.error('Erreur', err.error?.message || 'Impossible de renouveler l\'abonnement.');
      }
    });
  }

  openEditPlan(plan: Plan) {
    this.editingPlan.set(plan);
    this.editPlan = {
      name:     plan.name,
      price:    plan.price,
      duration: plan.duration,
      color:    plan.color,
      access:   plan.access.join('\n'),
    };
    this.showEditPlan.set(true);
  }

  saveEditedPlan() {
    const plan = this.editingPlan();
    if (!plan || !this.editPlan.name.trim()) return;
    this.isProcessing.set(true);

    const durationMonths = this.editPlan.duration === 'Annuel' ? 12
                         : this.editPlan.duration === 'Trimestriel' ? 3 : 1;

    this.subApi.updatePlan(Number(plan.id), {
      name:           this.editPlan.name.trim(),
      price:          this.editPlan.price,
      durationMonths: durationMonths,
      description:    this.editPlan.access,
    }).subscribe({
      next: () => {
        this.plans.update(list => list.map(p =>
          p.id === plan.id ? {
            ...p,
            name:     this.editPlan.name.trim(),
            price:    this.editPlan.price,
            duration: this.editPlan.duration,
            color:    this.editPlan.color,
            access:   this.editPlan.access.split('\n').filter(a => a.trim()),
          } : p
        ));
        this.isProcessing.set(false);
        this.showEditPlan.set(false);
        this.editingPlan.set(null);
      },
      error: (err) => {
        this.isProcessing.set(false);
        this.toast.error('Erreur', err.error?.message || 'Impossible de modifier le plan.');
      }
    });
  }

  confirmDeletePlan(planId: string) {
    this.showDeleteConfirm.set(planId);
  }

  deletePlan(planId: string) {
    this.subApi.deletePlan(Number(planId)).subscribe({
      next: () => {
        this.plans.update(list => list.filter(p => p.id !== planId));
        this.showDeleteConfirm.set(null);
      },
      error: (err) => {
        this.toast.error('Erreur', err.error?.message || 'Impossible de supprimer le plan.');
        this.showDeleteConfirm.set(null);
      }
    });
  }

  addNewPlan() {
    if (!this.newPlan.name.trim()) return;
    this.isProcessing.set(true);

    const durationMonths = this.newPlan.duration === 'Annuel' ? 12
                         : this.newPlan.duration === 'Trimestriel' ? 3 : 1;

    this.subApi.createPlan({
      name:           this.newPlan.name.trim(),
      price:          this.newPlan.price,
      durationMonths: durationMonths,
      description:    this.newPlan.access,
    }).subscribe({
      next: (created) => {
        this.plans.update(list => [...list, {
          id:              String(created.id),
          name:            created.name,
          price:           created.price,
          duration:        this.newPlan.duration as Plan['duration'],
          color:           this.newPlan.color as Plan['color'],
          access:          this.newPlan.access.split('\n').filter(a => a.trim()),
          subscribersCount: 0,
          revenue:          0,
        }]);
        this.isProcessing.set(false);
        this.showAddPlan.set(false);
        this.newPlan = { name: '', price: 49, duration: 'Mensuel', color: 'gold', access: '' };
      },
      error: () => {
        this.isProcessing.set(false);
      }
    });
  }
}
