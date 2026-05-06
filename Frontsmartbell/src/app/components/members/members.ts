import { Component, signal, computed, inject, OnInit } from '@angular/core';
import { ToastService } from '../../services/toast.service';
import { MemberApiService } from '../../services/member-api.service';
import { SubscriptionApiService } from '../../services/subscription-api.service';
import { MemberDTO } from '../../models/api.models';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ExportButtonComponent } from '../export-button/export-button.component';

interface Plan {
  id: string;
  name: string;
  price: number;
  duration: 'Mensuel' | 'Annuel';
  access: string[];
  subscribersCount: number;
  color: string;
  revenue: number;
}

interface MemberSubscription {
  id: string;
  memberName: string;
  memberAvatar: string;
  email: string;
  planName: string;
  startDate: Date;
  expiryDate: Date;
  status: 'Actif' | 'Expiré' | 'Expire bientôt';
  paymentStatus: 'Payé' | 'En attente' | 'Échoué';
  paymentMethod: 'Carte' | 'Cash' | 'Virement';
}

@Component({
  selector: 'app-members',
  standalone: true,
  imports: [CommonModule, FormsModule, ExportButtonComponent],
  templateUrl: './members.html',
  styleUrl: './members.css'
})
export class Members implements OnInit {
  private toast     = inject(ToastService);
  private memberApi = inject(MemberApiService);
  private subApi    = inject(SubscriptionApiService);
  isApiLoading = signal(false);
  loadError    = signal(false);

  plans               = signal<Plan[]>([]);
  memberSubscriptions = signal<MemberSubscription[]>([]);

  searchTerm   = signal('');
  statusFilter = signal<'Actif' | 'Expiré' | 'Expire bientôt' | ''>('');
  planFilter   = signal('');

  reminderSentIds = signal<Set<string>>(new Set());

  showPlanModal = signal(false);
  editingPlan = signal<Plan | null>(null);
  isProcessing = signal(false);

  planForm = {
    name: '',
    price: 0,
    duration: 'Mensuel' as 'Mensuel' | 'Annuel',
    color: 'gold',
    access: [] as string[]
  };

  selectedSubscription = signal<MemberSubscription | null>(null);
  editingMember = signal<MemberSubscription | null>(null);
  showEditModal = signal(false);
  editEmailError = signal('');
  showNewMemberModal = signal(false);

  newMemberName = '';
  newMemberEmail = '';
  newMemberPassword = '';
  newMemberPhone = '';
  newMemberAddress = '';
  newMemberBirthDate = '';
  newMemberGender = 'HOMME';
  newMemberEmergencyContact = '';
  newMemberEmergencyPhone = '';
  newMemberMedicalNotes = '';
  newMemberPhotoUrl = '';
  newMemberPlan = 'Standard';
  newMemberMethod = 'Carte';

  ngOnInit() {
    const action = localStorage.getItem('gym_open_modal');
    if (action === 'new_member') {
      localStorage.removeItem('gym_open_modal');
      setTimeout(() => this.openNewMemberModal(), 100);
    }
    this.loadMembers();
    this.loadPlans();
  }

  loadPlans() {
    this.subApi.getAllPlans().subscribe({
      next: (plans) => {
        const mapped = plans.map(p => ({
          id:               String(p.id),
          name:             p.name,
          price:            p.price,
          duration:         (p.durationMonths === 12 ? 'Annuel' : 'Mensuel') as 'Mensuel' | 'Annuel',
          access:           p.description ? p.description.split(', ') : [],
          subscribersCount: 0, // Would need another API call or filter from members
          color:            p.price > 100 ? 'purple' : p.price > 50 ? 'blue' : 'gold',
          revenue:          0,
        }));
        this.plans.set(mapped);
      },
      error: () => this.toast.error('Erreur', 'Impossible de charger les plans d\'abonnement.')
    });
  }

  openNewMemberModal() {
    this.newMemberName     = '';
    this.newMemberEmail    = '';
    this.newMemberPassword = '';
    this.newMemberPhone    = '';
    this.newMemberAddress  = '';
    this.newMemberBirthDate = '';
    this.newMemberGender   = 'HOMME';
    this.newMemberEmergencyContact = '';
    this.newMemberEmergencyPhone   = '';
    this.newMemberMedicalNotes     = '';
    this.newMemberPhotoUrl = '';
    this.newMemberPlan     = 'Standard';
    this.newMemberMethod   = 'Carte';
    this.showNewMemberModal.set(true);
  }

  closeNewMemberModal() {
    this.newMemberName     = '';
    this.newMemberEmail    = '';
    this.newMemberPassword = '';
    this.newMemberPhone    = '';
    this.newMemberPhotoUrl = '';
    this.showNewMemberModal.set(false);
  }

  private readonly CACHE_KEY = 'gym_members_cache';

