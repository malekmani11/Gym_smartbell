import { inject } from '@angular/core';
import { ActivatedRouteSnapshot, CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

export const authGuard: CanActivateFn = (route: ActivatedRouteSnapshot) => {
  const auth   = inject(AuthService);
  const router = inject(Router);

  if (!auth.isAuthenticated()) {
    router.navigate(['/login']);
    return false;
  }

  const userRole  = auth.currentUser()?.role ?? '';
  // Route can declare required roles via data: { roles: ['ADMIN'] }
  const required: string[] = route.data?.['roles'] ?? ['ADMIN'];
  const hasAccess = required.some(r => userRole === `ROLE_${r}`);

  if (hasAccess) {
    return true;
  }

  router.navigate(['/unauthorized']);
  return false;
};
