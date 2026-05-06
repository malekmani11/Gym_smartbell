import { Injectable, signal, computed } from '@angular/core';

/* ─────────────── INTERFACES ─────────────── */
export interface Coach {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  avatar: string;
  specialty: string;
  status: 'Actif' | 'Absent' | 'Congé';
  hireDate: Date;
  rating: number;
  sessionsCount: number;
  bio?: string;
}

export interface Plan {
  id: string;
  name: string;
  price: number;
  duration: 'Mensuel' | 'Trimestriel' | 'Annuel';
  access: string[];
  subscribersCount: number;
  color: string;
  description?: string;
  isPopular?: boolean;
}

export interface GymMember {
  id: string;
  name: string;
  email: string;
  phone?: string;
  avatar: string;
  planId: string;
  planName: string;
  status: 'Actif' | 'Expiré' | 'En attente' | 'Suspendu';
  joinDate: Date;
  expiryDate: Date;
  paymentStatus: 'Payé' | 'En attente' | 'Échoué';
  paymentMethod: 'Carte' | 'Cash' | 'Virement';
  amount: number;
  assignedCoachId?: string;
}

export interface PendingPayment {
  id: string;
  memberId: string;
  memberName: string;
  memberAvatar: string;
  amount: number;
  daysOverdue: number;
  plan: string;
  lastReminderSent?: Date;
  phone?: string;
}

export interface CourseSlot {
  id: string;
  name: string;
  coachId: string;
  coachName: string;
  day: 0 | 1 | 2 | 3 | 4 | 5 | 6; // 0=Lun … 6=Dim
  startHour: number;
  duration: number; // minutes
  capacity: number;
  enrolled: number;
  type: 'yoga' | 'crossfit' | 'powerlifting' | 'cardio' | 'nutrition' | 'pilates';
  color?: string;
}

export interface ShopCategory {
  id: string;
  name: string;
  icon: string;
  current: number;
  previous: number;
  history: number[];
  color: string;
}

/* ─────────────── SERVICE ─────────────── */
@Injectable({ providedIn: 'root' })
export class GymStoreService {

  /* ══════════ COACHES ══════════ */
  coaches = signal<Coach[]>([
    {
      id: 'C-001', firstName: 'Marc', lastName: 'Leroux',
      email: 'marc.leroux@gymelite.fr', phone: '06 12 34 56 78',
      avatar: 'https://i.pravatar.cc/150?u=marc',
      specialty: 'Bodybuilding & Powerlifting', status: 'Actif',
      hireDate: new Date('2020-03-15'), rating: 4.9, sessionsCount: 412,
      bio: 'Champion régional powerlifting 2019. Spécialiste prise de masse.'
    },
    {
      id: 'C-002', firstName: 'Julie', lastName: 'Vasseur',
      email: 'julie.vasseur@gymelite.fr', phone: '06 23 45 67 89',
      avatar: 'https://i.pravatar.cc/150?u=julie',
      specialty: 'Yoga & Pilates', status: 'Actif',
      hireDate: new Date('2021-06-01'), rating: 4.8, sessionsCount: 298,
      bio: 'Instructrice certifiée Yoga Alliance 200h. Spécialiste mobilité.'
    },
    {
      id: 'C-003', firstName: 'Thomas', lastName: 'Durand',
      email: 'thomas.durand@gymelite.fr', phone: '06 34 56 78 90',
      avatar: 'https://i.pravatar.cc/150?u=thomas',
      specialty: 'CrossFit & HIIT', status: 'Actif',
      hireDate: new Date('2019-09-10'), rating: 4.7, sessionsCount: 534,
      bio: 'CrossFit Level 2 Trainer. Record de fréquentation du cours WOD.'
    },
    {
      id: 'C-004', firstName: 'Sarah', lastName: 'Guerin',
      email: 'sarah.guerin@gymelite.fr', phone: '06 45 67 89 01',
      avatar: 'https://i.pravatar.cc/150?u=sarah',
      specialty: 'Nutrition & Cardio', status: 'Absent',
      hireDate: new Date('2022-01-20'), rating: 4.6, sessionsCount: 187,
      bio: 'Diététicienne sportive. Accompagnement perte de poids et performance.'
    },
    {
      id: 'C-005', firstName: 'Antoine', lastName: 'Moreau',
      email: 'antoine.moreau@gymelite.fr', phone: '06 56 78 90 12',
      avatar: 'https://i.pravatar.cc/150?u=antoine',
      specialty: 'Musculation & Cardio', status: 'Actif',
      hireDate: new Date('2023-04-05'), rating: 4.5, sessionsCount: 96,
      bio: 'Préparateur physique ancien club de football pro. Coach certifié BPJEPS.'
    },
  ]);

