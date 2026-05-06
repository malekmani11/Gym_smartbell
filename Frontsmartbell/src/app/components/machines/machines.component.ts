import { Component, signal, computed, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ToastService } from '../../services/toast.service';
import { MachineApiService, Machine, MachineStatus } from '../../services/machine-api.service';

const EMPTY = (): Machine => ({
  name: '', description: '', location: '', status: 'AVAILABLE', imageUrl: '', tutorialUrl: '',
});

@Component({
  selector: 'app-machines',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './machines.component.html',
  styleUrl: './machines.component.css',
})
export class MachinesComponent implements OnInit {
  private machineApi = inject(MachineApiService);
  private toast = inject(ToastService);

  machines       = signal<Machine[]>([]);
  searchQuery    = signal('');
  statusFilter   = signal<MachineStatus | ''>('');
  locationFilter = signal('');
  isLoading      = signal(false);

  showFormModal  = signal(false);
  editingMachine = signal<Machine | null>(null);
  form           = signal<Machine>(EMPTY());
  isProcessing   = signal(false);

  showQrModal    = signal(false);
  qrMachine      = signal<Machine | null>(null);

  readonly statuses: MachineStatus[] = ['AVAILABLE', 'MAINTENANCE', 'OUT_OF_SERVICE'];

  filtered = computed(() => {
    let list = this.machines();
    const q  = this.searchQuery().toLowerCase();
    const sf = this.statusFilter();
    const lf = this.locationFilter().toLowerCase();
    if (q)  list = list.filter(m => m.name.toLowerCase().includes(q) || (m.location ?? '').toLowerCase().includes(q));
    if (sf) list = list.filter(m => m.status === sf);
    if (lf) list = list.filter(m => (m.location ?? '').toLowerCase().includes(lf));
    return list;
  });

  availableCount   = computed(() => this.machines().filter(m => m.status === 'AVAILABLE').length);
  maintenanceCount = computed(() => this.machines().filter(m => m.status === 'MAINTENANCE').length);
  outOfServiceCount= computed(() => this.machines().filter(m => m.status === 'OUT_OF_SERVICE').length);
  locations        = computed(() => [...new Set(this.machines().map(m => m.location ?? '').filter(Boolean))].sort());

  ngOnInit() { this.load(); }

  load() {
    this.isLoading.set(true);
    this.machineApi.getAll().subscribe({
      next: (list) => { 
        this.machines.set(list); 
        this.isLoading.set(false); 
      },
      error: (err) => {
        this.toast.error('Erreur', 'Impossible de charger les machines.');
        this.isLoading.set(false);
      },
    });
  }

  openAdd() {
    this.editingMachine.set(null);
    this.form.set(EMPTY());
    this.showFormModal.set(true);
  }

  openEdit(m: Machine) {
    this.editingMachine.set(m);
    this.form.set({ ...m });
    this.showFormModal.set(true);
  }

  closeForm() { this.showFormModal.set(false); }

  save() {
    const f = this.form();
    if (!f.name.trim()) { this.toast.error('Champ requis', 'Le nom est obligatoire.'); return; }
    this.isProcessing.set(true);

    const editing = this.editingMachine();
    const req = editing?.id
      ? this.machineApi.update(editing.id, f)
      : this.machineApi.create(f);

    req.subscribe({
      next: (saved) => {
        if (editing?.id) {
          this.machines.update(list => list.map(m => m.id === editing.id ? saved : m));
          this.toast.success('Machine mise à jour', saved.name);
        } else {
          this.machines.update(list => [saved, ...list]);
          this.toast.success('Machine créée', saved.name);
        }
        this.isProcessing.set(false); 
        this.showFormModal.set(false);
      },
      error: (err) => {
        this.toast.error('Erreur', err.error?.message || 'Une erreur est survenue lors de l\'enregistrement.');
        this.isProcessing.set(false);
      },
    });
  }

  delete(machine: Machine) {
    if (!machine.id) return;
    if (!confirm(`Supprimer la machine ${machine.name} ?`)) return;

    this.machineApi.delete(machine.id).subscribe({
      next:  () => { 
        this.machines.update(l => l.filter(m => m.id !== machine.id)); 
        this.toast.success('Supprimée', machine.name); 
      },
      error: (err) => {
        this.toast.error('Erreur', 'Impossible de supprimer la machine.');
      },
    });
  }

  requestMaintenance(machine: Machine) {
    if (!machine.id) return;
    const updated = { ...machine, status: 'MAINTENANCE' as MachineStatus };
    this.machineApi.update(machine.id, updated).subscribe({
      next: () => {
        this.machines.update(list => list.map(m => m.id === machine.id ? updated : m));
        this.toast.info('Maintenance demandée', `${machine.name} est désormais en maintenance.`);
      },
      error: () => this.toast.error('Erreur', 'Impossible de mettre à jour le statut.')
    });
  }

  openQr(machine: Machine) {
    if (machine.id) {
      this.machineApi.getQrCode(machine.id).subscribe({
        next: (res) => { 
          this.qrMachine.set({ ...machine, qrCodeData: res.qrData }); 
          this.showQrModal.set(true); 
        },
        error: () => { 
          this.qrMachine.set({ ...machine, qrCodeData: `MACHINE-${machine.id}` }); 
          this.showQrModal.set(true); 
        },
      });
    } else {
      this.qrMachine.set(machine); 
      this.showQrModal.set(true);
    }
  }

  closeQr() { this.showQrModal.set(false); this.qrMachine.set(null); }

  statusBadge(status: MachineStatus): string {
    switch (status) {
      case 'AVAILABLE':     return 'bg-green-500/15 text-green-400 border border-green-500/30';
      case 'MAINTENANCE':   return 'bg-[#D4A017]/12 text-[#D4A017] border border-[#D4A017]/30';
      case 'OUT_OF_SERVICE':return 'bg-red-500/15 text-red-400 border border-red-500/30';
    }
  }

  statusLabel(status: MachineStatus): string {
    return status === 'OUT_OF_SERVICE' ? 'HORS SERVICE' : status;
  }

  statusIcon(status: MachineStatus): string {
    return status === 'AVAILABLE' ? 'fa-check-circle' : status === 'MAINTENANCE' ? 'fa-tools' : 'fa-times-circle';
  }

  updateForm(patch: Partial<Machine>) { this.form.update(f => ({ ...f, ...patch })); }
}
