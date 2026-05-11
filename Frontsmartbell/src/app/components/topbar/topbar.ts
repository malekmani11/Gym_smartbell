import { Component, signal, computed, inject, HostListener, ElementRef, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, NavigationEnd } from '@angular/router';
import { Subject, debounceTime, distinctUntilChanged, switchMap, of, takeUntil } from 'rxjs';
import { filter } from 'rxjs/operators';
import { NotificationPanelComponent } from '../dashboard/notification-panel.component';
import { AuthService } from '../../services/auth.service';
import { ThemeToggleComponent } from '../shared/theme-toggle/theme-toggle.component';
import { MemberApiService } from '../../services/member-api.service';

interface SearchItem {
  label: string;
  sublabel: string;
  icon: string;
  category: 'Membres' | 'Coachs' | 'Pages';
  route?: string;
}

const PAGES: SearchItem[] = [
  { label: 'Dashboard',    sublabel: 'Vue générale',              icon: 'fas fa-tachometer-alt',     category: 'Pages', route: '/dashboard'     },
  { label: 'Membres',      sublabel: 'Gestion adhérents',         icon: 'fas fa-users',              category: 'Pages', route: '/members'       },
  { label: 'Coachs',       sublabel: "Équipe d'experts",          icon: 'fas fa-chalkboard-teacher', category: 'Pages', route: '/coaches'       },
  { label: 'Abonnements',  sublabel: 'Formules & contrats',       icon: 'fas fa-id-card',            category: 'Pages', route: '/subscriptions' },
  { label: 'Paiements',    sublabel: 'Transactions & revenus',    icon: 'fas fa-credit-card',        category: 'Pages', route: '/payments'      },
  { label: 'Salles',       sublabel: 'Gestion des espaces',       icon: 'fas fa-door-open',          category: 'Pages', route: '/rooms'         },
  { label: 'Machines',     sublabel: 'Équipements & maintenance', icon: 'fas fa-dumbbell',           category: 'Pages', route: '/equipment'     },
];

@Component({
  selector: 'app-topbar',
  standalone: true,
  imports: [CommonModule, NotificationPanelComponent, ThemeToggleComponent],
  templateUrl: './topbar.html',
  styleUrl: './topbar.css'
})
export class Topbar implements OnDestroy {
  private auth      = inject(AuthService);
  private memberApi = inject(MemberApiService);
  private destroy$  = new Subject<void>();

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
  searchLoading = signal(false);

  private searchSubject = new Subject<string>();
  apiMembers = signal<SearchItem[]>([]);

  // Pages sont statiques — filtrées localement
  pageResults = computed<SearchItem[]>(() => {
    const q = this.searchQuery().toLowerCase().trim();
    if (q.length < 2) return [];
    return PAGES.filter(p => p.label.toLowerCase().includes(q));
  });

  resultsByCategory = computed(() => {
    const members = this.apiMembers();
    const pages   = this.pageResults();
    const groups: { cat: string; items: SearchItem[] }[] = [];
    if (members.length) groups.push({ cat: 'Membres', items: members });
    if (pages.length)   groups.push({ cat: 'Pages',   items: pages   });
    return groups;
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

    // Debounce la recherche membres : attend 350ms après la dernière frappe
    this.searchSubject.pipe(
      debounceTime(350),
      distinctUntilChanged(),
      switchMap(q => {
        if (q.length < 2) { this.apiMembers.set([]); return of(null); }
        this.searchLoading.set(true);
        return this.memberApi.getAll(0, 6, q);
      }),
      takeUntil(this.destroy$)
    ).subscribe(res => {
      this.searchLoading.set(false);
      if (!res) return;
      const items: SearchItem[] = res.content.map(m => ({
        label:    `${m.firstName} ${m.lastName}`,
        sublabel: m.planName || m.email || '',
        icon:     'fas fa-user',
        category: 'Membres' as const,
        route:    '/members',
      }));
      this.apiMembers.set(items);
    });
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  onSearchInput(value: string) {
    this.searchQuery.set(value);
    this.showResults.set(true);
    this.searchSubject.next(value.trim());
    if (value.trim().length < 2) this.apiMembers.set([]);
  }

  clearSearch() {
    this.searchQuery.set('');
    this.showResults.set(false);
    this.apiMembers.set([]);
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
