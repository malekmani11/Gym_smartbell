import { Component, signal, computed, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ToastService } from '../../services/toast.service';
import { SalleApiService, Salle, SalleStatus } from '../../services/salle-api.service';

const EMPTY_SALLE = (): Salle => ({
  name: '', capacity: 20, currentOccupancy: 0, status: 'DISPONIBLE', location: '', description: '',
});

@Component({
  selector: 'app-salles',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './salles.component.html',
  styleUrl: './salles.component.css',
})
export class SallesComponent implements OnInit {
  private salleApi = inject(SalleApiService);
  private toast    = inject(ToastService);

  salles        = signal<Salle[]>([]);
  statusFilter  = signal<SalleStatus | ''>('');
  isLoading     = signal(false);
  showModal     = signal(false);
  editingSalle  = signal<Salle | null>(null);
  isProcessing  = signal(false);
  form          = signal<Salle>(EMPTY_SALLE());

  readonly statuses: SalleStatus[] = ['DISPONIBLE', 'OCCUPEE', 'MAINTENANCE'];

  filtered = computed(() => {
    const sf = this.statusFilter();
    return sf ? this.salles().filter(s => s.status === sf) : this.salles();
  });

  totalCapacity    = computed(() => this.salles().reduce((s, r) => s + r.capacity, 0));
  totalOccupied    = computed(() => this.salles().reduce((s, r) => s + r.currentOccupancy, 0));
  disponibleCount  = computed(() => this.salles().filter(s => s.status === 'DISPONIBLE').length);
  maintenanceCount = computed(() => this.salles().filter(s => s.status === 'MAINTENANCE').length);

  globalFillRate = computed(() => {
    const cap = this.totalCapacity();
    return cap ? Math.round((this.totalOccupied() / cap) * 100) : 0;
  });

  ngOnInit() {
    this.load();
  }

  load() {
    this.isLoading.set(true);
    this.salleApi.getAll().subscribe({
      next: (list) => { 
        this.salles.set(list); 
        this.isLoading.set(false); 
      },
      error: () => {
        this.toast.error('Erreur', 'Impossible de charger les salles.');
        this.isLoading.set(false);
      }
    });
  }

  openAdd() {
    this.editingSalle.set(null);
    this.form.set(EMPTY_SALLE());
    this.showModal.set(true);
  }

  openEdit(salle: Salle) {
    this.editingSalle.set(salle);
    this.form.set({ ...salle });
    this.showModal.set(true);
  }

  closeModal() { this.showModal.set(false); }

  save() {
    const f = this.form();
    if (!f.name.trim()) { this.toast.error('Champ requis', 'Le nom est obligatoire.'); return; }
    this.isProcessing.set(true);

    const editing = this.editingSalle();
    const req = editing?.id
      ? this.salleApi.update(editing.id, f)
      : this.salleApi.create(f);

    req.subscribe({
      next: (saved) => {
        if (editing?.id) {
          this.salles.update(list => list.map(s => s.id === editing.id ? saved : s));
          this.toast.success('Salle mise à jour', saved.name);
        } else {
          this.salles.update(list => [saved, ...list]);
          this.toast.success('Salle créée', saved.name);
        }
        this.isProcessing.set(false);
        this.showModal.set(false);
      },
      error: (err) => {
        this.toast.error('Erreur', err.error?.message || 'Une erreur est survenue lors de l\'enregistrement.');
        this.isProcessing.set(false);
      },
    });
  }

  delete(salle: Salle) {
    if (!salle.id) return;
    if (!confirm(`Supprimer la salle ${salle.name} ?`)) return;

    this.salleApi.delete(salle.id).subscribe({
      next: () => {
        this.salles.update(list => list.filter(s => s.id !== salle.id));
        this.toast.success('Supprimée', salle.name);
      },
      error: () => {
        this.toast.error('Erreur', 'Impossible de supprimer la salle.');
      },
    });
  }

  statusBadge(status: SalleStatus): string {
    switch (status) {
      case 'DISPONIBLE':  return 'bg-green-500/15 text-green-400 border border-green-500/30';
      case 'OCCUPEE':     return 'bg-[#D4A017]/12 text-[#D4A017] border border-[#D4A017]/30';
      case 'MAINTENANCE': return 'bg-red-500/15 text-red-400 border border-red-500/30';
    }
  }

  statusLabel(status: SalleStatus): string {
    return status === 'OCCUPEE' ? 'OCCUPÉE' : status;
  }

  fillColor(salle: Salle): string {
    const pct = salle.capacity ? (salle.currentOccupancy / salle.capacity) * 100 : 0;
    if (pct >= 85) return 'bg-red-500';
    if (pct >= 60) return 'bg-[#D4A017]';
    return 'bg-green-500';
  }

  fillPct(salle: Salle): number {
    return salle.capacity ? Math.round(Math.min(100, (salle.currentOccupancy / salle.capacity) * 100)) : 0;
  }

  updateForm(patch: Partial<Salle>) {
    this.form.update(f => ({ ...f, ...patch }));
  }
}
