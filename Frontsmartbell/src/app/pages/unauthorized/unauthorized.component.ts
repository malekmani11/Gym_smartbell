import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-unauthorized',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <div class="min-h-screen flex items-center justify-center bg-gray-100 dark:bg-gray-900 px-4">
      <div class="max-w-md w-full text-center">
        <div class="mb-6">
          <i class="fas fa-exclamation-triangle text-6xl text-yellow-500"></i>
        </div>
        <h1 class="text-3xl font-bold text-gray-900 dark:text-white mb-2">Accès Refusé</h1>
        <p class="text-gray-600 dark:text-gray-400 mb-8">
          Désolé, vous n'avez pas les permissions nécessaires pour accéder à cette page. 
          Seuls les administrateurs et managers sont autorisés ici.
        </p>
        <a routerLink="/login" class="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors">
          Retour à la connexion
        </a>
      </div>
    </div>
  `
})
export class UnauthorizedComponent {}
