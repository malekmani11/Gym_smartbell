import { Component, signal, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { ToastService } from '../../services/toast.service';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
<div class="min-h-screen bg-[#0A0A0A] flex items-center justify-center p-4">
  <div class="w-full max-w-md">

    <!-- Logo -->
    <div class="text-center mb-8">
      <div class="w-16 h-16 rounded-2xl bg-gradient-to-br from-[#D4AF37]
                  to-[#A68523] flex items-center justify-center mx-auto mb-4
                  shadow-[0_0_32px_rgba(212,175,55,0.3)]">
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none">
          <path d="M6 4h2v16H6V4zm10 0h2v16h-2V4zM3 10h18v4H3v-4z" fill="#0A0A0A"/>
        </svg>
      </div>
      <h1 class="text-3xl font-playfair font-bold text-white">
        Gym<span class="text-[#D4AF37]">Admin</span>
      </h1>
      <p class="text-gray-500 text-sm mt-1 font-inter">Créer un compte</p>
    </div>

    <!-- Card -->
    <div class="bg-[#111] border border-white/5 rounded-2xl p-8">
      <h2 class="text-xl font-playfair font-bold text-white mb-6 text-center">
        Inscription
      </h2>

      <div class="space-y-4">
        <!-- Prénom + Nom -->
        <div class="grid grid-cols-2 gap-3">
          <div>
            <label class="text-[10px] text-gray-500 uppercase font-bold tracking-widest block mb-1.5">Prénom</label>
            <input type="text"
                   [(ngModel)]="firstName"
                   placeholder="Jean"
                   class="w-full bg-[#0A0A0A] border border-white/10 rounded-xl px-4 py-3
                          text-white text-sm focus:border-[#D4AF37] focus:outline-none
                          transition-colors placeholder-gray-600 font-inter">
          </div>
          <div>
            <label class="text-[10px] text-gray-500 uppercase font-bold tracking-widest block mb-1.5">Nom</label>
            <input type="text"
                   [(ngModel)]="lastName"
                   placeholder="Dupont"
                   class="w-full bg-[#0A0A0A] border border-white/10 rounded-xl px-4 py-3
                          text-white text-sm focus:border-[#D4AF37] focus:outline-none
                          transition-colors placeholder-gray-600 font-inter">
          </div>
        </div>

        <!-- Email -->
        <div>
          <label class="text-[10px] text-gray-500 uppercase font-bold tracking-widest block mb-1.5">Email</label>
          <input type="email"
                 [(ngModel)]="email"
                 placeholder="admin@gympro.fr"
                 class="w-full bg-[#0A0A0A] border border-white/10 rounded-xl px-4 py-3
                        text-white text-sm focus:border-[#D4AF37] focus:outline-none
                        transition-colors placeholder-gray-600 font-inter">
        </div>

        <!-- Téléphone -->
        <div>
          <label class="text-[10px] text-gray-500 uppercase font-bold tracking-widest block mb-1.5">Téléphone <span class="text-gray-600">(optionnel)</span></label>
          <input type="tel"
                 [(ngModel)]="phone"
                 placeholder="+216 XX XXX XXX"
                 class="w-full bg-[#0A0A0A] border border-white/10 rounded-xl px-4 py-3
                        text-white text-sm focus:border-[#D4AF37] focus:outline-none
                        transition-colors placeholder-gray-600 font-inter">
        </div>

        <!-- Rôle -->
        <div>
          <label class="text-[10px] text-gray-500 uppercase font-bold tracking-widest block mb-1.5">Rôle</label>
          <select [(ngModel)]="role"
                  class="w-full bg-[#0A0A0A] border border-white/10 rounded-xl px-4 py-3
                         text-white text-sm focus:border-[#D4AF37] focus:outline-none
                         transition-colors font-inter">
            <option value="ROLE_ADMIN">Administrateur</option>
          </select>
        </div>

        <!-- Mot de passe -->
        <div>
          <label class="text-[10px] text-gray-500 uppercase font-bold tracking-widest block mb-1.5">Mot de passe</label>
          <input type="password"
                 [(ngModel)]="password"
                 placeholder="••••••••"
                 class="w-full bg-[#0A0A0A] border border-white/10 rounded-xl px-4 py-3
                        text-white text-sm focus:border-[#D4AF37] focus:outline-none
                        transition-colors placeholder-gray-600 font-inter">
        </div>

        <!-- Confirmer mot de passe -->
        <div>
          <label class="text-[10px] text-gray-500 uppercase font-bold tracking-widest block mb-1.5">Confirmer le mot de passe</label>
          <input type="password"
                 [(ngModel)]="confirmPassword"
                 placeholder="••••••••"
                 (keyup.enter)="register()"
                 class="w-full bg-[#0A0A0A] border border-white/10 rounded-xl px-4 py-3
                        text-white text-sm focus:border-[#D4AF37] focus:outline-none
                        transition-colors placeholder-gray-600 font-inter">
        </div>
      </div>

      @if (errorMsg()) {
        <div class="mt-4 px-4 py-3 rounded-xl bg-red-500/10 border border-red-500/20">
          <p class="text-xs text-red-400 font-inter">{{ errorMsg() }}</p>
        </div>
      }

      <button (click)="register()"
              [disabled]="isLoading() || !isFormValid()"
              class="w-full mt-6 py-3.5 rounded-xl text-sm font-black font-montserrat
                     bg-gradient-to-r from-[#D4AF37] to-[#F5D77A] text-[#0A0A0A]
                     transition-all hover:shadow-[0_0_24px_rgba(212,175,55,0.4)]
                     disabled:opacity-50 disabled:cursor-not-allowed
                     flex items-center justify-center gap-2">
        @if (isLoading()) {
          <i class="fas fa-spinner animate-spin"></i>
          <span>Création...</span>
        } @else {
          <i class="fas fa-user-plus"></i>
          <span>Créer le compte</span>
        }
      </button>
    </div>

    <p class="text-center text-gray-600 text-xs mt-6 font-inter">
      Déjà un compte ?
      <a routerLink="/login" class="text-[#D4AF37] hover:underline ml-1">Se connecter</a>
    </p>
  </div>
</div>
  `,
})
export class RegisterComponent {
  private auth   = inject(AuthService);
  private router = inject(Router);
  private toast  = inject(ToastService);

  firstName       = '';
  lastName        = '';
  email           = '';
  phone           = '';
  role            = 'ROLE_ADMIN';
  password        = '';
  confirmPassword = '';

  isLoading = signal(false);
  errorMsg  = signal('');

  isFormValid() {
    return this.firstName.trim() &&
           this.lastName.trim() &&
           this.email.trim() &&
           this.password.trim() &&
           this.confirmPassword.trim();
  }

  register() {
    this.errorMsg.set('');

    if (!this.isFormValid()) return;

    if (this.password !== this.confirmPassword) {
      this.errorMsg.set('Les mots de passe ne correspondent pas.');
      return;
    }

    if (this.password.length < 6) {
      this.errorMsg.set('Le mot de passe doit contenir au moins 6 caractères.');
      return;
    }

    this.isLoading.set(true);

    this.auth.register({
      firstName: this.firstName.trim(),
      lastName:  this.lastName.trim(),
      email:     this.email.trim(),
      password:  this.password,
      phone:     this.phone.trim() || undefined,
      roleName:  this.role,
    }).subscribe({
      next: () => {
        this.toast.success('Compte créé', `Bienvenue ${this.firstName} !`);
        this.router.navigate(['/dashboard']);
      },
      error: (err) => {
        this.isLoading.set(false);
        if (err.status === 0) {
          this.errorMsg.set('Serveur inaccessible. Vérifiez que Spring Boot tourne.');
        } else if (err.status === 400) {
          this.errorMsg.set(err.error?.message || 'Données invalides.');
        } else if (err.status === 409 || err.error?.message?.includes('already exists')) {
          this.errorMsg.set('Cet email est déjà utilisé.');
        } else {
          this.errorMsg.set(`Erreur ${err.status}: ${err.message}`);
        }
      },
      complete: () => this.isLoading.set(false),
    });
  }
}
