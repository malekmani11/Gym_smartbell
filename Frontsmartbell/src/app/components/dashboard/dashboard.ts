import { Component, signal, computed, inject, OnInit, AfterViewInit } from '@angular/core';
import { ToastService } from '../../services/toast.service';
import { StatisticsApiService } from '../../services/statistics-api.service';
import { MemberApiService } from '../../services/member-api.service';
import { CourseApiService } from '../../services/course-api.service';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AttendanceHeatmapComponent } from './attendance-heatmap.component';
import { MemberProfileModalComponent, MemberProfile } from './member-profile-modal.component';
import { MemberLeaderboardComponent } from './member-leaderboard.component';
import { SubscriptionChartComponent } from './subscription-chart.component';
import { RevenueForecastComponent } from './revenue-forecast.component';
import { PendingPaymentsComponent } from './pending-payments.component';
import { MonthlyRevenueChartComponent } from './monthly-revenue-chart.component';
import { ExpiringSubscriptionsAlertComponent } from './expiring-subscriptions-alert.component';
import { CrmComponent } from '../crm/crm.component';

interface KpiMetric {
  title: string;
  value: string;
  trend: string;
  trendUp: boolean;
  icon: string;
  description?: string;
  sparklineData: number[];
}

interface Member {
  id: string;
  name: string;
  email: string;
  avatar: string;
  plan: string;
  status: 'active' | 'expired' | 'pending';
  joinDate: Date;
  expiryDate?: Date;
}

interface QuickAction {
  label: string;
  icon: string;
  color: string;
  description: string;
}

interface ClassAttendance {
  name: string;
  time: string;
  filled: number;
  capacity: number;
  coach: string;
}

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, FormsModule, AttendanceHeatmapComponent, MemberProfileModalComponent, MemberLeaderboardComponent, SubscriptionChartComponent, RevenueForecastComponent, PendingPaymentsComponent, MonthlyRevenueChartComponent, ExpiringSubscriptionsAlertComponent, CrmComponent],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.css'
})
export class Dashboard implements OnInit, AfterViewInit {
  private toast     = inject(ToastService);
  private statsApi  = inject(StatisticsApiService);
  private memberApi = inject(MemberApiService);
  private courseApi = inject(CourseApiService);

  // 🧪 State Management
  showNewMemberModal = signal(false);
  isProcessing = signal(false);
  selectedMember = signal<MemberProfile | null>(null);

  // 📊 KPIs principaux
  totalMembersCount   = signal(0);
  revenueCurrentMonth = signal(0);

  kpis = signal<KpiMetric[]>([
    { title: 'Total Membres',     value: '0',    trend: '', trendUp: true, icon: 'fas fa-users',          description: 'Membres enregistrés',        sparklineData: [] },
    { title: 'Revenus du mois',   value: '0 DT', trend: '', trendUp: true, icon: 'fas fa-money-bill-wave', description: 'Chiffre d\'affaires mensuel', sparklineData: [] },
    { title: 'Abonnements actifs',value: '0',    trend: '', trendUp: true, icon: 'fas fa-id-card',         description: 'Abonnements en cours',       sparklineData: [] },
    { title: 'Coachs actifs',     value: '0',    trend: '', trendUp: true, icon: 'fas fa-user-tie',        description: 'Coaches disponibles',        sparklineData: [] },
  ]);

  // 📈 Business Metrics
  totalMembers           = signal(0);
  activeMembers          = signal(0);
  lostMembers            = signal(0);
  monthlyRevenue         = signal(0);
  previousMonthlyRevenue = signal(0);
  acquisitionCost        = signal(0);
  newMembersCount        = signal(0);

  // 🔢 Computed Advanced KPIs
  retentionRate = computed(() => {
    const total = this.totalMembers();
    return total > 0 ? ((this.activeMembers() / total) * 100).toFixed(1) : '0.0';
  });

  churnRate = computed(() => {
    const total = this.totalMembers();
    return total > 0 ? ((this.lostMembers() / total) * 100).toFixed(1) : '0.0';
  });

  arpu = computed(() => {
    const active = this.activeMembers();
    return active > 0 ? (this.revenueCurrentMonth() / active).toFixed(2) : '0.00';
  });

