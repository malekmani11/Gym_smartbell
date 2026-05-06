import {
  Component,
  OnInit,
  OnDestroy,
  AfterViewInit,
  ElementRef,
  ViewChild,
  signal,
  computed,
  inject,
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { Chart, registerables } from 'chart.js';
import { environment } from '../../../environments/environment';

Chart.register(...registerables);

interface MonthPoint {
  label: string;  // ex: "avr. 25"
  revenue: number;
  count: number;
}

@Component({
  selector: 'app-monthly-revenue-chart',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './monthly-revenue-chart.component.html',
  styleUrl: './monthly-revenue-chart.component.css',
})
export class MonthlyRevenueChartComponent implements OnInit, AfterViewInit, OnDestroy {
  @ViewChild('chartCanvas') private canvasRef!: ElementRef<HTMLCanvasElement>;

  private http  = inject(HttpClient);
  private chart: Chart | null = null;
  private pendingData: MonthPoint[] | null = null;
  private viewReady = false;

  monthlyData = signal<MonthPoint[]>([]);
  isLoading   = signal(true);
  hasError    = signal(false);

  totalRevenue = computed(() =>
    this.monthlyData().reduce((s, m) => s + m.revenue, 0)
  );

  bestMonth = computed(() => {
    const data = this.monthlyData().filter(m => m.revenue > 0);
    if (!data.length) return null;
    return data.reduce((best, m) => (m.revenue > best.revenue ? m : best));
  });

  avgRevenue = computed(() => {
    const months = this.monthlyData().filter(m => m.revenue > 0);
    if (!months.length) return 0;
    return this.totalRevenue() / months.length;
  });

  growthLastMonth = computed(() => {
    const data = this.monthlyData();
    if (data.length < 2) return 0;
    const prev = data[data.length - 2].revenue;
    const curr = data[data.length - 1].revenue;
    if (!prev) return 0;
    return ((curr - prev) / prev) * 100;
  });

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  ngOnInit(): void {
    this.loadPayments();
  }

  ngAfterViewInit(): void {
    this.viewReady = true;
    if (this.pendingData) {
      this.buildChart(this.pendingData);
      this.pendingData = null;
    }
  }

  ngOnDestroy(): void {
    this.chart?.destroy();
  }

  // ── Data ────────────────────────────────────────────────────────────────────

  private loadPayments(): void {
    this.http
      .get<any>(`${environment.apiUrl}/payments`, {
        params: { size: '500', sort: 'paymentDate,desc' },
      })
      .subscribe({
        next: (res) => {
          const raw: any[] = res?.content ?? (Array.isArray(res) ? res : []);
          const data = this.buildMonthlyData(raw);
          this.monthlyData.set(data);
          this.isLoading.set(false);
          if (this.viewReady) {
            this.buildChart(data);
          } else {
            this.pendingData = data;
          }
        },
        error: () => {
          const empty = this.buildMonthlyData([]);
          this.monthlyData.set(empty);
          this.isLoading.set(false);
          if (this.viewReady) {
            this.buildChart(empty);
          } else {
            this.pendingData = empty;
          }
        },
      });
  }

  private buildMonthlyData(payments: any[]): MonthPoint[] {
    const now = new Date();
    // Initialize last 12 months (oldest → newest)
    const map = new Map<string, { label: string; revenue: number; count: number }>();

    for (let i = 11; i >= 0; i--) {
      const d   = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
      const lbl = d.toLocaleString('fr-FR', { month: 'short', year: '2-digit' });
      map.set(key, { label: lbl, revenue: 0, count: 0 });
    }

    for (const p of payments) {
      if (p.status !== 'COMPLETED' || !p.paymentDate) continue;
      const d   = new Date(p.paymentDate);
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
      const slot = map.get(key);
      if (slot) {
        slot.revenue += Number(p.amount ?? 0);
        slot.count   += 1;
      }
    }

    return Array.from(map.values()).map(v => ({
      label:   v.label,
      revenue: Math.round(v.revenue * 100) / 100,
      count:   v.count,
    }));
  }

  // ── Chart ───────────────────────────────────────────────────────────────────

  private buildChart(data: MonthPoint[]): void {
    if (!this.canvasRef) return;
    this.chart?.destroy();

    const ctx = this.canvasRef.nativeElement.getContext('2d')!;
    const values = data.map(d => d.revenue);
    const labels = data.map(d => d.label);

    // Bar gradient (top → bottom)
    const barGrad = ctx.createLinearGradient(0, 0, 0, 300);
    barGrad.addColorStop(0,   'rgba(212, 160, 23, 0.90)');
    barGrad.addColorStop(0.55,'rgba(212, 160, 23, 0.40)');
    barGrad.addColorStop(1,   'rgba(212, 160, 23, 0.04)');

    // Area gradient under line
    const areaGrad = ctx.createLinearGradient(0, 0, 0, 300);
    areaGrad.addColorStop(0,  'rgba(232, 180, 30, 0.18)');
    areaGrad.addColorStop(1,  'rgba(232, 180, 30, 0.00)');

    this.chart = new Chart(ctx, {
      data: {
        labels,
        datasets: [
          {
            type: 'bar',
            label: 'Revenus',
            data: values,
            backgroundColor: barGrad,
            borderColor: 'rgba(212, 160, 23, 0.85)',
            borderWidth: 1.5,
            borderRadius: 7,
            borderSkipped: false,
            order: 2,
          },
          {
            type: 'line',
            label: 'Tendance',
            data: values,
            borderColor: 'rgba(248, 210, 60, 0.85)',
            borderWidth: 2.5,
            pointBackgroundColor: '#D4A017',
            pointBorderColor: '#131108',
            pointBorderWidth: 2,
            pointRadius: 4,
            pointHoverRadius: 7,
            pointHoverBackgroundColor: '#F5D77A',
            fill: true,
            backgroundColor: areaGrad,
            tension: 0.42,
            order: 1,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { intersect: false, mode: 'index' },
        animation: { duration: 700, easing: 'easeInOutQuart' },
        plugins: {
          legend: {
            display: true,
            position: 'top',
            align: 'end',
            labels: {
              color: '#9CA3AF',
              font: { size: 11, family: "'Inter', sans-serif" },
              boxWidth: 10,
              boxHeight: 10,
              borderRadius: 3,
              padding: 14,
              usePointStyle: true,
              pointStyleWidth: 10,
            },
          },
          tooltip: {
            backgroundColor: '#1c1a10',
            titleColor: '#D4A017',
            bodyColor: '#D1D5DB',
            footerColor: '#6B7280',
            borderColor: 'rgba(212, 160, 23, 0.30)',
            borderWidth: 1,
            padding: 12,
            cornerRadius: 10,
            displayColors: false,
            callbacks: {
              title: (items) => items[0]?.label?.toUpperCase() ?? '',
              label: (item) => {
                if (item.datasetIndex === 0) {
                  return `  ${(item.parsed.y ?? 0).toLocaleString('fr-FR')} DT`;
                }
                return '';
              },
              footer: (items) => {
                const idx = items[0]?.dataIndex;
                if (idx !== undefined) {
                  const n = data[idx]?.count ?? 0;
                  return `  ${n} transaction${n > 1 ? 's' : ''}`;
                }
                return '';
              },
            },
          },
        },
        scales: {
          x: {
            grid: { display: false },
            ticks: {
              color: '#6B7280',
              font: { size: 10, family: "'Inter', sans-serif" },
              maxRotation: 0,
            },
            border: { color: 'rgba(255,255,255,0.05)' },
          },
          y: {
            grid: { color: 'rgba(255,255,255,0.04)', lineWidth: 1 },
            ticks: {
              color: '#6B7280',
              font: { size: 10, family: "'Inter', sans-serif" },
              callback: (v) => `${Number(v).toLocaleString('fr-FR')} DT`,
              maxTicksLimit: 6,
            },
            border: { display: false, dash: [4, 4] },
          },
        },
      },
    });
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  retry(): void {
    this.hasError.set(false);
    this.isLoading.set(true);
    this.loadPayments();
  }
}
