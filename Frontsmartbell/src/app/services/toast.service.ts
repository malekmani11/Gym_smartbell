import { Injectable, signal } from '@angular/core';

export type ToastType = 'success' | 'error' | 'warning' | 'info';

export interface Toast {
  id: string;
  type: ToastType;
  title: string;
  message?: string;
  duration: number;
}

@Injectable({ providedIn: 'root' })
export class ToastService {
  toasts = signal<Toast[]>([]);

  private add(type: ToastType, title: string, message?: string, duration = 4000) {
    const id = `toast-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
    const toast: Toast = { id, type, title, message, duration };
    this.toasts.update(list => [...list, toast]);
    setTimeout(() => this.dismiss(id), duration);
    return id;
  }

  success(title: string, message?: string, duration?: number) {
    return this.add('success', title, message, duration);
  }

  error(title: string, message?: string, duration?: number) {
    return this.add('error', title, message, duration ?? 6000);
  }

  warning(title: string, message?: string, duration?: number) {
    return this.add('warning', title, message, duration ?? 5000);
  }

  info(title: string, message?: string, duration?: number) {
    return this.add('info', title, message, duration);
  }

  dismiss(id: string) {
    this.toasts.update(list => list.filter(t => t.id !== id));
  }
}