  clv = computed(() => {
    const monthlyArpu  = parseFloat(this.arpu());
    const monthlyChurn = parseFloat(this.churnRate()) / 100;
    if (!monthlyArpu || isNaN(monthlyArpu)) return '0';
    return (monthlyArpu / (monthlyChurn || 0.01)).toFixed(0);
  });

  cac = computed(() => {
    const cost  = this.acquisitionCost();
    const count = this.newMembersCount();
    return cost > 0 && count > 0 ? (cost / count).toFixed(2) : '0.00';
  });

  ltvCacRatio = computed(() => {
    const cacVal = parseFloat(this.cac());
    return cacVal > 0 ? (parseFloat(this.clv()) / cacVal).toFixed(1) : '0.0';
  });

  revenueGrowthMoM = computed(() => {
    const prev = this.previousMonthlyRevenue();
    if (!prev) return '0.0';
    const growth = ((this.revenueCurrentMonth() - prev) / prev) * 100;
    return growth.toFixed(1);
  });

  // 📅 Classes affluence data
  attendanceData = signal<number[]>([]);

  // ⚡ Quick Actions
  quickActions = signal<QuickAction[]>([
    { label: 'Nouveau Membre', icon: 'fas fa-user-plus', color: 'bg-[#D4AF37]', description: 'Enregistrer un nouveau client' },
    { label: 'Paiement', icon: 'fas fa-credit-card', color: 'bg-green-500', description: 'Encaisser un abonnement' },
    { label: 'Planning', icon: 'fas fa-calendar-alt', color: 'bg-blue-500', description: 'Gérer les cours' },
    { label: 'Rapports AI', icon: 'fas fa-magic', color: 'bg-purple-500', description: 'Analyse prédictive Gemini' },
  ]);

  // 📅 Prochains Cours
  upcomingClasses = signal<ClassAttendance[]>([
    { name: 'CrossFit WOD', time: '18:00', filled: 18, capacity: 20, coach: 'Marc L.' },
    { name: 'Yoga Flow', time: '18:30', filled: 12, capacity: 15, coach: 'Julie V.' },
    { name: 'Powerlifting', time: '19:00', filled: 8, capacity: 10, coach: 'Thomas D.' },
    { name: 'HIIT Cardio', time: '19:30', filled: 22, capacity: 25, coach: 'Sarah G.' },
  ]);

  // 👥 Membres récents
  recentMembers = signal<Member[]>([]);

  // ────────────────────────────────────────────────────────────────
  //  LIFECYCLE
  // ────────────────────────────────────────────────────────────────

