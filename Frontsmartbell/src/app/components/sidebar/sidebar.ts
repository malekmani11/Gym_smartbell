import { Component, signal, computed, inject, Input, Output, EventEmitter, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { StatisticsApiService } from '../../services/statistics-api.service';

interface NavItem {
  icon: string;
  label: string;
  route: string;
  badge?: number;
  badgeColor?: 'gold' | 'red' | 'blue';
  section?: string;
  roles?: ('ADMIN' | 'COACH' | 'MEMBER')[]; // if absent, visible to all authenticated roles
}

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './sidebar.html',
  styleUrl: './sidebar.css'
})
export class Sidebar implements OnInit {
  private router  = inject(Router);
  private auth    = inject(AuthService);
  private statsApi = inject(StatisticsApiService);

  userName = computed(() => {
    const user = this.auth.currentUser();
    if (!user) return 'Admin';
    return `${user.firstName || ''} ${user.lastName || ''}`.trim() || user.email || 'Admin';
  });

  userEmail = computed(() => {
    return this.auth.currentUser()?.email || 'admin@gympro.fr';
  });

  userAvatar = computed(() => {
    const user = this.auth.currentUser();
    return `https://i.pravatar.cc/150?u=${user?.email || 'admin'}`;
  });

  isAdmin  = computed(() => this.auth.currentUser()?.role === 'ROLE_ADMIN');
  isCoach  = computed(() => this.auth.currentUser()?.role === 'ROLE_COACH');
  isMember = computed(() => this.auth.currentUser()?.role === 'ROLE_MEMBER');

  private currentRoleKey = computed<'ADMIN' | 'COACH' | 'MEMBER' | null>(() => {
    const r = this.auth.currentUser()?.role ?? '';
    if (r === 'ROLE_ADMIN')  return 'ADMIN';
    if (r === 'ROLE_COACH')  return 'COACH';
    if (r === 'ROLE_MEMBER') return 'MEMBER';
    return null;
  });

  visibleNavItems = computed(() => {
    const role = this.currentRoleKey();
    return this.navItems().filter(item =>
      !item.roles || (role !== null && item.roles.includes(role))
    );
  });

  @Input() collapsed = false;
  @Output() toggleCollapse = new EventEmitter<void>();

  showLogoutConfirm = signal(false);

  ngOnInit() {
    this.statsApi.getDashboard().subscribe({
      next: (stats) => {
        this.navItems.update(items => items.map(item => {
          if (item.route === '/members')       return { ...item, badge: stats.expiringSoonCount   || undefined };
          if (item.route === '/subscriptions') return { ...item, badge: stats.expiredSubscriptions || undefined };
          if (item.route === '/schedule')      return { ...item, badge: stats.totalCourses         || undefined };
          if (item.route === '/payments')      return { ...item, badge: undefined };
          return item;
        }));
      },
      error: () => {
        // leave static badges as-is on error
      }
    });
  }

  toggle() {
    this.toggleCollapse.emit();
  }

  logout() {
    this.showLogoutConfirm.set(false);
    this.auth.logout();
  }

  navItems = signal<NavItem[]>([
    { icon: 'fas fa-th-large',          label: 'Dashboard',      route: '/dashboard',      roles: ['ADMIN'] },
    { icon: 'fas fa-users',             label: 'Membres',        route: '/members',        roles: ['ADMIN'], badgeColor: 'gold' },
    { icon: 'fas fa-user-tie',          label: 'Coachs',         route: '/coaches',        roles: ['ADMIN'] },
    { icon: 'fas fa-id-card',           label: 'Abonnements',    route: '/subscriptions',  roles: ['ADMIN'], badgeColor: 'red' },
    { icon: 'fas fa-calendar-alt',      label: 'Cours',          route: '/schedule',       roles: ['ADMIN', 'COACH'], badgeColor: 'blue' },
    // ── Gestion & Outils ───────────────────────────────────────────────────
    { icon: 'fas fa-credit-card',       label: 'Paiement',       route: '/payments',       roles: ['ADMIN'], section: 'Gestion' },
    { icon: 'fas fa-door-open',         label: 'Salles',         route: '/rooms',          roles: ['ADMIN'] },
    { icon: 'fas fa-ticket-alt',        label: 'Événements',     route: '/events',         roles: ['ADMIN'] },
    { icon: 'fas fa-dumbbell',          label: 'Machines',       route: '/equipment',      roles: ['ADMIN'] },
    { icon: 'fas fa-bell',             label: 'Notifications',   route: '/notifications',  roles: ['ADMIN'] },
    { icon: 'fas fa-exclamation-circle', label: 'Plaintes',      route: '/complaints',     roles: ['ADMIN'], badgeColor: 'red' },
  ]);
}
