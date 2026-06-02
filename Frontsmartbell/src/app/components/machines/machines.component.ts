import { Component, signal, computed, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ToastService } from '../../services/toast.service';
import { MachineApiService, Machine, MachineStatus } from '../../services/machine-api.service';
import { SalleApiService, Salle } from '../../services/salle-api.service';

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
  private salleApi  = inject(SalleApiService);
  private toast = inject(ToastService);

  salles = signal<Salle[]>([]);

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

  ngOnInit() {
    this.load();
    this.salleApi.getAll().subscribe({
      next: (list) => this.salles.set(list),
      error: () => this.toast.error('Erreur', 'Impossible de charger les salles.'),
    });
  }

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
    const qrData = machine.tutorialUrl?.trim()
      ? machine.tutorialUrl
      : `MACHINE-${machine.id}-${(machine.name ?? '').replace(/\s+/g, '_').toUpperCase()}`;
    this.qrMachine.set({ ...machine, qrCodeData: qrData });
    this.showQrModal.set(true);
  }

  closeQr() { this.showQrModal.set(false); this.qrMachine.set(null); }

  getMachineImage(machine: Machine): string {
    const text = `${machine.name ?? ''} ${machine.description ?? ''}`.toLowerCase();
    const id   = machine.id ?? 0;

    // Pools de photos par type — on choisit selon id % longueur pour varier
    const pick = (urls: string[]) => urls[id % urls.length];

    if (text.includes('tapis') || text.includes('treadmill'))
      return pick([
        'https://images.unsplash.com/photo-1599058917765-a780eda07a3e?w=400&q=80&fit=crop',
        'https://images.unsplash.com/photo-1637666155747-5ac0be5c57a3?w=400&q=80&fit=crop',
        'https://images.unsplash.com/photo-1558611848-73f7eb4001a1?w=400&q=80&fit=crop',
      ]);
    if (text.includes('elliptique') || text.includes('vélo') || text.includes('velo') || text.includes('spinning') || text.includes('bike'))
      return pick([
        'https://images.unsplash.com/photo-1605296867304-46d5465a13f1?w=400&q=80&fit=crop',
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&q=80&fit=crop',
        'https://images.unsplash.com/photo-1521673461164-de300ebcfb17?w=400&q=80&fit=crop',
      ]);
    if (text.includes('rameur') || text.includes('rower'))
      return pick([
        'https://images.unsplash.com/photo-1616279969965-f3a091f13f9a?w=400&q=80&fit=crop',
        'https://images.unsplash.com/photo-1580086319619-3ed498161c77?w=400&q=80&fit=crop',
      ]);
    if (text.includes('barre') || text.includes('haltère') || text.includes('haltere') || text.includes('olympique') || text.includes('poids'))
      return pick([
        'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?w=400&q=80&fit=crop',
        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&q=80&fit=crop',
        'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=400&q=80&fit=crop',
      ]);
    if (text.includes('cage') || text.includes('squat') || text.includes('rack'))
      return pick([
        'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400&q=80&fit=crop',
        'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=400&q=80&fit=crop',
      ]);
    if (text.includes('presse') || text.includes('jambe'))
      return 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=400&q=80&fit=crop';
    if (text.includes('corde') || text.includes('boxe') || text.includes('sac'))
      return 'https://images.unsplash.com/photo-1555597673-b21d5c935865?w=400&q=80&fit=crop';
    if (text.includes('banc') || text.includes('chest') || text.includes('pec'))
      return pick([
        'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=400&q=80&fit=crop',
        'https://images.unsplash.com/photo-1534367610401-9f5ed68180aa?w=400&q=80&fit=crop',
      ]);
    if (text.includes('cardio') || text.includes('stepper') || text.includes('crosstrainer'))
      return pick([
        'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=400&q=80&fit=crop',
        'https://images.unsplash.com/photo-1549060279-7e168fcee0c2?w=400&q=80&fit=crop',
      ]);
    // Défaut : varie selon id
    return pick([
      'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=400&q=80&fit=crop',
      'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&q=80&fit=crop',
      'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400&q=80&fit=crop',
      'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=400&q=80&fit=crop',
    ]);
  }

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

  qrImageUrl(data: string): string {
    return `https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=${encodeURIComponent(data)}`;
  }
}