  ngOnInit() {
    this.statsApi.getDashboard().subscribe({
      next: (stats) => {
        const total    = stats.totalMembers   ?? 0;
        const active   = stats.activeMembers  ?? 0;
        const revenue  = Number(stats.revenueThisMonth ?? 0);
        const subs     = stats.activeSubscriptions ?? 0;
        const coaches  = stats.totalCoaches ?? 0;

        this.totalMembers.set(total);
        this.activeMembers.set(active);
        this.lostMembers.set(total - active);
        this.monthlyRevenue.set(revenue);
        this.revenueCurrentMonth.set(revenue);
        this.totalMembersCount.set(total);

        this.kpis.set([
          { title: 'Total Membres',      value: total.toLocaleString(),           trend: '', trendUp: true, icon: 'fas fa-users',          description: 'Membres enregistrés',        sparklineData: stats.memberTrend || [] },
          { title: 'Revenus du mois',    value: `${revenue.toLocaleString()} DT`, trend: '', trendUp: true, icon: 'fas fa-money-bill-wave', description: 'Chiffre d\'affaires mensuel', sparklineData: stats.revenueTrend || [] },
          { title: 'Abonnements actifs', value: subs.toLocaleString(),            trend: '', trendUp: true, icon: 'fas fa-id-card',         description: 'Abonnements en cours',       sparklineData: [] },
          { title: 'Coachs actifs',      value: coaches.toLocaleString(),         trend: '', trendUp: true, icon: 'fas fa-user-tie',        description: 'Coaches disponibles',        sparklineData: [] },
          { title: 'Présence',           value: `${(stats.attendanceRate || 0).toFixed(1)}%`, trend: '', trendUp: true, icon: 'fas fa-calendar-check', description: 'Taux de fréquentation', sparklineData: [] },
          { title: 'Équipements HS',     value: (stats.brokenMachinesCount || 0).toString(), trend: '', trendUp: false, icon: 'fas fa-tools', description: 'En maintenance/HS',       sparklineData: [] },
        ]);

        this.attendanceData.set(stats.revenueTrend || []);

        // Update gender split from API
        const male = stats.maleCount || 0;
        const female = stats.femaleCount || 0;
        const totalGender = male + female || 1;
        this.genderData.set({
          male:   Math.round((male   / totalGender) * 100),
          female: Math.round((female / totalGender) * 100),
        });

        // ── Déclencher les animations visuelles ──────────────────
        setTimeout(() => {
          this.animateCounters();
          this.animateAccentBars();
          this.animateBars();
        }, 400);
        setTimeout(() => this.animateSparklines(), 700);
        // ─────────────────────────────────────────────────────────
      },
      error: () => {
        this.kpis.set([
          { title: 'Total Membres',     value: '0',    trend: '', trendUp: true, icon: 'fas fa-users',          description: 'Membres enregistrés',        sparklineData: [] },
          { title: 'Revenus du mois',   value: '0 DT', trend: '', trendUp: true, icon: 'fas fa-money-bill-wave', description: 'Chiffre d\'affaires mensuel', sparklineData: [] },
          { title: 'Abonnements actifs',value: '0',    trend: '', trendUp: true, icon: 'fas fa-id-card',         description: 'Abonnements en cours',       sparklineData: [] },
          { title: 'Coachs actifs',     value: '0',    trend: '', trendUp: true, icon: 'fas fa-user-tie',        description: 'Coaches disponibles',        sparklineData: [] },
        ]);
      }
    });

    // Load recent members from API
    this.memberApi.getAll().subscribe({
      next: (response) => {
        const list = (response.content || []).slice(0, 5);
        if (list.length === 0) return;
        this.recentMembers.set(list.map(m => ({
          id:         `M-${String(m.id).padStart(3, '0')}`,
          name:       `${m.firstName} ${m.lastName}`,
          email:      m.email,
          avatar:     m.profileImageUrl || `https://i.pravatar.cc/150?u=member${m.id}`,
          plan:       m.planName || 'Standard',
          status:     this._mapMemberStatus(m.membershipStatus || 'ACTIVE'),
          joinDate:   m.joinDate ? new Date(m.joinDate) : new Date(),
        })));
      },
      error: () => {}
    });

    // Load today's upcoming courses from API
    this.courseApi.getAll().subscribe({
      next: (response) => {
        const JS_TO_BACKEND: Record<number, string> = {
          0: 'SUNDAY', 1: 'MONDAY', 2: 'TUESDAY', 3: 'WEDNESDAY',
          4: 'THURSDAY', 5: 'FRIDAY', 6: 'SATURDAY',
        };
        const todayEnum = JS_TO_BACKEND[new Date().getDay()];
        const now = new Date();
        const nowMinutes = now.getHours() * 60 + now.getMinutes();

        const todayCourses = (response.content || [])
          .filter(c => c.dayOfWeek === todayEnum)
          .filter(c => {
            const parts = (c.startTime || '').split(':').map(Number);
            return (parts[0] * 60 + (parts[1] || 0)) >= nowMinutes;
          })
          .slice(0, 4)
          .map(c => ({
            name:     c.name,
            time:     (c.startTime || '').slice(0, 5),
            filled:   c.currentParticipants ?? 0,
            capacity: c.maxParticipants,
            coach:    c.coachName ?? '—',
          }));

        if (todayCourses.length > 0) this.upcomingClasses.set(todayCourses);
      },
      error: () => {}
    });
  }

  ngAfterViewInit(): void {
    setTimeout(() => this.setupScrollAnimations(), 120);
  }

  // ────────────────────────────────────────────────────────────────
  //  ANIMATIONS PRIVÉES (visuel uniquement — zéro logique métier)
  // ────────────────────────────────────────────────────────────────