  /* ══════════ PLANS ══════════ */
  plans = signal<Plan[]>([
    {
      id: 'P-001', name: 'Standard', price: 49,
      duration: 'Mensuel', color: 'blue',
      access: ['Musculation', 'Cardio', 'Vestiaires premium'],
      subscribersCount: 420, isPopular: false,
      description: 'Accès illimité salle de musculation et cardio'
    },
    {
      id: 'P-002', name: 'Premium', price: 89,
      duration: 'Mensuel', color: 'gold',
      access: ['Musculation', 'Cardio', 'Cours collectifs', 'Sauna', 'Bilan forme'],
      subscribersCount: 310, isPopular: true,
      description: 'Accès complet + cours collectifs illimités'
    },
    {
      id: 'P-003', name: 'Elite CrossFit', price: 129,
      duration: 'Mensuel', color: 'purple',
      access: ['Accès illimité', 'CrossFit WOD', 'Coach dédié', 'Programme nutrition', 'Suivi personnalisé'],
      subscribersCount: 238, isPopular: false,
      description: 'Formule CrossFit intensive avec coaching personnalisé'
    },
    {
      id: 'P-004', name: 'Annuel VIP', price: 799,
      duration: 'Annuel', color: 'emerald',
      access: ['Accès total 24/7', 'Coach personnel', 'Plan nutrition', 'Spa & Massage', 'Guest pass ×12'],
      subscribersCount: 280, isPopular: false,
      description: 'L\'expérience ultime — tout inclus toute l\'année'
    },
  ]);

