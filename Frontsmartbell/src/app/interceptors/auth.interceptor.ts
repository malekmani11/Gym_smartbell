import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, throwError } from 'rxjs';
import { Router } from '@angular/router';
import { ToastService } from '../services/toast.service';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const router = inject(Router);
  const toast  = inject(ToastService);
  const token  = localStorage.getItem('gym_token');

  const authReq = token
    ? req.clone({
        headers: req.headers.set('Authorization', `Bearer ${token}`)
      })
    : req;

  return next(authReq).pipe(
    catchError((error: HttpErrorResponse) => {
      switch (error.status) {
        case 401:
          localStorage.removeItem('gym_token');
          localStorage.removeItem('gym_user');
          router.navigate(['/login']);
          toast.error('Session expirée', 'Veuillez vous reconnecter.');
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
