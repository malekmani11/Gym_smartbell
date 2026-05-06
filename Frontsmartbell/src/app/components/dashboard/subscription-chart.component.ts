import { Component, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';

export interface PlanSegment {
  id: string;
  name: string;
  members: number;
  monthlyRevenue: number;  // already normalized to monthly
  priceLabel: string;
  color: string;
  // computed after build()
  percentage: number;
  startAngle: number;
  endAngle: number;
  path: string;
  labelX: number;
  labelY: number;
}

const CX = 100;
const CY = 100;
const R  = 80;
const R_INNER = 44; // donut hole radius

@Component({
  selector: 'app-subscription-chart',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './subscription-chart.component.html',
})
export class SubscriptionChartComponent {

  hoveredId = signal<string | null>(null);

  // ── Raw plan data ─────────────────────────────────────────────────────
  private readonly rawPlans = [
    { id: 'monthly',   name: 'Mensuel',       members: 420, monthlyRevenue: 420 * 49,            priceLabel: '49DT/m',    color: '#D4AF37' },
    { id: 'quarterly', name: 'Trimestriel',   members: 310, monthlyRevenue: Math.round(310 * 43), priceLabel: '129DT/trim', color: '#3B82F6' },
    { id: 'annual',    name: 'Annuel',         members: 280, monthlyRevenue: Math.round(280 * 33), priceLabel: '399DT/an',  color: '#22C55E' },
    { id: 'crossfit',  name: 'CrossFit Elite', members: 238, monthlyRevenue: 238 * 89,            priceLabel: '89DT/m',    color: '#A855F7' },
  ];

  // ── Build segments with SVG paths ─────────────────────────────────────
  segments: PlanSegment[] = (() => {
    const total = this.rawPlans.reduce((s, p) => s + p.members, 0);
    let angle = -Math.PI / 2; // start at top
    return this.rawPlans.map(p => {
      const pct       = p.members / total;
      const sweep     = pct * 2 * Math.PI;
      const startAngle = angle;
      const endAngle   = angle + sweep;
      const midAngle   = startAngle + sweep / 2;
      const path       = this._arc(startAngle, endAngle);
      const labelR     = R * 0.72;
      const labelX     = CX + labelR * Math.cos(midAngle);
      const labelY     = CY + labelR * Math.sin(midAngle);
      angle = endAngle;
      return { ...p, percentage: Math.round(pct * 100), startAngle, endAngle, path, labelX, labelY };
    });
  })();

  // ── Summary KPIs ──────────────────────────────────────────────────────
  totalRevenue  = computed(() => this.segments.reduce((s, p) => s + p.monthlyRevenue, 0));
  totalMembers  = computed(() => this.segments.reduce((s, p) => s + p.members, 0));
  bestPlan      = computed(() => [...this.segments].sort((a, b) => b.monthlyRevenue - a.monthlyRevenue)[0]);
  growthRate    = '+12.4%';

  // ── Hover helpers ─────────────────────────────────────────────────────
  isHovered(id: string)  { return this.hoveredId() === id; }
  svgTransform(id: string) {
    return this.isHovered(id)
      ? `translate(${CX} ${CY}) scale(1.06) translate(${-CX} ${-CY})`
      : '';
  }

  tooltipX(seg: PlanSegment): number {
    const mid = (seg.startAngle + seg.endAngle) / 2;
    return CX + (R + 10) * Math.cos(mid);
  }
  tooltipY(seg: PlanSegment): number {
    const mid = (seg.startAngle + seg.endAngle) / 2;
    return CY + (R + 10) * Math.sin(mid);
  }

  // ── SVG arc path builder ──────────────────────────────────────────────
  private _arc(start: number, end: number): string {
    const x1 = (CX + R * Math.cos(start)).toFixed(3);
    const y1 = (CY + R * Math.sin(start)).toFixed(3);
    const x2 = (CX + R * Math.cos(end)).toFixed(3);
    const y2 = (CY + R * Math.sin(end)).toFixed(3);
    const xi1 = (CX + R_INNER * Math.cos(start)).toFixed(3);
    const yi1 = (CY + R_INNER * Math.sin(start)).toFixed(3);
    const xi2 = (CX + R_INNER * Math.cos(end)).toFixed(3);
    const yi2 = (CY + R_INNER * Math.sin(end)).toFixed(3);
    const large = end - start > Math.PI ? 1 : 0;
    // Donut path: outer arc CW → inner arc CCW
    return `M ${x1} ${y1} A ${R} ${R} 0 ${large} 1 ${x2} ${y2} L ${xi2} ${yi2} A ${R_INNER} ${R_INNER} 0 ${large} 0 ${xi1} ${yi1} Z`;
  }
}
