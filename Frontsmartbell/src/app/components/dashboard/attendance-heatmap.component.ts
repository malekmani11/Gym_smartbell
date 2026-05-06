import { Component, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';

export interface HeatmapCell {
  day: number;   // 0-6
  hour: number;  // 7-18
  count: number;
}

@Component({
  selector: 'app-attendance-heatmap',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './attendance-heatmap.component.html',
})
export class AttendanceHeatmapComponent {

  readonly days  = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  readonly hours = [7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18];

  // ── Données réalistes 7j × 12h ─────────────────────────────────────────
  // Pics : 7h-8h (matin) et 17h-18h (soir) — creux : 10h-14h
  // Samedi/Dimanche plus chargés en matinée, moins le soir
  private readonly rawData: number[][] = [
    // Lun
    [22, 18,  8,  5,  4,  6,  5,  4,  7, 12, 19, 26],
    // Mar
    [20, 15,  7,  4,  3,  5,  4,  3,  6, 11, 17, 24],
    // Mer
    [24, 20,  9,  5,  4,  7,  6,  5,  8, 13, 21, 28],
    // Jeu
    [21, 16,  8,  4,  3,  6,  5,  4,  7, 12, 18, 25],
    // Ven
    [19, 14,  7,  4,  3,  5,  4,  3,  6, 10, 16, 22],
    // Sam
    [28, 25, 18, 12,  9,  8,  7,  6,  8, 11, 14, 16],
    // Dim
    [15, 12,  9,  7,  5,  4,  4,  3,  5,  8, 10, 12],
  ];

  cells = signal<HeatmapCell[]>(
    this.rawData.flatMap((dayCounts, d) =>
      dayCounts.map((count, h) => ({ day: d, hour: this.hours[h], count }))
    )
  );

  // ── Stats calculées ────────────────────────────────────────────────────
  peakHour = computed(() => {
    const totals = this.hours.map((h, hi) => ({
      hour: h,
      total: this.rawData.reduce((sum, day) => sum + day[hi], 0),
    }));
    const peak = totals.reduce((a, b) => (a.total > b.total ? a : b));
    return `${peak.hour}h – ${peak.hour + 1}h`;
  });

  busiestDay = computed(() => {
    const totals = this.days.map((label, di) => ({
      label,
      total: this.rawData[di].reduce((a, b) => a + b, 0),
    }));
    return totals.reduce((a, b) => (a.total > b.total ? a : b)).label;
  });

  // ── Helpers ────────────────────────────────────────────────────────────
  getCell(day: number, hour: number): HeatmapCell {
    return this.cells().find(c => c.day === day && c.hour === hour)!;
  }

  getCellColor(count: number): string {
    if (count >= 21) return 'bg-[#D4AF37]';
    if (count >= 11) return 'bg-[#D4AF37]/50';
    if (count >= 6)  return 'bg-[#D4AF37]/20';
    return 'bg-white/5';
  }

  getCellBorder(count: number): string {
    if (count >= 21) return 'border-[#D4AF37]/60';
    if (count >= 11) return 'border-[#D4AF37]/30';
    if (count >= 6)  return 'border-[#D4AF37]/15';
    return 'border-white/5';
  }
}