  /* ══════════ MEMBERS ══════════ */
  members = signal<GymMember[]>([
    {
      id: 'M-001', name: 'Sophie Laurent', email: 'sophie.l@email.com',
      phone: '06 11 22 33 44', avatar: 'https://i.pravatar.cc/150?u=1',
      planId: 'P-002', planName: 'Premium', status: 'Actif',
      joinDate: new Date('2025-01-10'), expiryDate: new Date('2026-05-10'),
      paymentStatus: 'Payé', paymentMethod: 'Carte', amount: 89, assignedCoachId: 'C-002'
    },
    {
      id: 'M-002', name: 'Lucas Martin', email: 'lucas.m@email.com',
      phone: '06 22 33 44 55', avatar: 'https://i.pravatar.cc/150?u=2',
      planId: 'P-003', planName: 'Elite CrossFit', status: 'Actif',
      joinDate: new Date('2024-11-05'), expiryDate: new Date('2026-04-05'),
      paymentStatus: 'Payé', paymentMethod: 'Virement', amount: 129, assignedCoachId: 'C-003'
    },
    {
      id: 'M-003', name: 'Emma Bernard', email: 'emma.b@email.com',
      phone: '06 33 44 55 66', avatar: 'https://i.pravatar.cc/150?u=3',
      planId: 'P-001', planName: 'Standard', status: 'En attente',
      joinDate: new Date('2026-03-28'), expiryDate: new Date('2026-04-28'),
      paymentStatus: 'En attente', paymentMethod: 'Cash', amount: 49
    },
    {
      id: 'M-004', name: 'Thomas Renard', email: 'thomas.r@email.com',
      phone: '06 44 55 66 77', avatar: 'https://i.pravatar.cc/150?u=4',
      planId: 'P-002', planName: 'Premium', status: 'Actif',
      joinDate: new Date('2025-06-15'), expiryDate: new Date('2026-04-08'),
      paymentStatus: 'Payé', paymentMethod: 'Carte', amount: 89, assignedCoachId: 'C-001'
    },
    {
      id: 'M-005', name: 'Camille Morin', email: 'camille.m@email.com',
      phone: '06 55 66 77 88', avatar: 'https://i.pravatar.cc/150?u=5',
      planId: 'P-004', planName: 'Annuel VIP', status: 'Actif',
      joinDate: new Date('2026-01-01'), expiryDate: new Date('2026-12-31'),
      paymentStatus: 'Payé', paymentMethod: 'Virement', amount: 799, assignedCoachId: 'C-001'
    },
    {
      id: 'M-006', name: 'Pierre Dumont', email: 'pierre.d@email.com',
      phone: '06 66 77 88 99', avatar: 'https://i.pravatar.cc/150?u=6',
      planId: 'P-001', planName: 'Standard', status: 'Expiré',
      joinDate: new Date('2025-02-01'), expiryDate: new Date('2026-03-01'),
      paymentStatus: 'Échoué', paymentMethod: 'Carte', amount: 49
    },
    {
      id: 'M-007', name: 'Léa Fontaine', email: 'lea.f@email.com',
      phone: '06 77 88 99 00', avatar: 'https://i.pravatar.cc/150?u=7',
      planId: 'P-002', planName: 'Premium', status: 'Actif',
      joinDate: new Date('2025-09-20'), expiryDate: new Date('2026-04-10'),
      paymentStatus: 'Payé', paymentMethod: 'Carte', amount: 89, assignedCoachId: 'C-004'
    },
    {
      id: 'M-008', name: 'Hugo Petit', email: 'hugo.p@email.com',
      phone: '06 88 99 00 11', avatar: 'https://i.pravatar.cc/150?u=8',
      planId: 'P-003', planName: 'Elite CrossFit', status: 'Actif',
      joinDate: new Date('2026-02-14'), expiryDate: new Date('2026-05-14'),
      paymentStatus: 'Payé', paymentMethod: 'Virement', amount: 129, assignedCoachId: 'C-003'
    },
  ]);

  /* ══════════ PENDING PAYMENTS ══════════ */
  pendingPayments = signal<PendingPayment[]>([
    {
      id: 'PP-001', memberId: 'M-006', memberName: 'Pierre Dumont',
      memberAvatar: 'https://i.pravatar.cc/150?u=6',
      amount: 49, daysOverdue: 25, plan: 'Standard', phone: '06 66 77 88 99'
    },
    {
      id: 'PP-002', memberId: 'M-012', memberName: 'Adrien Chevalier',
      memberAvatar: 'https://i.pravatar.cc/150?u=12',
      amount: 89, daysOverdue: 18, plan: 'Premium', phone: '06 12 98 76 54'
    },
    {
      id: 'PP-003', memberId: 'M-019', memberName: 'Isabelle Marchand',
      memberAvatar: 'https://i.pravatar.cc/150?u=19',
      amount: 129, daysOverdue: 12, plan: 'Elite CrossFit', phone: '06 23 87 65 43'
    },
    {
      id: 'PP-004', memberId: 'M-031', memberName: 'Romain Garnier',
      memberAvatar: 'https://i.pravatar.cc/150?u=31',
      amount: 49, daysOverdue: 7, plan: 'Standard', phone: '06 34 76 54 32'
    },
    {
      id: 'PP-005', memberId: 'M-003', memberName: 'Emma Bernard',
      memberAvatar: 'https://i.pravatar.cc/150?u=3',
      amount: 49, daysOverdue: 3, plan: 'Standard', phone: '06 33 44 55 66'
    },
  ]);

