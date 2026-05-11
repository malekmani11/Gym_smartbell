import { Component, OnInit, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ComplaintApiService } from '../../services/complaint-api.service';
import { ComplaintDTO, ComplaintStatus } from '../../models/api.models';
import { ToastService } from '../../services/toast.service';

@Component({
  selector: 'app-complaints',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './complaints.component.html',
  styleUrl: './complaints.component.css'
})
export class ComplaintsComponent implements OnInit {
  private complaintApi = inject(ComplaintApiService);
  private toast        = inject(ToastService);

  complaints = signal<ComplaintDTO[]>([]);
  loading    = signal(true);

  filterStatus = signal<string>('ALL');
  searchTerm   = signal<string>('');

  showResponseModal = signal(false);
  showDetailModal   = signal(false);
  selectedComplaint = signal<ComplaintDTO | null>(null);

  adminResponse = signal('');
  newStatus     = signal<ComplaintStatus>('IN_PROGRESS');

  filteredComplaints = computed(() => {
    let list = this.complaints();
    if (this.filterStatus() !== 'ALL')
      list = list.filter(c => c.status === this.filterStatus());
    if (this.searchTerm()) {
      const term = this.searchTerm().toLowerCase();
      list = list.filter(c =>
        c.subject.toLowerCase().includes(term) ||
        `${c.firstName} ${c.lastName}`.toLowerCase().includes(term)
      );
    }
    return list;
  });

  stats = computed(() => {
    const all = this.complaints();
    return {
      open:       all.filter(c => c.status === 'OPEN').length,
      inProgress: all.filter(c => c.status === 'IN_PROGRESS').length,
      resolved:   all.filter(c => c.status === 'RESOLVED').length,
      closed:     all.filter(c => c.status === 'CLOSED').length,
    };
  });

  ngOnInit() { this.loadComplaints(); }

  loadComplaints() {
    this.loading.set(true);
    this.complaintApi.getAll().subscribe({
      next: (data) => { this.complaints.set(data); this.loading.set(false); },
      error: () => { this.toast.error('Erreur', 'Impossible de charger les plaintes'); this.loading.set(false); }
    });
  }

  markAsRead(complaint: ComplaintDTO) {
    if (complaint.status !== 'OPEN') return;
    this.complaintApi.markAsRead(complaint.id).subscribe({
      next: (updated) => {
        this.complaints.update(list => list.map(c => c.id === updated.id ? updated : c));
        this.toast.success('Marquée en cours', `Plainte #${complaint.id} prise en charge`);
      },
      error: () => this.toast.error('Erreur', 'Impossible de marquer la plainte')
    });
  }

  openResponseModal(complaint: ComplaintDTO) {
    this.selectedComplaint.set(complaint);
    this.adminResponse.set(complaint.response || '');
    this.newStatus.set(complaint.status === 'OPEN' ? 'IN_PROGRESS' : complaint.status);
    this.showResponseModal.set(true);
  }

  openDetailModal(complaint: ComplaintDTO) {
    this.selectedComplaint.set(complaint);
    this.showDetailModal.set(true);
  }

  closeModals() {
    this.showResponseModal.set(false);
    this.showDetailModal.set(false);
    this.selectedComplaint.set(null);
  }

  submitResponse() {
    const complaint = this.selectedComplaint();
    if (!complaint || !this.adminResponse().trim()) {
      this.toast.warning('Champ requis', 'La réponse ne peut pas être vide');
      return;
    }
    this.complaintApi.respond(complaint.id, this.adminResponse(), this.newStatus()).subscribe({
      next: (updated) => {
        this.complaints.update(list => list.map(c => c.id === updated.id ? updated : c));
        this.toast.success('Réponse envoyée', `Plainte #${complaint.id} mise à jour`);
        this.closeModals();
      },
      error: () => this.toast.error('Erreur', 'Impossible d\'envoyer la réponse')
    });
  }

  openNewComplaint() {
    this.toast.info('Info', 'Les plaintes sont soumises par les membres via l\'application mobile');
  }

  getStatusColor(status: ComplaintStatus): string {
    return ({ OPEN: '#E24B4A', IN_PROGRESS: '#534AB7', RESOLVED: '#1D9E75', CLOSED: '#888888' })[status] ?? '#888888';
  }

  getStatusLabel(status: ComplaintStatus): string {
    return ({ OPEN: 'Ouvert', IN_PROGRESS: 'En cours', RESOLVED: 'Résolu', CLOSED: 'Fermé' })[status] ?? status;
  }

  getAvatarClass(status: ComplaintStatus): string {
    const map: Record<string, string> = {
      OPEN: 'cpl-avatar--open', IN_PROGRESS: 'cpl-avatar--ongoing',
      RESOLVED: 'cpl-avatar--resolved', CLOSED: 'cpl-avatar--closed'
    };
    return 'cpl-avatar ' + (map[status] ?? 'cpl-avatar--closed');
  }

  getBadgeClass(status: ComplaintStatus): string {
    const map: Record<string, string> = {
      OPEN: 'cpl-badge cpl-badge--open', IN_PROGRESS: 'cpl-badge cpl-badge--ongoing',
      RESOLVED: 'cpl-badge cpl-badge--resolved', CLOSED: 'cpl-badge cpl-badge--closed'
    };
    return map[status] ?? 'cpl-badge cpl-badge--closed';
  }

  getInitials(firstName: string, lastName: string): string {
    return ((firstName?.[0] ?? '') + (lastName?.[0] ?? '')).toUpperCase() || '?';
  }
}
