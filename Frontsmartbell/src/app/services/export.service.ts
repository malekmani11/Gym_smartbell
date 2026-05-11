import { Injectable } from '@angular/core';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import * as XLSX from 'xlsx';

@Injectable({ providedIn: 'root' })
export class ExportService {

  // ── Filename helpers ──────────────────────────────────────────────────────

  private filename(prefix: string, ext: string): string {
    const d  = new Date();
    const ym = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
    return `SmartBell_${prefix}_${ym}.${ext}`;
  }

  private formatDate(v: string | Date | undefined | null): string {
    if (!v) return '—';
    try {
      return new Date(v).toLocaleDateString('fr-FR', {
        day: '2-digit', month: '2-digit', year: 'numeric',
      });
    } catch { return '—'; }
  }

  private methodLabel(m: string): string {
    return ({ CASH: 'Espèces', CARD: 'Carte', BANK_TRANSFER: 'Virement', ONLINE: 'En ligne' } as any)[
      m?.toUpperCase()
    ] ?? m ?? '—';
  }

  private statusLabel(s: string): string {
    return ({ COMPLETED: 'Complété', PENDING: 'En attente', FAILED: 'Échoué', REFUNDED: 'Remboursé' } as any)[
      s?.toUpperCase()
    ] ?? s ?? '—';
  }

  // ── Data normalizers ──────────────────────────────────────────────────────

  private normalizePayment(p: any): string[] {
    const member =
      p.memberName ??
      [p.subscription?.user?.firstName, p.subscription?.user?.lastName]
        .filter(Boolean).join(' ') ?? '—';
    const plan   = p.planName ?? p.plan?.name ?? p.subscription?.plan?.name ?? '—';
    const amount = `${Number(p.amount ?? 0).toFixed(2)} DT`;
    return [member, plan, amount, this.methodLabel(p.paymentMethod), this.statusLabel(p.status), this.formatDate(p.paymentDate)];
  }

  private normalizeMember(m: any): string[] {
    const name =
      m.memberName ??
      [m.firstName, m.lastName].filter(Boolean).join(' ') ??
      [m.user?.firstName, m.user?.lastName].filter(Boolean).join(' ') ?? '—';
    return [
      name,
      m.email ?? m.user?.email ?? '—',
      m.phone ?? m.user?.phone ?? '—',
      m.status ?? m.membershipStatus ?? '—',
      this.formatDate(m.joinDate ?? m.startDate),
    ];
  }

  // ── PDF shared ────────────────────────────────────────────────────────────

  private tableTheme() {
    return {
      theme: 'plain' as const,
      styles: {
        fillColor:   [30, 30, 30]  as [number, number, number],
        textColor:   [210, 210, 210] as [number, number, number],
        fontSize:    8.5,
        cellPadding: { top: 4, bottom: 4, left: 5, right: 5 },
        lineColor:   [55, 55, 55]  as [number, number, number],
        lineWidth:   0.15,
      },
      headStyles: {
        fillColor:  [239, 159, 39] as [number, number, number],
        textColor:  [17, 17, 17]   as [number, number, number],
        fontStyle:  'bold' as const,
        fontSize:   9,
        cellPadding: { top: 5, bottom: 5, left: 5, right: 5 },
      },
      alternateRowStyles: {
        fillColor: [42, 42, 42] as [number, number, number],
      },
      margin: { top: 14, left: 10, right: 10, bottom: 18 },
    };
  }

  /** Draws the full-page dark bg + branded header for one page. */
  private drawPage(
    doc: jsPDF,
    title: string,
    recordCount: number,
    pageNum: number,
  ): void {
    const W = doc.internal.pageSize.width;
    const H = doc.internal.pageSize.height;

    // ── Dark background ──
    doc.setFillColor(17, 17, 17);
    doc.rect(0, 0, W, H, 'F');

    // ── Amber top accent bar ──
    doc.setFillColor(239, 159, 39);
    doc.rect(0, 0, W, 1.8, 'F');

    // ── Header card ──
    doc.setFillColor(28, 28, 28);
    doc.rect(0, 1.8, W, pageNum === 1 ? 40 : 11, 'F');

    if (pageNum === 1) {
      // Logo
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(20);
      doc.setTextColor(239, 159, 39);
      doc.text('SmartBell', 14, 19);
      doc.setTextColor(255, 255, 255);
      doc.text('Gym', 63, 19);

      // Separator
      doc.setDrawColor(60, 60, 60);
      doc.setLineWidth(0.4);
      doc.line(88, 8, 88, 38);

      // Title + meta
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(12);
      doc.setTextColor(210, 210, 210);
      doc.text(title, 96, 18);

      doc.setFont('helvetica', 'normal');
      doc.setFontSize(8.5);
      doc.setTextColor(120, 120, 120);
      doc.text(
        `Exporté le ${new Date().toLocaleDateString('fr-FR', { day: '2-digit', month: 'long', year: 'numeric' })}`,
        96, 27,
      );
      doc.text(`${recordCount} enregistrement(s)`, 96, 34);
    } else {
      // Compact continuation header
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(8.5);
      doc.setTextColor(239, 159, 39);
      doc.text('SmartBell Gym', 14, 9);
      doc.setFont('helvetica', 'normal');
      doc.setTextColor(130, 130, 130);
      doc.text(`${title} — suite`, 52, 9);
    }
  }

