import { Routes } from '@angular/router';
import { Layout } from './components/layout/layout';
import { authGuard } from './guards/auth.guard';

export const routes: Routes = [
  {
    path: 'login',
    loadComponent: () =>
      import('./pages/login/login.component')
        .then(m => m.LoginComponent),
    title: 'Connexion — GymPro',
  },
  {
    path: 'register',
    loadComponent: () =>
      import('./pages/register/register.component')
        .then(m => m.RegisterComponent),
    title: 'Inscription — GymPro',
  },
  {
    path: 'unauthorized',
    loadComponent: () =>
      import('./pages/unauthorized/unauthorized.component')
        .then(m => m.UnauthorizedComponent),
    title: 'Accès Refusé — GymPro',
  },
  {
    path: '',
    component: Layout,
    canActivate: [authGuard],
    data: { roles: ['ADMIN'] },
    children: [
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
      {
        path: 'dashboard',
        loadComponent: () =>
          import('./components/dashboard/dashboard')
            .then(m => m.Dashboard),
        title: 'Dashboard — GymPro',
        data: { roles: ['ADMIN'] },
      },
      {
        path: 'members',
        loadComponent: () =>
          import('./components/members/members')
            .then(m => m.Members),
        title: 'Membres — GymPro',
        data: { roles: ['ADMIN'] },
      },
      {
        path: 'coaches',
        loadComponent: () =>
          import('./components/coaches/coaches')
            .then(m => m.Coaches),
        title: 'Coachs — GymPro',
        data: { roles: ['ADMIN'] },
      },
      {
        path: 'subscriptions',
        loadComponent: () =>
          import('./components/subscriptions/subscriptions')
            .then(m => m.Subscriptions),
        title: 'Abonnements — GymPro',
        data: { roles: ['ADMIN'] },
      },
      {
        path: 'schedule',
        loadComponent: () =>
          import('./components/schedule/schedule')
            .then(m => m.Schedule),
        title: 'Cours — GymPro',
        data: { roles: ['ADMIN', 'COACH'] },
      },
      {
        path: 'payments',
        loadComponent: () =>
          import('./components/paiement/paiement.component')
            .then(m => m.PaiementComponent),
        title: 'Paiements — GymPro',
        data: { roles: ['ADMIN'] },
      },
      {
        path: 'rooms',
        loadComponent: () =>
          import('./components/salles/salles.component')
            .then(m => m.SallesComponent),
        title: 'Salles — GymPro',
        data: { roles: ['ADMIN'] },
      },
      {
        path: 'events',
        loadComponent: () =>
          import('./components/events/events.component')
            .then(m => m.EventsComponent),
        title: 'Événements — GymPro',
        data: { roles: ['ADMIN'] },
      },
      {
        path: 'equipment',
        loadComponent: () =>
          import('./components/machines/machines.component')
            .then(m => m.MachinesComponent),
        title: 'Machines — GymPro',
        data: { roles: ['ADMIN'] },
      },
      {
        path: 'notifications',
        loadComponent: () =>
          import('./components/notifications/notifications.component')
            .then(m => m.NotificationsComponent),
        title: 'Notifications — GymPro',
        data: { roles: ['ADMIN'] },
      },
      {
        path: 'complaints',
        loadComponent: () =>
          import('./components/complaints/complaints.component')
            .then(m => m.ComplaintsComponent),
        title: 'Plaintes — GymPro',
        data: { roles: ['ADMIN'] },
      },
      { path: '**', redirectTo: 'dashboard' },
    ],
  },
];
