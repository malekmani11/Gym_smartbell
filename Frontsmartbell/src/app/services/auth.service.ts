import { Injectable, signal, computed, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Observable, tap, catchError, throwError, BehaviorSubject, filter, timer } from 'rxjs';
import { environment } from '../../environments/environment';
import {
  LoginRequest, RegisterRequest, AuthResponse, RefreshTokenRequest
} from '../models/api.models';

@Injectable({ providedIn: 'root' })
export class AuthService {

  private http   = inject(HttpClient);
  private router = inject(Router);
  private readonly API = environment.apiUrl;

  // ── State ──────────────────────────────────────
  private _token    = signal<string | null>(
    localStorage.getItem('gym_token')
  );
  private _user     = signal<AuthResponse | null>(
    this._loadUser()
  );
  private _refreshToken = signal<string | null>(
    localStorage.getItem('gym_refresh_token')
  );

  // Token refresh timer
  private refreshTimer$ = new BehaviorSubject<number>(0);
  private REFRESH_BUFFER = 5 * 60 * 1000; // 5 minutes before expiry

  // ── Public computed ───────────────────────────
  isAuthenticated = computed(() => !!this._token());
  currentUser     = computed(() => this._user());
  currentUserId   = computed(() => this._user()?.id ?? null);
  currentRole     = computed(() => this._user()?.role ?? null);
  isAdmin         = computed(() => this._user()?.role === 'ROLE_ADMIN');
  isCoach         = computed(() => this._user()?.role === 'ROLE_COACH');
  isMember        = computed(() => this._user()?.role === 'ROLE_MEMBER');
  token           = computed(() => this._token());

  constructor() {
    this.initAutoRefresh();
  }

  // ── Auth methods ──────────────────────────────
  login(req: LoginRequest): Observable<AuthResponse> {
    return this.http
      .post<AuthResponse>(`${this.API}/auth/login`, req)
      .pipe(
        tap(res => this._persist(res)),
        catchError(err => throwError(() => err))
      );
  }

  register(req: RegisterRequest): Observable<AuthResponse> {
    return this.http
      .post<AuthResponse>(`${this.API}/auth/register`, req)
      .pipe(
        tap(res => this._persist(res)),
        catchError(err => throwError(() => err))
      );
  }

  // Used by admin to create accounts without overwriting the current session
  createAccount(req: RegisterRequest): Observable<AuthResponse> {
    return this.http
      .post<AuthResponse>(`${this.API}/auth/register`, req)
      .pipe(catchError(err => throwError(() => err)));
  }

  /**
   * Rafraîchit le token JWT avant expiration
   */
  refreshToken(): Observable<AuthResponse> {
    const refreshToken = this._refreshToken();
    if (!refreshToken) {
      this.logout();
      return throwError(() => new Error('Aucun refresh token disponible'));
    }

    const request: RefreshTokenRequest = { refreshToken };

    return this.http
      .post<AuthResponse>(`${this.API}/auth/refresh`, request)
      .pipe(
        tap(res => {
          this._persist(res);
          console.log('Token rafraîchi avec succès');
        }),
        catchError(err => {
          console.error('Échec du refresh token:', err);
          this.logout();
          return throwError(() => err);
        })
      );
  }

  /**
   * Déconnexion avec révocation du refresh token
   */
  logout() {
    const refreshToken = this._refreshToken();
    if (refreshToken) {
      this.http.post(`${this.API}/auth/logout`, { refreshToken })
        .subscribe({ next: () => {}, error: () => {} });
    }
    this.clearLocalSession();
  }

  /** Vide la session localement sans appel HTTP — utilisé par l'intercepteur sur 401 */
  clearLocalSession() {
    localStorage.removeItem('gym_token');
    localStorage.removeItem('gym_refresh_token');
    localStorage.removeItem('gym_user');
    this._token.set(null);
    this._user.set(null);
    this._refreshToken.set(null);
    this.router.navigate(['/login']);
  }

  /**
   * Déconnexion de tous les appareils
   */
  logoutAll() {
    const userId = this._user()?.id;
    if (userId) {
      this.http.post(`${this.API}/auth/logout-all?userId=${userId}`, {})
        .subscribe({
          next: () => console.log('Tous les tokens révoqués'),
          error: () => {}
        });
    }
    this.logout();
  }

  // ── Private helpers ───────────────────────────
  private _persist(res: AuthResponse) {
    localStorage.setItem('gym_token', res.token);
    localStorage.setItem('gym_user', JSON.stringify(res));
    if (res.refreshToken) {
      localStorage.setItem('gym_refresh_token', res.refreshToken);
      this._refreshToken.set(res.refreshToken);
    }
    this._token.set(res.token);
    this._user.set(res);
  }

  private _loadUser(): AuthResponse | null {
    const raw = localStorage.getItem('gym_user');
    return raw ? JSON.parse(raw) : null;
  }

  /**
   * Initialise le rafraîchissement automatique du token
   */
  private initAutoRefresh() {
    const user = this._user();
    if (user && user.expiresIn) {
      this.scheduleRefresh(user.expiresIn);
    }
  }

  /**
   * Planifie le rafraîchissement du token avant expiration
   */
  private scheduleRefresh(expiresInSeconds: number) {
    // Annuler tout timer existant
    this.refreshTimer$.next(0);

    // Calculer le temps avant refresh (5 minutes avant expiration)
    const refreshTime = (expiresInSeconds - 300) * 1000; // en millisecondes

    if (refreshTime > 0) {
      // Programmer le refresh
      timer(refreshTime).subscribe(() => {
        console.log('Token expire bientôt, tentative de refresh...');
        this.refreshToken().subscribe({
          next: (res) => {
            this.scheduleRefresh(res.expiresIn || 86400);
          },
          error: () => {
            // Le logout sera appelé automatiquement en cas d'échec
          }
        });
      });
    }
  }
}