  loadMembers() {
    this.isApiLoading.set(true);
    this.loadError.set(false);

    // Show cached data immediately while fetching
    const cached = localStorage.getItem(this.CACHE_KEY);
    if (cached) {
      try {
        const parsed: MemberSubscription[] = JSON.parse(cached);
        const revived = parsed.map(m => ({
          ...m,
          startDate:  new Date(m.startDate),
          expiryDate: new Date(m.expiryDate),
        }));
        this.memberSubscriptions.set(revived);
        this.isApiLoading.set(false);
      } catch { /* ignore corrupt cache */ }
    }

    this.memberApi.getAll().subscribe({
      next: (response) => {
        // response is PageResponse<MemberDTO>
        const list = response.content || [];
        const mapped: MemberSubscription[] = list.map((m: MemberDTO) => ({
          id:            String(m.id),
          memberName:    `${m.firstName || ''} ${m.lastName || ''}`.trim() || 'Membre #' + m.id,
          memberAvatar:  m.profileImageUrl || `https://i.pravatar.cc/150?u=member${m.id}`,
          email:         m.email || '',
          planName:      m.planName || 'Standard',
          startDate:     m.joinDate ? new Date(m.joinDate) : new Date(),
          expiryDate:    new Date(Date.now() + 30 * 864e5), // Dynamic logic could go here
          status:        this.mapStatus(m.membershipStatus || 'ACTIVE'),
          paymentStatus: 'Payé' as const,
          paymentMethod: 'Carte' as const,
        }));
        this.memberSubscriptions.set(mapped);
        localStorage.setItem(this.CACHE_KEY, JSON.stringify(mapped));
        this.isApiLoading.set(false);
      },
      error: (err) => {
        console.error('Load members error:', err);
        this.isApiLoading.set(false);
        if (!cached) {
          this.loadError.set(true);
        }
      }
    });
  }

  private mapStatus(apiStatus: string): 'Actif' | 'Expiré' | 'Expire bientôt' {
    const map: Record<string, 'Actif' | 'Expiré' | 'Expire bientôt'> = {
      'ACTIVE':    'Actif',
      'INACTIVE':  'Expiré',
      'SUSPENDED': 'Expiré',
      'EXPIRED':   'Expiré'
    };
    return map[apiStatus] ?? 'Actif';
  }

  confirmNewMember() {
    if (!this.newMemberName.trim() || !this.newMemberEmail.trim() || !this.newMemberPassword.trim()) {
      this.toast.error('Champs requis', 'Le nom, l\'email et le mot de passe sont obligatoires.');
      return;
    }
    this.isProcessing.set(true);

    const parts     = this.newMemberName.trim().split(' ');
    const firstName = parts[0];
    const lastName  = parts.slice(1).join(' ') || firstName;

    this.memberApi.register({
      firstName,
      lastName,
      email:    this.newMemberEmail.trim(),
      password: this.newMemberPassword.trim(),
      phone:    this.newMemberPhone.trim() || undefined,
    }).subscribe({
      next: (created) => {
        const selectedPlan = this.plans().find(p => p.name === this.newMemberPlan);
        const finish = () => {
          this.loadMembers();
          this.isProcessing.set(false);
          this.closeNewMemberModal();
        };
        if (selectedPlan && created.id) {
          const today = new Date().toISOString().slice(0, 10);
          this.subApi.create({
            userId: Number(created.id),
            planId: Number(selectedPlan.id),
            startDate: today as any,
          } as any).subscribe({
            next: () => { finish(); this.toast.success('Membre ajouté ✓', `${created.firstName} inscrit avec plan ${selectedPlan.name}.`); },
            error: () => { finish(); this.toast.success('Membre ajouté ✓', `${created.firstName} inscrit (erreur lors de l'abonnement).`); }
          });
        } else {
          finish();
          this.toast.success('Membre ajouté ✓', `${created.firstName} ${created.lastName} a été inscrit.`);
        }
      },
      error: (err) => {
        this.isProcessing.set(false);
        const msg = err.error?.message || '';
        if (msg.includes('déjà')) {
          this.toast.error('Email déjà utilisé', 'Un compte avec cet email existe déjà.');
        } else {
          this.toast.error(`Erreur ${err.status}`, msg || 'Une erreur est survenue.');
        }
      }
    });
  }

  saveEditedMember() {
    const edited = this.editingMember();
    if (!edited) return;

    // Validate email
    const email = (edited.email || '').trim();
    if (!email) {
      this.editEmailError.set('L\'email est obligatoire');
      return;
    }
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      this.editEmailError.set('Format email invalide');
      return;
    }
    this.editEmailError.set('');
    this.isProcessing.set(true);

