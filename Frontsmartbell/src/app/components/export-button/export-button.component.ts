import { Component, input, signal, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ExportService } from '../../services/export.service';
import { ToastService } from '../../services/toast.service';

export type ExportType = 'payments' | 'members';

@Component({
  selector: 'app-export-button',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './export-button.component.html',
  styleUrl: './export-button.component.css',
})
export class ExportButtonComponent {
  data  = input<any[]>([]);
  type  = input<ExportType>('payments');
  label = input<string>('');

  isPdfLoading   = signal(false);
  isExcelLoading = signal(false);

  private exportSvc = inject(ExportService);
  private toast     = inject(ToastService);

  exportPdf(): void {
    if (this.isPdfLoading()) return;
    const rows = this.data();
    if (!rows.length) {
      this.toast.error('Aucune donnée', 'Aucun enregistrement à exporter.');
      return;
    }
    this.isPdfLoading.set(true);
    setTimeout(() => {
      try {
        if (this.type() === 'payments') {
          this.exportSvc.exportPaymentsPDF(rows);
        } else {
          this.exportSvc.exportMembersPDF(rows);
        }
      } catch (err: any) {
        this.toast.error('Erreur export PDF', err?.message ?? 'Impossible de générer le PDF.');
      } finally {
        this.isPdfLoading.set(false);
      }
    }, 30);
  }

  exportExcel(): void {
    if (this.isExcelLoading()) return;
    const rows = this.data();
    if (!rows.length) {
      this.toast.error('Aucune donnée', 'Aucun enregistrement à exporter.');
      return;
    }
    this.isExcelLoading.set(true);
    setTimeout(() => {
      try {
        if (this.type() === 'payments') {
          this.exportSvc.exportPaymentsExcel(rows);
        } else {
          this.exportSvc.exportMembersExcel(rows);
        }
      } catch (err: any) {
        this.toast.error('Erreur export Excel', err?.message ?? 'Impossible de générer le fichier Excel.');
      } finally {
        this.isExcelLoading.set(false);
      }
    }, 30);
  }
}
