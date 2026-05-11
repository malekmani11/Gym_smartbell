import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject, Injector } from '@angular/core';
import { catchError, throwError } from 'rxjs';
import { ToastService } from '../services/toast.service';
import { AuthService } from '../services/auth.service';

// Drapeau global pour éviter plusieurs redirections/toasts sur 401 simultanés
let _redirecting401 = false;

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const injector = inject(Injector);
  const toast    = inject(ToastService);
  const token    = localStorage.getItem('gym_token');

  const authReq = token
    ? req.clone({
        headers: req.headers.set('Authorization', `Bearer ${token}`)
      })
    : req;

  return next(authReq).pipe(
    catchError((error: HttpErrorResponse) => {
      switch (error.status) {
        case 401:
          if (!_redirecting401) {
            _redirecting401 = true;
            toast.error('Session expirée', 'Veuillez vous reconnecter.');
            // Injection lazy pour éviter la dépendance circulaire HttpClient ↔ Intercepteur
            const auth = injector.get(AuthService, null);
            if (auth) {
              auth.clearLocalSession();
            }
            setTimeout(() => { _redirecting401 = false; }, 3000);
          }
          break;
        case 403:
          // Only show toast for write operations — silent fail for read-only data loading
          if (req.method !== 'GET') {
            toast.error('Accès refusé', 'Vous n\'avez pas les droits nécessaires.');
          } else {
            console.warn(`403 on ${req.url} — skipping toast`);
          }
          break;
        case 404:
          if (req.method !== 'GET') {
            toast.error('Introuvable', 'La ressource demandée n\'existe pas.');
          } else {
            console.warn(`404 on ${req.url}`);
          }
          break;
        case 500:
          toast.error('Erreur serveur', 'Une erreur interne s\'est produite.');
          break;
        case 0:
          // Silent on initial page load — only toast after first successful connection
          console.warn('Server unreachable:', req.url);
          break;
        default:
          if (req.method !== 'GET') {
            const msg = error.error?.message || 'Une erreur est survenue.';
            toast.error(`Erreur ${error.status}`, msg);
          } else {
            console.warn(`HTTP ${error.status} on ${req.url}`);
          }
      }
      return throwError(() => error);
    })
  );
};
