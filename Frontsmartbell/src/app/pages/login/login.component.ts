import { Component, signal, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { ToastService } from '../../services/toast.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
<div class="min-h-screen bg-[#0A0A0A] flex items-center justify-center p-4 relative overflow-hidden">

  <!-- Ambient glows -->
  <div class="absolute top-0 right-0 w-[600px] h-[600px] bg-[#D4AF37]/3 blur-[120px] rounded-full -translate-y-1/2 translate-x-1/3 pointer-events-none"></div>
  <div class="absolute bottom-0 left-0 w-[500px] h-[500px] bg-[#D4AF37]/3 blur-[100px] rounded-full translate-y-1/2 -translate-x-1/3 pointer-events-none"></div>

  <div class="w-full max-w-md relative z-10">

    <!-- Logo -->
    <div class="text-center mb-8">
      <div class="w-16 h-16 rounded-2xl bg-gradient-to-br from-[#D4AF37] to-[#A68523]
                  flex items-center justify-center mx-auto mb-5
                  shadow-[0_0_40px_rgba(212,175,55,0.35),0_8px_20px_rgba(0,0,0,0.5)]">
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none">
          <path d="M6 4h2v16H6V4zm10 0h2v16h-2V4zM3 10h18v4H3v-4z" fill="#0A0A0A"/>
        </svg>
      </div>
      <h1 class="text-3xl font-playfair font-bold text-white tracking-tight">
        Gym<span class="text-[#D4AF37]">Admin</span>
      </h1>
      <p class="text-gray-500 text-sm mt-1.5 font-inter">Tableau de bord Premium</p>
    </div>

    <!-- Card -->
    <div class="rounded-2xl p-8"
         style="background: linear-gradient(145deg, #141414 0%, #0f0f0f 100%);
                border: 1px solid rgba(255,255,255,0.07);
                box-shadow: 0 8px 40px rgba(0,0,0,0.6), 0 1px 0 rgba(255,255,255,0.04) inset;">
      <h2 class="text-xl font-playfair font-bold text-white mb-6 text-center tracking-wide">
        Connexion
      </h2>

      <div class="space-y-5">
        <div>
          <label for="login-email"
                 class="text-[11px] text-gray-500 uppercase font-bold tracking-widest block mb-2">
            Email
          </label>
          <input id="login-email"
                 type="email"
                 [(ngModel)]="email"
                 placeholder="admin@gympro.fr"
                 (keyup.enter)="login()"
                 class="w-full bg-[#0A0A0A] border border-white/8 rounded-xl px-4 py-3 text-white text-sm
                        focus:border-[#D4AF37]/60 focus:outline-none placeholder-gray-600 font-inter"
                 style="transition: border-color 0.2s ease, box-shadow 0.2s ease;"
                 onfocus="this.style.boxShadow='0 0 0 3px rgba(212,175,55,0.1)'"
                 onblur="this.style.boxShadow='none'">
        </div>
        <div>
          <label for="login-pwd"
                 class="text-[11px] text-gray-500 uppercase font-bold tracking-widest block mb-2">
            Mot de passe
          </label>
          <input id="login-pwd"
                 type="password"
                 [(ngModel)]="password"
                 placeholder="••••••••"
                 (keyup.enter)="login()"
                 class="w-full bg-[#0A0A0A] border border-white/8 rounded-xl px-4 py-3 text-white text-sm
                        focus:border-[#D4AF37]/60 focus:outline-none placeholder-gray-600 font-inter"
                 style="transition: border-color 0.2s ease, box-shadow 0.2s ease;"
                 onfocus="this.style.boxShadow='0 0 0 3px rgba(212,175,55,0.1)'"
                 onblur="this.style.boxShadow='none'">
        </div>
      </div>

      @if (errorMsg()) {
        <div class="mt-4 px-4 py-3 rounded-xl bg-red-500/10 border border-red-500/20 flex items-start gap-2.5">
          <i class="fas fa-exclamation-circle text-red-400 text-sm mt-0.5 flex-shrink-0"></i>
          <p class="text-xs text-red-400 font-inter leading-relaxed">{{ errorMsg() }}</p>
        </div>
      }

      <button (click)="login()"
              [disabled]="isLoading() || !email.trim() || !password.trim()"
              class="w-full mt-6 py-3.5 rounded-xl text-sm font-black font-montserrat
                     text-[#0A0A0A] cursor-pointer
                     disabled:opacity-45 disabled:cursor-not-allowed
                     flex items-center justify-center gap-2"
              style="background: linear-gradient(135deg, #C9A227 0%, #F5D77A 50%, #D4AF37 100%);
                     background-size: 200% 200%;
                     transition: box-shadow 0.25s ease, transform 0.2s ease;
                     box-shadow: 0 2px 10px rgba(212,175,55,0.3);"
              onmouseover="if(!this.disabled){this.style.boxShadow='0 4px 24px rgba(212,175,55,0.5)';this.style.transform='translateY(-1px)'}"
              onmouseout="this.style.boxShadow='0 2px 10px rgba(212,175,55,0.3)';this.style.transform='translateY(0)'">
        @if (isLoading()) {
          <i class="fas fa-spinner animate-spin"></i>
          <span>Connexion...</span>
        } @else {
          <i class="fas fa-sign-in-alt"></i>
          <span>Se connecter</span>
        }
      </button>
    </div>

  </div>
</div>
  `,
})
export class LoginComponent {
  private auth   = inject(AuthService);
  private router = inject(Router);
  private toast  = inject(ToastService);

  email    = '';
  password = '';
  isLoading = signal(false);
  errorMsg  = signal('');

  login() {
    if (!this.email.trim() || !this.password.trim()) return;
    this.isLoading.set(true);
    this.errorMsg.set('');

    this.auth.login({ email: this.email, password: this.password })
      .subscribe({
        next: () => {
          this.toast.success('Connexion réussie', 'Bienvenue sur GymAdmin !');
          this.router.navigate(['/dashboard']);
        },
        error: (err) => {
          console.error('Login error — status:', err.status, '| url:', err.url, '| detail:', err);
          this.isLoading.set(false);
          if (err.status === 0) {
            this.errorMsg.set(
              'Serveur inaccessible (status 0). Vérifiez que Spring Boot tourne sur http://localhost:8080'
            );
          } else if (err.status === 401) {
            this.errorMsg.set('Email ou mot de passe incorrect.');
          } else if (err.status === 404) {
            this.errorMsg.set(`Endpoint introuvable (404). URL: ${err.url}`);
          } else {
            this.errorMsg.set(`Erreur ${err.status}: ${err.message}`);
          }
        },
        complete: () => this.isLoading.set(false),
      });
  }
}
