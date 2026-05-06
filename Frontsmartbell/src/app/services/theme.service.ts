import { Injectable, signal, effect } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class ThemeService {
  isDark = signal<boolean>(this._readPreference());

  constructor() {
    effect(() => {
      const theme = this.isDark() ? 'dark' : 'light';
      this._applyTheme(theme);
      localStorage.setItem('smartbell-theme', theme);
    });
  }

  toggle() {
    this.isDark.update(dark => !dark);
  }

  private _readPreference(): boolean {
    const saved = localStorage.getItem('smartbell-theme');
    if (saved !== null) return saved === 'dark';
    return window.matchMedia('(prefers-color-scheme: dark)').matches;
  }

  private _applyTheme(theme: 'dark' | 'light') {
    document.body.classList.toggle('light', theme === 'light');
    document.body.classList.toggle('dark',  theme === 'dark');
  }
}