  /* ══════════ COURSE SLOTS ══════════ */
  slots = signal<CourseSlot[]>([
    { id: 'S-001', name: 'CrossFit WOD', coachId: 'C-003', coachName: 'Thomas D.', day: 0, startHour: 7,   duration: 60,  capacity: 20, enrolled: 18, type: 'crossfit',     color: '#EF4444' },
    { id: 'S-002', name: 'Yoga Flow',    coachId: 'C-002', coachName: 'Julie V.',  day: 0, startHour: 9,   duration: 90,  capacity: 15, enrolled: 12, type: 'yoga',         color: '#8B5CF6' },
    { id: 'S-003', name: 'HIIT Cardio',  coachId: 'C-003', coachName: 'Thomas D.', day: 1, startHour: 18,  duration: 45,  capacity: 25, enrolled: 22, type: 'cardio',       color: '#F97316' },
    { id: 'S-004', name: 'Powerlifting', coachId: 'C-001', coachName: 'Marc L.',   day: 1, startHour: 19,  duration: 60,  capacity: 10, enrolled: 8,  type: 'powerlifting', color: '#D4AF37' },
    { id: 'S-005', name: 'Pilates',      coachId: 'C-002', coachName: 'Julie V.',  day: 2, startHour: 10,  duration: 60,  capacity: 12, enrolled: 10, type: 'pilates',      color: '#EC4899' },
    { id: 'S-006', name: 'CrossFit WOD', coachId: 'C-003', coachName: 'Thomas D.', day: 2, startHour: 18,  duration: 60,  capacity: 20, enrolled: 20, type: 'crossfit',     color: '#EF4444' },
    { id: 'S-007', name: 'Yoga Débutant',coachId: 'C-002', coachName: 'Julie V.',  day: 3, startHour: 7,   duration: 75,  capacity: 15, enrolled: 9,  type: 'yoga',         color: '#8B5CF6' },
    { id: 'S-008', name: 'HIIT Cardio',  coachId: 'C-003', coachName: 'Thomas D.', day: 3, startHour: 20,  duration: 45,  capacity: 25, enrolled: 16, type: 'cardio',       color: '#F97316' },
    { id: 'S-009', name: 'Musculation',  coachId: 'C-001', coachName: 'Marc L.',   day: 4, startHour: 17,  duration: 90,  capacity: 15, enrolled: 14, type: 'powerlifting', color: '#D4AF37' },
    { id: 'S-010', name: 'CrossFit WOD', coachId: 'C-003', coachName: 'Thomas D.', day: 4, startHour: 18,  duration: 60,  capacity: 20, enrolled: 19, type: 'crossfit',     color: '#EF4444' },
    { id: 'S-011', name: 'Yoga Flow',    coachId: 'C-002', coachName: 'Julie V.',  day: 5, startHour: 9,   duration: 90,  capacity: 15, enrolled: 15, type: 'yoga',         color: '#8B5CF6' },
    { id: 'S-012', name: 'Bootcamp',     coachId: 'C-005', coachName: 'Antoine M.',day: 6, startHour: 10,  duration: 60,  capacity: 20, enrolled: 11, type: 'cardio',       color: '#F97316' },
  ]);

  /* ══════════ SHOP CATEGORIES ══════════ */
  shopCategories = signal<ShopCategory[]>([
    { id: 'SC-001', name: 'Suppléments',  icon: 'fas fa-flask',       current: 3240, previous: 2980, history: [2400,2600,2800,2700,2980,3240], color: '#D4AF37' },
    { id: 'SC-002', name: 'Vêtements',   icon: 'fas fa-tshirt',      current: 1850, previous: 1620, history: [1200,1400,1500,1600,1620,1850], color: '#8B5CF6' },
    { id: 'SC-003', name: 'Coaching',    icon: 'fas fa-user-tie',    current: 2100, previous: 2350, history: [2600,2500,2400,2300,2350,2100], color: '#3B82F6' },
    { id: 'SC-004', name: 'Nutrition',   icon: 'fas fa-apple-alt',   current: 980,  previous: 820,  history: [600,700,750,800,820,980],  color: '#10B981' },
  ]);

