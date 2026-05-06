import { Component, signal, computed, inject, HostListener, ElementRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, NavigationEnd } from '@angular/router';
import { filter } from 'rxjs/operators';
import { NotificationPanelComponent } from '../dashboard/notification-panel.component';
import { AuthService } from '../../services/auth.service';
import { ThemeToggleComponent } from '../shared/theme-toggle/theme-toggle.component';


interface SearchItem {
  label: string;
  sublabel: string;
  icon: string;
  category: 'Membres' | 'Coachs' | 'Pages';
  route?: string;
}

const SEARCH_DATA: SearchItem[] = [
  // Membres
  { label: 'Sophie Laurent',  sublabel: 'Yoga Premium',         icon: 'fas fa-user',               category: 'Membres' },
  { label: 'Lucas Martin',    sublabel: 'CrossFit Elite',        icon: 'fas fa-user',               category: 'Membres' },
  { label: 'Emma Bernard',    sublabel: 'Standard',              icon: 'fas fa-user',               category: 'Membres' },
  { label: 'Thomas Renard',   sublabel: 'Standard Premium',      icon: 'fas fa-user',               category: 'Membres' },
  { label: 'Camille Morin',   sublabel: 'VIP Elite',             icon: 'fas fa-user',               category: 'Membres' },
  // Coachs
  { label: 'Marc Leroux',     sublabel: 'Bodybuilding',          icon: 'fas fa-user-tie',           category: 'Coachs'  },
  { label: 'Julie Vasseur',   sublabel: 'Yoga & Pilates',        icon: 'fas fa-user-tie',           category: 'Coachs'  },
  { label: 'Thomas Durand',   sublabel: 'CrossFit',              icon: 'fas fa-user-tie',           category: 'Coachs'  },
  { label: 'Sarah Guerin',    sublabel: 'Nutrition',             icon: 'fas fa-user-tie',           category: 'Coachs'  },
  // Pages
  { label: 'Dashboard',       sublabel: 'Vue générale',          icon: 'fas fa-tachometer-alt',     category: 'Pages',  route: '/dashboard'     },
  { label: 'Membres',         sublabel: 'Gestion adhérents',     icon: 'fas fa-users',              category: 'Pages',  route: '/members'       },
  { label: 'Coachs',          sublabel: "Équipe d'experts",      icon: 'fas fa-chalkboard-teacher', category: 'Pages',  route: '/coaches'       },
  { label: 'Abonnements',     sublabel: 'Formules & contrats',   icon: 'fas fa-id-card',            category: 'Pages',  route: '/subscriptions' },
  { label: 'Paiements',       sublabel: 'Transactions & revenus',icon: 'fas fa-credit-card',        category: 'Pages',  route: '/payments'      },
  { label: 'Salles',          sublabel: 'Gestion des espaces',   icon: 'fas fa-door-open',          category: 'Pages',  route: '/rooms'         },
  { label: 'Machines',        sublabel: 'Équipements & maintenance', icon: 'fas fa-dumbbell',       category: 'Pages',  route: '/equipment'     },
  { label: 'CRM',             sublabel: 'Pipeline & prospects',  icon: 'fas fa-address-book',       category: 'Pages',  route: '/dashboard'     },
];

@Component({
  selector: 'app-topbar',
  standalone: true,
  imports: [CommonModule, NotificationPanelComponent, ThemeToggleComponent],
  templateUrl: './topbar.html',
  styleUrl: './topbar.css'
})
export class Topbar {
  private auth = inject(AuthService);

  userName = computed(() => {
    const user = this.auth.currentUser();
    if (!user) return 'Admin';
    const first = user.firstName || '';
    const last  = user.lastName  || '';
    return `${first} ${last}`.trim() || user.email || 'Admin';
  });

  userRole = computed(() => {
    const user = this.auth.currentUser();
    const role = user?.role ?? '';
    if (role.includes('ADMIN')) return 'Administrateur';
    if (role.includes('COACH')) return 'Coach';
    if (role.includes('MEMBER')) return 'Membre';
    return 'Manager';
  });