  /** IntersectionObserver : .panel-card entre en vue → classe .in-view */
  private setupScrollAnimations(): void {
    if (typeof IntersectionObserver === 'undefined') return;
    const cards = document.querySelectorAll<HTMLElement>('.panel-card');
    cards.forEach(c => c.classList.add('anim-ready'));

    const observer = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('in-view');
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.15 });

    cards.forEach(c => observer.observe(c));
  }

  /** Compteurs animés — easeOutCubic 1200 ms sur .kpi-value-text */
  private animateCounters(): void {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

    document.querySelectorAll<HTMLElement>('.kpi-value-text').forEach(el => {
      const raw = (el.textContent ?? '').trim();
      const match = raw.match(/^[\d,. ]+/);
      if (!match) return;
      const target = parseFloat(match[0].replace(/[,\s]/g, ''));
      if (isNaN(target) || target === 0) return;
      const suffix = raw.slice(match[0].length);
      const t0 = performance.now();
      const duration = 1200;
      const tick = (now: number) => {
        const p = Math.min((now - t0) / duration, 1);
        const ease = 1 - Math.pow(1 - p, 3);
        el.textContent = Math.floor(ease * target).toLocaleString() + suffix;
        if (p < 1) requestAnimationFrame(tick);
        else el.textContent = raw;
      };
      requestAnimationFrame(tick);
    });
  }

  /** Barre accent scaleX — chaque .kpi-accent-line reçoit .show */
  private animateAccentBars(): void {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    document.querySelectorAll('.kpi-accent-line').forEach((bar, i) => {
      setTimeout(() => bar.classList.add('show'), 400 + i * 100);
    });
  }

  /** Barres revenus scaleY — chaque .bar-animated reçoit .show */
  private animateBars(): void {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    document.querySelectorAll('.bar-animated').forEach((bar, i) => {
      setTimeout(() => bar.classList.add('show'), 500 + i * 80);
    });
  }

  /** Sparklines progressives — clip-path reveal sur .sparkline-animate-wrap */
  private animateSparklines(): void {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    document.querySelectorAll('.sparkline-animate-wrap').forEach((wrap, i) => {
      setTimeout(() => wrap.classList.add('spark-reveal'), i * 60);
    });
  }

  // ────────────────────────────────────────────────────────────────
  //  HELPERS EXISTANTS (inchangés)
  // ────────────────────────────────────────────────────────────────

  private _mapMemberStatus(s: string): 'active' | 'expired' | 'pending' {
    if (s === 'ACTIVE') return 'active';
    if (s === 'EXPIRED' || s === 'SUSPENDED' || s === 'INACTIVE') return 'expired';
    return 'pending';
  }

  getStatusBadgeClass(status: string): string {
    switch (status) {
      case 'active': return 'badge-active';
      case 'expired': return 'badge-expired';
      case 'pending': return 'badge-gold';
      default: return 'badge-active';
    }
  }

  onQuickAction(action: QuickAction) {
    if (action.label === 'Nouveau Membre') {
      this.showNewMemberModal.set(true);
    } else if (action.label === 'Paiement') {
      this.simulatePayment();
    } else if (action.label === 'Planning') {
      this.onViewPlanning();
      this.toast.info('Planning', 'Navigation vers le planning des cours.');
    } else {
      this.toast.info(action.label, action.description);
    }
  }

  onHeaderAction() { this.showNewMemberModal.set(true); }

  newMemberForm = { name: '', email: '', password: 'password123', plan: 'Standard' };

  confirmNewMember() {
    if (!this.newMemberForm.name.trim()) {
      this.toast.error('Champ requis', 'Le nom est obligatoire.');
      return;
    }
    this.isProcessing.set(true);
    const [firstName, ...rest] = this.newMemberForm.name.trim().split(' ');
    const lastName = rest.join(' ') || firstName;
    this.memberApi.register({
      firstName,
      lastName,
      email: this.newMemberForm.email || `user${Date.now()}@gym.com`,
      password: this.newMemberForm.password,
    }).subscribe({
      next: (m) => {
        this.toast.success('Membre ajouté', `${m.firstName} a été inscrit avec succès.`);
        this.isProcessing.set(false);
        this.showNewMemberModal.set(false);
        this.ngOnInit();
      },
      error: (err) => {
        this.toast.error('Erreur', err.error?.message || 'Impossible d\'ajouter le membre.');
        this.isProcessing.set(false);
      }
    });
  }

  simulatePayment() {
    const amount = 49;
    this.revenueCurrentMonth.update(rev => rev + amount);
    this.toast.success('Paiement encaissé', `${amount}DT encaissés — le CA a été mis à jour.`);
  }

  onChartFilter(period: string) {
    if (period === 'JOUR') {
      this.attendanceData.set([20, 35, 25, 45, 30, 50, 40]);
    } else {
      this.attendanceData.set([40, 65, 45, 85, 55, 95, 75]);
    }
  }

  onViewPlanning() {
    document.getElementById('planning')?.scrollIntoView({ behavior: 'smooth' });
  }

  onSmartAlertAction(type: string) {
    this.toast.success('Email envoyé', `Gemini AI a envoyé un email de ${type.toLowerCase()} au client.`);
  }

  onMemberClick(member: Member) {
    const profile: MemberProfile = {
      ...member,
      assignedCoach: 'Marc Leroux',
      goal: 'Prise de masse',
      currentWeight: 82,
      targetWeight: 88,
      progressPercent: 65,
      sessionsThisMonth: 14,
      currentStreak: 7,
      lastVisit: new Date(),
      favoriteCourses: ['CrossFit WOD', 'Powerlifting', 'HIIT Cardio'],
      courseHistory: [
        { name: 'CrossFit WOD', date: new Date(Date.now() - 1 * 86400000), coach: 'Marc L.', duration: '1h00' },
        { name: 'Powerlifting', date: new Date(Date.now() - 3 * 86400000), coach: 'Thomas D.', duration: '1h15' },
        { name: 'HIIT Cardio',  date: new Date(Date.now() - 5 * 86400000), coach: 'Sarah G.', duration: '45m' },
        { name: 'CrossFit WOD', date: new Date(Date.now() - 7 * 86400000), coach: 'Marc L.', duration: '1h00' },
        { name: 'Yoga Flow',    date: new Date(Date.now() - 10 * 86400000), coach: 'Julie V.', duration: '1h30' },
      ],
    };
    this.selectedMember.set(profile);
  }

  closeMemberProfile() { this.selectedMember.set(null); }

  genderData = signal({ male: 62, female: 38 });

  getGenderDash(percent: number): string {
    const circ = 2 * Math.PI * 54;
    return `${(circ * percent / 100).toFixed(1)} ${circ.toFixed(1)}`;
  }

  getGenderOffset(skipPercent: number): string {
    const circ = 2 * Math.PI * 54;
    return `${-(circ * skipPercent / 100).toFixed(1)}`;
  }

  getSparklinePoints(data: number[]): string {
    if (data.length < 2) return '';
    const min = Math.min(...data);
    const max = Math.max(...data);
    const range = max - min || 1;
    const w = 100;
    const h = 32;
    const step = w / (data.length - 1);
    return data
      .map((v, i) => `${(i * step).toFixed(1)},${(h - ((v - min) / range) * (h - 4) - 2).toFixed(1)}`)
      .join(' ');
  }

  getDaysUntil(date: Date): number {
    return Math.ceil((new Date(date).getTime() - Date.now()) / 86400000);
  }

  onPaymentAction(event: { type: string; memberId: string }) {
    const messages: Record<string, string> = {
      REMINDER:     `Rappel de paiement envoyé au membre ${event.memberId}.`,
      ALL_REMINDER: `Rappels envoyés à tous les membres en retard.`,
    };
    console.log(messages[event.type] ?? `Action paiement : ${event.type}`);
  }

  onAlertAction(event: { type: string; member: { name: string } }) {
    const messages: Record<string, string> = {
      retention: `Email de rétention envoyé à ${event.member.name}.`,
      renewal:   `Rappel de renouvellement envoyé à ${event.member.name}.`,
    };
    this.toast.success('Action effectuée', messages[event.type] ?? 'Action effectuée.');
  }

  onNotificationAction(event: { type: string; notification: { title: string; actionLabel?: string } }) {
    const messages: Record<string, string> = {
      expiry:  'Rappel envoyé au membre.',
      payment: 'Reçu de paiement ouvert.',
      member:  'Profil membre chargé.',
      ai:      'Analyse Gemini AI affichée.',
      alert:   'Calendrier de planning ouvert.',
    };
    const msg = messages[event.type] ?? `Action : ${event.notification.actionLabel}`;
    this.toast.info('Notification', msg);
  }
}
