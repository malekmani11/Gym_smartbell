import { Component, input, signal, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ExportService } from '../../services/export.service';

export type ExportType = 'payments' | 'members';

@Component({
  selector: 'app-export-button',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './export-button.component.html',
  styleUrl: './export-button.component.css',
})
export class ExportButtonComponent {
  // ── Inputs (signal-based) ─────────────────────────────────────────────────
  data  = input<any[]>([]);
  type  = input<ExportType>('payments');
  label = input<string>('');

  // ── State ─────────────────────────────────────────────────────────────────
  isPdfLoading   = signal(false);
  isExcelLoading = signal(false);

  private exportSvc = inject(ExportService);

  // ── Actions ───────────────────────────────────────────────────────────────

  exportPdf(): void {
    if (this.isPdfLoading()) return;
    this.isPdfLoading.set(true);
    // Defer to next tick so the spinner renders before blocking work
    setTimeout(() => {
      try {
        if (this.type() === 'payments') {
          this.exportSvc.exportPaymentsPDF(this.data());
        } else {
          this.exportSvc.exportMembersPDF(this.data());
        }
      } finally {
        this.isPdfLoading.set(false);
      }
    }, 30);
  }

  exportExcel(): void {
    if (this.isExcelLoading()) return;
    this.isExcelLoading.set(true);
    setTimeout(() => {
      try {
        if (this.type() === 'payments') {
          this.exportSvc.exportPaymentsExcel(this.data());
        } else {
          this.exportSvc.exportMembersExcel(this.data());
        }
      } finally {
        this.isExcelLoading.set(false);
      }
    }, 30);
  }
}
