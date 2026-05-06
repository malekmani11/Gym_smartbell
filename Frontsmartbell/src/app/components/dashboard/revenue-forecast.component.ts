import { Component, signal, computed, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-revenue-forecast',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './revenue-forecast.component.html',
})
export class RevenueForecastComponent implements OnInit, OnDestroy {

  // ── Inputs (adjustable) ───────────────────────────────────────────────
  retentionRate  = signal(94.2);   // % — driven by slider
  activeMembers  = signal(1180);
  avgMonthlyRate = signal(71);     // DT — average across all plans
  currentRevenue = signal(84500);  // DT — actual this month
  revenueTarget  = signal(92000);  // DT — monthly objective

  /** New-member average over last 3 months (mock) */
  private readonly newMembersAvg = 56;

  // ── Core computed forecasts ───────────────────────────────────────────
  certain = computed(() =>
    Math.round(this.activeMembers() * this.avgMonthlyRate() * 0.4)
  );

  renewals = computed(() =>
    Math.round((this.retentionRate() / 100) * this.activeMembers() * this.avgMonthlyRate() * 0.55)
  );

  newRevenue = computed(() =>
    Math.round(this.newMembersAvg * this.avgMonthlyRate())
  );

  totalForecast = computed(() =>
    this.certain() + this.renewals() + this.newRevenue()
  );

  gapAmount = computed(() =>
    this.totalForecast() - this.currentRevenue()
  );

  gapPercent = computed(() =>
    ((this.gapAmount() / this.currentRevenue()) * 100).toFixed(1)
  );

  isOnTarget = computed(() =>
    this.totalForecast() >= this.revenueTarget()
  );

  gapToTarget = computed(() =>
    this.revenueTarget() - this.totalForecast()
  );

  // ── Bar widths for decomposition ─────────────────────────────────────
  certainPct = computed(() =>
    Math.round((this.certain() / this.totalForecast()) * 100)
  );
  renewalsPct = computed(() =>
    Math.round((this.renewals() / this.totalForecast()) * 100)
  );
  newPct = computed(() =>
    100 - this.certainPct() - this.renewalsPct()
  );

  // ── Count-up animation ────────────────────────────────────────────────
  displayedTotal = signal(0);
  private _countInterval: ReturnType<typeof setInterval> | null = null;

  ngOnInit() {
    const target   = this.totalForecast();
    const duration = 1200; // ms
    const steps    = 40;
    const increment = Math.ceil(target / steps);
    let current = 0;

    this._countInterval = setInterval(() => {
      current += increment;
      if (current >= target) {
        this.displayedTotal.set(target);
        clearInterval(this._countInterval!);
        this._countInterval = null;
      } else {
        this.displayedTotal.set(current);
      }
    }, duration / steps);
  }

  ngOnDestroy() {
    if (this._countInterval) clearInterval(this._countInterval);
  }

  // ── Slider helper ─────────────────────────────────────────────────────
  onRetentionChange(event: Event) {
    const val = parseFloat((event.target as HTMLInputElement).value);
    this.retentionRate.set(val);
  }
}