  private drawTotalFooter(doc: jsPDF, finalY: number, text: string): void {
    const W = doc.internal.pageSize.width;
    doc.setFillColor(28, 28, 28);
    doc.rect(10, finalY + 8, W - 20, 14, 'F');
    doc.setFillColor(239, 159, 39);
    doc.rect(10, finalY + 8, 3, 14, 'F');
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(10);
    doc.setTextColor(239, 159, 39);
    doc.text(text, 18, finalY + 17);
  }

  // ── Public PDF ─────────────────────────────────────────────────────────────

  exportPaymentsPDF(payments: any[]): void {
    const doc   = new jsPDF({ orientation: 'landscape', unit: 'mm', format: 'a4' });
    const W     = doc.internal.pageSize.width;
    const H     = doc.internal.pageSize.height;
    const title = 'Rapport des Paiements';

    autoTable(doc, {
      ...this.tableTheme(),
      startY: 50,
      head: [['Membre', 'Plan', 'Montant (DT)', 'Méthode', 'Statut', 'Date']],
      body: payments.map(p => this.normalizePayment(p)),
      columnStyles: {
        0: { cellWidth: 44 },
        1: { cellWidth: 42 },
        2: { cellWidth: 30, halign: 'right' as const },
        3: { cellWidth: 28 },
        4: { cellWidth: 28 },
        5: { cellWidth: 32 },
      },
      willDrawPage: (data) => this.drawPage(doc, title, payments.length, data.pageNumber),
      didDrawPage: (data) => {
        doc.setFontSize(7.5);
        doc.setTextColor(75, 75, 75);
        doc.text(`SmartBell Gym · ${title} · Page ${data.pageNumber}`, W / 2, H - 7, { align: 'center' });
      },
    });

    const total  = payments
      .filter(p => (p.status ?? '').toUpperCase() === 'COMPLETED')
      .reduce((s, p) => s + Number(p.amount ?? 0), 0);
    const finalY = (doc as any).lastAutoTable?.finalY ?? 160;
    this.drawTotalFooter(doc, finalY, `Total paiements complétés : ${total.toFixed(2)} DT`);

    doc.save(this.filename('Paiements', 'pdf'));
  }

  exportMembersPDF(members: any[]): void {
    const doc   = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });
    const W     = doc.internal.pageSize.width;
    const H     = doc.internal.pageSize.height;
    const title = 'Liste des Membres';

    autoTable(doc, {
      ...this.tableTheme(),
      startY: 50,
      head: [['Nom', 'Email', 'Téléphone', 'Statut abonnement', 'Date inscription']],
      body: members.map(m => this.normalizeMember(m)),
      columnStyles: {
        0: { cellWidth: 38 },
        1: { cellWidth: 55 },
        2: { cellWidth: 28 },
        3: { cellWidth: 38 },
        4: { cellWidth: 28 },
      },
      willDrawPage: (data) => this.drawPage(doc, title, members.length, data.pageNumber),
      didDrawPage: (data) => {
        doc.setFontSize(7.5);
        doc.setTextColor(75, 75, 75);
        doc.text(`SmartBell Gym · ${title} · Page ${data.pageNumber}`, W / 2, H - 7, { align: 'center' });
      },
    });

    const finalY = (doc as any).lastAutoTable?.finalY ?? 150;
    this.drawTotalFooter(doc, finalY, `Total membres exportés : ${members.length}`);

    doc.save(this.filename('Membres', 'pdf'));
  }

  // ── Public Excel ───────────────────────────────────────────────────────────

  exportPaymentsExcel(payments: any[]): void {
    const headers = ['Membre', 'Plan', 'Montant (DT)', 'Méthode', 'Statut', 'Date'];
    const rows    = payments.map(p => this.normalizePayment(p));
    const total   = payments
      .filter(p => (p.status ?? '').toUpperCase() === 'COMPLETED')
      .reduce((s, p) => s + Number(p.amount ?? 0), 0);

    const data = [
      headers,
      ...rows,
      [],  // blank separator
      [`TOTAL (Complétés) : ${total.toFixed(2)} DT`, '', '', '', '', ''],
    ];

    const ws = XLSX.utils.aoa_to_sheet(data);
    ws['!cols'] = [
      { wch: 26 }, { wch: 24 }, { wch: 16 }, { wch: 16 }, { wch: 16 }, { wch: 18 },
    ];

    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Paiements SmartBell');
    XLSX.writeFile(wb, this.filename('Paiements', 'xlsx'));
  }

  exportMembersExcel(members: any[]): void {
    const headers = ['Nom', 'Email', 'Téléphone', 'Statut abonnement', 'Date inscription'];
    const rows    = members.map(m => this.normalizeMember(m));

    const data = [
      headers,
      ...rows,
      [],
      [`TOTAL : ${members.length} membre(s)`, '', '', '', ''],
    ];

    const ws = XLSX.utils.aoa_to_sheet(data);
    ws['!cols'] = [
      { wch: 26 }, { wch: 32 }, { wch: 18 }, { wch: 22 }, { wch: 18 },
    ];

    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Membres SmartBell');
    XLSX.writeFile(wb, this.filename('Membres', 'xlsx'));
  }

  exportPaymentsCSV(payments: any[]): void {
    const header = 'ID,Membre,Montant,Date,Méthode,Statut,Référence';
    const lines  = payments.map(p =>
      `${p.id},"${p.memberName ?? ''}",${p.amount},${this.formatDate(p.paymentDate)},${p.paymentMethod},${p.status},${p.transactionRef ?? ''}`
    );
    const csv  = [header, ...lines].join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url  = URL.createObjectURL(blob);
    const a    = document.createElement('a');
    a.href     = url;
    a.download = this.filename('Paiements', 'csv');
    a.click();
    URL.revokeObjectURL(url);
  }
}
