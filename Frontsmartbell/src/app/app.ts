import { Component, signal, inject, OnInit } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { Router, NavigationEnd } from '@angular/router';
import { filter } from 'rxjs/operators';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App implements OnInit {
  protected readonly title = signal('GymAdmin');

  private router = inject(Router);

  ngOnInit(): void {
    this.router.events
      .pipe(filter(e => e instanceof NavigationEnd))
      .subscribe(() => setTimeout(() => this.animateKpiCounters(), 500));
  }

  private animateKpiCounters(): void {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

    document.querySelectorAll<HTMLElement>('.kpi-value').forEach(el => {
      // Skip elements that have child element nodes (only animate pure text)
      if (el.children.length > 0) return;

      const raw = (el.textContent ?? '').trim();
      const match = raw.match(/^[\d\s,]+\.?\d*/);
      if (!match) return;

      const numStr  = match[0].replace(/[\s,]/g, '');
      const target  = parseFloat(numStr);
      if (isNaN(target) || target === 0) return;

      const suffix  = raw.slice(match[0].length);
      const t0      = performance.now();
      const dur     = 1400;

      const tick = (now: number) => {
        const p    = Math.min((now - t0) / dur, 1);
        const ease = 1 - Math.pow(1 - p, 3);
        const cur  = Math.floor(ease * target);
        el.textContent = cur.toLocaleString('fr-FR') + suffix;
        if (p < 1) requestAnimationFrame(tick);
        else el.textContent = raw;
      };
      requestAnimationFrame(tick);
    });
  }
}
