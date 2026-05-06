import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ToastService, Toast } from '../../services/toast.service';

@Component({
  selector: 'app-toast',
  standalone: true,
  imports: [CommonModule],
  template: `
    <!-- Toast Container — fixed bottom-right, z-[9999] -->
    <div class="fixed bottom-6 right-6 z-[9999] flex flex-col gap-3 pointer-events-none"
         style="min-width:320px; max-width:400px;">

      @for (toast of toastSvc.toasts(); track toast.id) {
        <div class="pointer-events-auto flex items-start gap-3 px-4 py-3.5 rounded-xl border shadow-[0_8px_32px_rgba(0,0,0,0.6)]
                    backdrop-blur-md animate-slide-up transition-all duration-300"
             [class]="getBg(toast)">

          <!-- Icon -->
          <div class="flex-shrink-0 mt-0.5">
            <i [class]="getIcon(toast) + ' text-base'"></i>
          </div>

          <!-- Content -->
          <div class="flex-1 min-w-0">
            <p class="text-sm font-bold font-montserrat leading-snug" [class]="getTextColor(toast)">
              {{ toast.title }}
            </p>
            @if (toast.message) {
              <p class="text-xs text-gray-400 font-inter mt-0.5 leading-relaxed">{{ toast.message }}</p>
            }
          </div>

          <!-- Dismiss -->
          <button (click)="toastSvc.dismiss(toast.id)"
                  class="flex-shrink-0 text-gray-500 hover:text-white transition-colors mt-0.5">
            <i class="fas fa-times text-xs"></i>
          </button>
        </div>
      }

    </div>
  `,
})
export class ToastComponent {
  toastSvc = inject(ToastService);

  getBg(toast: Toast): string {
    const map: Record<string, string> = {
      success: 'bg-[#0D1F14] border-green-500/30',
      error:   'bg-[#1F0D0D] border-red-500/30',
      warning: 'bg-[#1F1A0D] border-yellow-500/30',
      info:    'bg-[#0D131F] border-blue-500/30',
    };
    return map[toast.type] ?? map['info'];
  }

  getIcon(toast: Toast): string {
    const map: Record<string, string> = {
      success: 'fas fa-check-circle text-green-400',
      error:   'fas fa-times-circle text-red-400',
      warning: 'fas fa-exclamation-triangle text-yellow-400',
      info:    'fas fa-info-circle text-blue-400',
    };
    return map[toast.type] ?? map['info'];
  }

  getTextColor(toast: Toast): string {
    const map: Record<string, string> = {
      success: 'text-green-300',
      error:   'text-red-300',
      warning: 'text-yellow-300',
      info:    'text-blue-300',
    };
    return map[toast.type] ?? 'text-white';
  }
}