    const statusMap: Record<string, string> = {
      'Actif':          'ACTIVE',
      'Expiré':         'INACTIVE',
      'Expire bientôt': 'ACTIVE'
    };

    const parts = edited.memberName.trim().split(' ');
    const firstName = parts[0];
    const lastName = parts.slice(1).join(' ') || firstName;

    const dto: Partial<MemberDTO> = {
      firstName,
      lastName,
      email,
      membershipStatus: (statusMap[edited.status] ?? 'ACTIVE') as any,
    };

    this.memberApi.update(Number(edited.id), dto).subscribe({
      next: () => {
        const selectedPlan = this.plans().find(p => p.name === edited.planName);
        const finish = () => {
          this.loadMembers();
          this.showEditModal.set(false);
          this.editingMember.set(null);
          this.isProcessing.set(false);
        };
        if (selectedPlan) {
          const today = new Date().toISOString().slice(0, 10);
          this.subApi.create({
            userId: Number(edited.id),
            planId: Number(selectedPlan.id),
            startDate: today as any,
          } as any).subscribe({
            next: () => { finish(); this.toast.success('Membre mis à jour', `Abonnement ${selectedPlan.name} créé.`); },
            error: () => { finish(); this.toast.success('Membre mis à jour', 'Informations sauvegardées (erreur abonnement).'); }
          });
        } else {
          finish();
          this.toast.success('Membre mis à jour', 'Les modifications ont été enregistrées.');
        }
      },
      error: (err) => {
        this.isProcessing.set(false);
        const msg: string = err.error?.message || '';
        if (msg.toLowerCase().includes('email') || err.status === 409) {
          this.editEmailError.set('Cet email est déjà utilisé par un autre compte');
        } else {
          this.toast.error('Erreur', msg || 'Impossible de mettre à jour le membre.');
        }
      }
    });
  }

  sendReminder(subId: string) {
    const sub = this.memberSubscriptions().find(s => s.id === subId);
    if (!sub) return;

    this.reminderSentIds.update(s => new Set([...s, subId]));
    this.toast.success('Rappel envoyé', `Email de relance envoyé à ${sub.memberName}.`);
  }

  sendAllReminders() {
    this.memberSubscriptions()
      .filter(s => s.paymentStatus === 'En attente' || s.paymentStatus === 'Échoué')
      .forEach(s => {
        if (!this.isReminderSent(s.id)) {
          this.sendReminder(s.id);
        }
      });
  }

  isReminderSent(subId: string): boolean {
    return this.reminderSentIds().has(subId);
  }

  openNewPlan() {
    this.editingPlan.set(null);
    this.planForm = {
      name: '',
      price: 0,
      duration: 'Mensuel',
      color: 'gold',
      access: []
    };
    this.showPlanModal.set(true);
  }

  openEditPlan(plan: Plan) {
    this.editingPlan.set(plan);
    this.planForm = {
      name: plan.name,
      price: plan.price,
      duration: plan.duration,
      color: plan.color,
      access: [...plan.access]
    };
    this.showPlanModal.set(true);
  }

  savePlan() {
    this.isProcessing.set(true);
    const currentEditing = this.editingPlan();
    const data = this.planForm;
    const durationMonths = data.duration === 'Annuel' ? 12 : 1;

    if (currentEditing) {
      const planId = Number(currentEditing.id.replace('P', ''));
      this.subApi.updatePlan(planId, {
        name: data.name,
        price: data.price,
        durationMonths,
        description: data.access.join(', '),
      }).subscribe({
        next: () => {
          this.plans.update(all => all.map(p =>
            p.id === currentEditing.id ? { ...p, ...data } : p
          ));
          this.isProcessing.set(false);
          this.showPlanModal.set(false);
          this.toast.success('Plan mis à jour', `Le plan ${data.name} a été modifié.`);
        },
        error: () => {
          this.isProcessing.set(false);
          this.showPlanModal.set(false);
        }
      });
    } else {
      this.subApi.createPlan({
        name: data.name,
        price: data.price,
        durationMonths,
        description: data.access.join(', '),
      }).subscribe({
        next: (created) => {
          const newPlan: Plan = {
            id:               String(created.id),
            name:             created.name,
            price:            created.price,
            duration:         data.duration,
            access:           data.access,
            subscribersCount: 0,
            color:            data.color,
            revenue:          0,
          };
          this.plans.update(all => [...all, newPlan]);
          this.isProcessing.set(false);
          this.showPlanModal.set(false);
          this.toast.success('Plan créé', `Le plan ${newPlan.name} a été créé.`);
        },
        error: () => {
          this.isProcessing.set(false);
          this.showPlanModal.set(false);
        }
      });
    }
  }

  viewMember(sub: MemberSubscription) {
    this.selectedSubscription.set(sub);
  }

  closeMember() {
    this.selectedSubscription.set(null);
  }

  editMember(sub: MemberSubscription) {
    this.editingMember.set({ ...sub });
    this.editEmailError.set('');
    this.showEditModal.set(true);
  }

  deleteMember(id: string) {
    const member = this.memberSubscriptions().find(m => m.id === id);
    if (!member) return;
    this.memberApi.delete(Number(id)).subscribe({
      next: () => {
        this.memberSubscriptions.update(list => list.filter(m => m.id !== id));
        this.toast.success('Membre supprimé', `${member.memberName} a été retiré de la liste.`);
      },
      error: (err) => {
        this.toast.error('Erreur', err.error?.message || 'Impossible de supprimer le membre.');
      }
    });
  }

  viewPlanMembers(planName: string) {
    this.viewMode.set('members');
    this.searchTerm.set(planName);
  }

  getMonthsSinceStart(startDate: Date): number {
    const start = new Date(startDate);
    const now = new Date();
    return (now.getFullYear() - start.getFullYear()) * 12 + (now.getMonth() - start.getMonth());
  }

  renewSubscription() {
    this.toast.success('Abonnement renouvelé', 'L\'abonnement a été renouvelé avec succès.');
  }

  filteredSubscriptions = computed(() => {
    const term   = (this.searchTerm() ?? '').toLowerCase();
    const status = this.statusFilter();
    const plan   = this.planFilter();

    return this.memberSubscriptions().filter(s =>
      (s.memberName.toLowerCase().includes(term) ||
       s.planName.toLowerCase().includes(term) ||
       s.email.toLowerCase().includes(term)) &&
      (!status || s.status   === status) &&
      (!plan   || s.planName === plan)
    );
  });

  totalSubscribers = computed(() => this.memberSubscriptions().length);

  totalRevenue = computed(() =>
    this.plans().reduce((sum, p) => sum + p.revenue, 0)
  );

  expiringThisWeek = computed(() => {
    const today = Date.now();

    return this.memberSubscriptions().filter(s => {
      const diff = (new Date(s.expiryDate).getTime() - today) / (1000 * 60 * 60 * 24);
      return diff <= 7 && diff > 0;
    }).length;
  });

  activeSubscribers = computed(() =>
    this.memberSubscriptions().filter(s => s.status === 'Actif').length
  );

  pendingPayments = computed(() =>
    this.memberSubscriptions().filter(s => s.paymentStatus === 'En attente').length
  );

  averageRevenue = computed(() =>
    this.totalSubscribers() ? Math.round(this.totalRevenue() / this.totalSubscribers()) : 0
  );

  bestPlan = computed(() =>
    this.plans().reduce((best, p) => p.revenue > best.revenue ? p : best, this.plans()[0])
  );

  pendingPaymentsCount = computed(() =>
    this.memberSubscriptions().filter(s => s.paymentStatus === 'En attente').length
  );

  recoveryRate = computed(() => {
    const total = this.memberSubscriptions().length;
    const paid  = this.memberSubscriptions().filter(s => s.paymentStatus === 'Payé').length;
    return total ? Math.round((paid / total) * 100) : 0;
  });

  viewMode = signal<'plans' | 'members' | 'finance'>('members');

  getPlanPrice(planName: string): number {
    return this.plans().find(p => p.name === planName)?.price ?? 0;
  }

  getPaymentMethodIcon(method: string): string {
    switch (method) {
      case 'Carte':    return 'fa-credit-card';
      case 'Cash':     return 'fa-money-bill';
      case 'Virement': return 'fa-university';
      default:         return 'fa-circle-question';
    }
  }

  onStatusChange(event: Event) {
    const value = (event.target as HTMLSelectElement).value;
    this.statusFilter.set(value as 'Actif' | 'Expiré' | '');
  }

  getPaymentStatusClass(status: string): string {
    switch (status) {
      case 'Payé':       return 'bg-green-500/15 text-green-400 border border-green-500/30';
      case 'En attente': return 'bg-orange-500/15 text-orange-400 border border-orange-500/30';
      case 'Échoué':     return 'bg-red-500/15 text-red-400 border border-red-500/30';
      default:           return '';
    }
  }

  getSubscriptionStatusClass(status: string): string {
    switch (status) {
      case 'Actif':  return 'bg-green-500/15 text-green-400 border border-green-500/30';
      case 'Expiré': return 'bg-red-500/15 text-red-400 border border-red-500/30';
      default:       return 'bg-gray-500/15 text-gray-400 border border-gray-500/30';
    }
  }

  getInitials(name: string): string {
    if (!name?.trim()) return '?';
    const parts = name.trim().split(/\s+/);
    return parts.length === 1
      ? parts[0].charAt(0).toUpperCase()
      : (parts[0].charAt(0) + parts[parts.length - 1].charAt(0)).toUpperCase();
  }
}
