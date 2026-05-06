import { Component, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

export interface ShopCategory {
  id: string;
  label: string;
  icon: string;
  current: number;       // CA ce mois (DT)
  previous: number;      // CA mois précédent (DT)
  history: number[];     // 6 derniers mois (du plus ancien au plus récent)
}

interface SaleForm {
  categoryId: string;
  amount: number | null;
  member: string;
}

@Component({
  selector: 'app-shop-revenue',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './shop-revenue.component.html',
})
export class ShopRevenueComponent {

  showForm = signal(false);

  form = signal<SaleForm>({ categoryId: '', amount: null, member: '' });

  categories = signal<ShopCategory[]>([
    {
      id: 'supplements',
      label: 'Compléments alimentaires',
      icon: 'fas fa-capsules',
      current: 3200,
      previous: 2900,
      history: [2400, 2650, 2800, 3100, 2900, 3200],
    },
    {
      id: 'apparel',
      label: 'Tenues & accessoires',
      icon: 'fas fa-tshirt',
      current: 1850,
      previous: 2100,
      history: [1600, 1750, 2000, 2100, 2100, 1850],
    },
    {
      id: 'coaching',
      label: 'Coaching privé',
      icon: 'fas fa-user-tie',
      current: 4500,
      previous: 3800,
      history: [3000, 3200, 3500, 3800, 3800, 4500],
    },
    {
      id: 'nutrition',
      label: 'Bilans nutritionnels',
      icon: 'fas fa-apple-alt',
      current: 960,
      previous: 800,
      history: [600, 650, 750, 800, 800, 960],
    },
  ]);

  // ── Computed ─────────────────────────────────────────────────────────────
  totalRevenue = computed(() =>
    this.categories().reduce((sum, c) => sum + c.current, 0)
  );

  totalPrevious = computed(() =>
    this.categories().reduce((sum, c) => sum + c.previous, 0)
  );

  totalGrowth = computed(() => {
    const prev = this.totalPrevious();
    if (!prev) return 0;
    return ((this.totalRevenue() - prev) / prev) * 100;
  });

  /** Share of total gym CA (subscriptions ~84 500 + shop) */
  caSharePct = computed(() => {
    const total = 84500 + this.totalRevenue();
    return ((this.totalRevenue() / total) * 100).toFixed(1);
  });

  maxCurrent = computed(() =>
    Math.max(...this.categories().map(c => c.current))
  );

  // ── Helpers ───────────────────────────────────────────────────────────────
  growthPct(cat: ShopCategory): number {
    if (!cat.previous) return 0;
    return ((cat.current - cat.previous) / cat.previous) * 100;
  }

  barWidth(current: number): number {
    return Math.round((current / this.maxCurrent()) * 100);
  }

  /** SVG bar chart — 6 bars in a 120×40 viewBox */
  svgBars(history: number[]): { x: number; y: number; h: number }[] {
    const max   = Math.max(...history) || 1;
    const H     = 36;
    const barW  = 14;
    const gap   = 6;
    return history.map((v, i) => {
      const h = Math.round((v / max) * H);
      return { x: i * (barW + gap), y: H - h, h };
    });
  }

  svgViewBox = '0 0 120 40';

  // ── Form actions ──────────────────────────────────────────────────────────
  toggleForm() {
    this.showForm.update(v => !v);
    if (!this.showForm()) this.resetForm();
  }

  updateForm(patch: Partial<SaleForm>) {
    this.form.update(f => ({ ...f, ...patch }));
  }

  get formValid(): boolean {
    const f = this.form();
    return !!f.categoryId && !!f.amount && f.amount > 0;
  }

  submitSale() {
    if (!this.formValid) return;
    const { categoryId, amount } = this.form();

    this.categories.update(list =>
      list.map(c => {
        if (c.id !== categoryId) return c;
        const next = c.current + (amount as number);
        return {
          ...c,
          current: next,
          history: [...c.history.slice(1), next],  // glisse la fenêtre
        };
      })
    );

    this.resetForm();
    this.showForm.set(false);
  }

  private resetForm() {
    this.form.set({ categoryId: '', amount: null, member: '' });
  }
}