  /* ══════════ COMPUTED ══════════ */
  totalMonthlyRevenue = computed(() =>
    this.members().filter(m => m.paymentStatus === 'Payé').reduce((s, m) => s + m.amount, 0)
  );

  totalShopRevenue = computed(() =>
    this.shopCategories().reduce((s, c) => s + c.current, 0)
  );

  activeMembers = computed(() =>
    this.members().filter(m => m.status === 'Actif').length
  );

  expiringThisWeek = computed(() => {
    const now = Date.now();
    const week = 7 * 86400000;
    return this.members().filter(m => {
      const diff = m.expiryDate.getTime() - now;
      return diff > 0 && diff <= week;
    }).length;
  });

  pendingPaymentsCount = computed(() => this.pendingPayments().length);

  totalUnpaid = computed(() =>
    this.pendingPayments().reduce((s, p) => s + p.amount, 0)
  );

  activeCoaches = computed(() =>
    this.coaches().filter(c => c.status === 'Actif').length
  );

  recoveryRate = computed(() => {
    const total = this.members().length;
    const paid  = this.members().filter(m => m.paymentStatus === 'Payé').length;
    return total > 0 ? ((paid / total) * 100).toFixed(1) : '0';
  });

  /* ══════════ COACHES METHODS ══════════ */
  addCoach(coach: Omit<Coach, 'id'>) {
    const id = `C-${String(this.coaches().length + 1).padStart(3, '0')}`;
    this.coaches.update(list => [...list, { ...coach, id }]);
  }

  updateCoach(id: string, patch: Partial<Coach>) {
    this.coaches.update(list => list.map(c => c.id === id ? { ...c, ...patch } : c));
  }

  deleteCoach(id: string) {
    this.coaches.update(list => list.filter(c => c.id !== id));
  }

  /* ══════════ PLANS METHODS ══════════ */
  addPlan(plan: Omit<Plan, 'id'>) {
    const id = `P-${String(this.plans().length + 1).padStart(3, '0')}`;
    this.plans.update(list => [...list, { ...plan, id }]);
  }

  updatePlan(id: string, patch: Partial<Plan>) {
    this.plans.update(list => list.map(p => p.id === id ? { ...p, ...patch } : p));
  }

  /* ══════════ MEMBERS METHODS ══════════ */
  addMember(member: Omit<GymMember, 'id'>) {
    const id = `M-${String(this.members().length + 1).padStart(3, '0')}`;
    this.members.update(list => [{ ...member, id }, ...list]);
  }

  /* ══════════ PAYMENTS METHODS ══════════ */
  sendReminder(paymentId: string) {
    const snapshot = this.pendingPayments();
    this.pendingPayments.set(
      snapshot.map(p => p.id === paymentId ? { ...p, lastReminderSent: new Date() } : p)
    );
  }

  sendAllReminders() {
    const snapshot = this.pendingPayments();
    this.pendingPayments.set(
      snapshot.map(p => ({ ...p, lastReminderSent: new Date() }))
    );
  }

  /* ══════════ SLOTS METHODS ══════════ */
  addSlot(slot: Omit<CourseSlot, 'id'>) {
    const id = `S-${String(this.slots().length + 1).padStart(3, '0')}`;
    this.slots.update(list => [...list, { ...slot, id }]);
  }

  deleteSlot(id: string) {
    this.slots.update(list => list.filter(s => s.id !== id));
  }

  /* ══════════ SHOP METHODS ══════════ */
  addShopSale(categoryId: string, amount: number) {
    const snapshot = this.shopCategories();
    this.shopCategories.set(
      snapshot.map(c => c.id === categoryId
        ? { ...c, current: c.current + amount, history: [...c.history, c.current + amount] }
        : c
      )
    );
  }
}