  userAvatar = computed(() => {
    const user = this.auth.currentUser();
    return `https://i.pravatar.cc/150?u=${user?.email || 'admin'}`;
  });

  pageTitle    = signal('Tableau de bord');
  pageSubtitle = signal('');

  actionRapideOpen = signal(false);

  searchQuery   = signal('');
  showResults   = signal(false);

  searchResults = computed<SearchItem[]>(() => {
    const q = this.searchQuery().toLowerCase().trim();
    if (q.length < 2) return [];
    return SEARCH_DATA.filter(item =>
      item.label.toLowerCase().includes(q) ||
      item.sublabel.toLowerCase().includes(q)
    );
  });

  resultsByCategory = computed(() => {
    const categories: ('Membres' | 'Coachs' | 'Pages')[] = ['Membres', 'Coachs', 'Pages'];
    return categories
      .map(cat => ({ cat, items: this.searchResults().filter(r => r.category === cat) }))
      .filter(g => g.items.length > 0);
  });

  private router  = inject(Router);
  private elRef   = inject(ElementRef);

  private readonly routeTitles: Record<string, string> = {
    '/dashboard':     'Tableau de bord',
    '/members':       'Membres',
    '/coaches':       'Coachs',
    '/subscriptions': 'Abonnements',
    '/schedule':      'Cours',
    '/payments':      'Paiements',
    '/rooms':         'Salles',
    '/equipment':     'Machines',
    '/crm':           'CRM',
  };

  private readonly routeSubtitles: Record<string, string> = {
    '/dashboard':     'Vue d\'ensemble de votre salle',
    '/members':       'Gestion des adhérents',
    '/coaches':       'Équipe technique',
    '/subscriptions': 'Suivi des forfaits',
    '/schedule':      'Planning des cours',
    '/payments':      'Transactions et revenus',
    '/rooms':         'Gestion des espaces',
    '/equipment':     'Maintenance du matériel',
    '/crm':           'Pipeline de conversion',
  };

  constructor() {
    // Set title from current URL on first load
    const initialUrl = this.router.url.split('?')[0];
    this.pageTitle.set(this.routeTitles[initialUrl] ?? 'GymPro');
    this.pageSubtitle.set(this.routeSubtitles[initialUrl] ?? '');

    this.router.events
      .pipe(filter(e => e instanceof NavigationEnd))
      .subscribe(e => {
        const url = (e as NavigationEnd).urlAfterRedirects.split('?')[0];
        this.pageTitle.set(this.routeTitles[url] ?? 'GymPro');
        this.pageSubtitle.set(this.routeSubtitles[url] ?? '');
      });
  }

  onSearchInput(value: string) {
    this.searchQuery.set(value);
    this.showResults.set(true);
  }

  clearSearch() {
    this.searchQuery.set('');
    this.showResults.set(false);
  }

  selectResult(item: SearchItem) {
    if (item.route) this.router.navigate([item.route]);
    this.clearSearch();
  }

  onNotificationAction(_event: any) {
    // notification actions handled inside NotificationPanelComponent
  }

  onQuickAction(type: string) {
    this.actionRapideOpen.set(false);
    switch (type) {
      case 'member':
        localStorage.setItem('gym_open_modal', 'new_member');
        this.router.navigate(['/members']);
        this.actionRapideOpen.set(false);
        break;
      case 'coach':   this.router.navigate(['/coaches']);       break;
      case 'course':  this.router.navigate(['/schedule']);      break;
      case 'payment': this.router.navigate(['/payments']);      break;
    }
  }

  @HostListener('document:keydown', ['$event'])
  onKeydown(e: KeyboardEvent) {
    if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
      e.preventDefault();
      const input = this.elRef.nativeElement.querySelector('input[type="text"]') as HTMLInputElement | null;
      input?.focus();
      this.showResults.set(true);
    }
    if (e.key === 'Escape') {
      this.showResults.set(false);
      this.actionRapideOpen.set(false);
    }
  }

  @HostListener('document:click', ['$event'])
  onDocClick(e: MouseEvent) {
    if (!this.elRef.nativeElement.contains(e.target)) {
      this.showResults.set(false);
    }
  }
}
