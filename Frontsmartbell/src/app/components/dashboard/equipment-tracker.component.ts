import { Component, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';

export type EquipmentStatus = 'ok' | 'maintenance' | 'hs';

export interface Equipment {
  id: string;
  name: string;
  category: string;
  status: EquipmentStatus;
  lastRevision: Date;
  nextRevision: Date;
  usageHours: number;
  notes?: string;
  icon: string;
}

type FilterKey = 'all' | EquipmentStatus;

const now = Date.now();
const days = (n: number) => new Date(now + n * 86400000);

const SEED: Equipment[] = [
  {
    id: 'eq-1', name: 'Tapis de course #1', category: 'Cardio',
    status: 'ok', icon: 'fas fa-running',
    lastRevision: days(-30), nextRevision: days(60), usageHours: 412,
  },
  {
    id: 'eq-2', name: 'Tapis de course #2', category: 'Cardio',
    status: 'ok', icon: 'fas fa-running',
    lastRevision: days(-45), nextRevision: days(45), usageHours: 380,
  },
  {
    id: 'eq-3', name: 'Tapis de course #3', category: 'Cardio',
    status: 'maintenance', icon: 'fas fa-running',
    lastRevision: days(-60), nextRevision: days(3),
    usageHours: 610, notes: 'Courroie usée — technicien prévu',
  },
  {
    id: 'eq-4', name: 'Vélo elliptique #1', category: 'Cardio',
    status: 'ok', icon: 'fas fa-bicycle',
    lastRevision: days(-20), nextRevision: days(70), usageHours: 295,
  },
  {
    id: 'eq-5', name: 'Vélo elliptique #2', category: 'Cardio',
    status: 'ok', icon: 'fas fa-bicycle',
    lastRevision: days(-25), nextRevision: days(65), usageHours: 310,
  },
  {
    id: 'eq-6', name: 'Presse à cuisses', category: 'Musculation',
    status: 'hs', icon: 'fas fa-dumbbell',
    lastRevision: days(-90), nextRevision: days(-5),
    usageHours: 890, notes: 'Vérin hydraulique défaillant — pièce commandée',
  },
  {
    id: 'eq-7', name: 'Banc de musculation #1', category: 'Musculation',
    status: 'ok', icon: 'fas fa-dumbbell',
    lastRevision: days(-15), nextRevision: days(75), usageHours: 220,
  },
  {
    id: 'eq-8', name: 'Banc de musculation #2', category: 'Musculation',
    status: 'ok', icon: 'fas fa-dumbbell',
    lastRevision: days(-18), nextRevision: days(72), usageHours: 198,
  },
  {
    id: 'eq-9', name: 'Lot cordes à sauter', category: 'Accessoires',
    status: 'ok', icon: 'fas fa-circle-notch',
    lastRevision: days(-10), nextRevision: days(80), usageHours: 55,
  },
  {
    id: 'eq-10', name: 'Rack squat', category: 'Musculation',
    status: 'maintenance', icon: 'fas fa-weight-hanging',
    lastRevision: days(-55), nextRevision: days(5),
    usageHours: 740, notes: 'Révision préventive planifiée dans 5 jours',
  },
];

@Component({
  selector: 'app-equipment-tracker',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './equipment-tracker.component.html',
})
export class EquipmentTrackerComponent {

  equipment  = signal<Equipment[]>(SEED);
  activeFilter = signal<FilterKey>('all');

  readonly filters: { key: FilterKey; label: string }[] = [
    { key: 'all',         label: 'Tous'        },
    { key: 'ok',          label: 'OK'           },
    { key: 'maintenance', label: 'Maintenance'  },
    { key: 'hs',          label: 'Hors service' },
  ];

  // ── Compteurs ─────────────────────────────────────────────────────────────
  countOk          = computed(() => this.equipment().filter(e => e.status === 'ok').length);
  countMaintenance = computed(() => this.equipment().filter(e => e.status === 'maintenance').length);
  countHs          = computed(() => this.equipment().filter(e => e.status === 'hs').length);

  // ── Alertes ───────────────────────────────────────────────────────────────
  alerts = computed(() => {
    const list: string[] = [];
    for (const e of this.equipment()) {
      if (e.status === 'hs')
        list.push(`${e.name} est hors service.`);
      else if (this.daysUntil(e.nextRevision) < 7)
        list.push(`${e.name} : révision dans ${this.daysUntil(e.nextRevision)} jour(s).`);
    }
    return list;
  });

  // ── Vue filtrée ───────────────────────────────────────────────────────────
  filtered = computed(() => {
    const f = this.activeFilter();
    return f === 'all' ? this.equipment() : this.equipment().filter(e => e.status === f);
  });

  // ── Helpers ───────────────────────────────────────────────────────────────
  daysUntil(date: Date): number {
    return Math.ceil((date.getTime() - Date.now()) / 86400000);
  }

  statusBadgeClass(status: EquipmentStatus): string {
    switch (status) {
      case 'ok':          return 'bg-green-500/15 text-green-400 border-green-500/30';
      case 'maintenance': return 'bg-orange-500/15 text-orange-400 border-orange-500/30';
      case 'hs':          return 'bg-red-500/15 text-red-400 border-red-500/30';
    }
  }

  statusLabel(status: EquipmentStatus): string {
    switch (status) {
      case 'ok':          return 'OK';
      case 'maintenance': return 'Maintenance';
      case 'hs':          return 'Hors service';
    }
  }

  rowBorderClass(status: EquipmentStatus): string {
    switch (status) {
      case 'ok':          return 'border-l-2 border-l-green-500/40';
      case 'maintenance': return 'border-l-2 border-l-orange-500/60';
      case 'hs':          return 'border-l-2 border-l-red-500/60';
    }
  }

  nextRevisionClass(eq: Equipment): string {
    const d = this.daysUntil(eq.nextRevision);
    if (d < 0)  return 'text-red-400 font-black';
    if (d < 7)  return 'text-orange-400 font-bold';
    return 'text-gray-500';
  }

  nextRevisionLabel(eq: Equipment): string {
    const d = this.daysUntil(eq.nextRevision);
    if (d < 0)  return `Dépassée (${Math.abs(d)}j)`;
    if (d === 0) return 'Aujourd\'hui';
    return `Dans ${d}j`;
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  reportIssue(id: string) {
    this.equipment.update(list =>
      list.map(e => e.id === id ? { ...e, status: 'maintenance' as EquipmentStatus } : e)
    );
  }

  markRepaired(id: string) {
    this.equipment.update(list =>
      list.map(e => e.id === id
        ? { ...e, status: 'ok' as EquipmentStatus, lastRevision: new Date(), nextRevision: days(90) }
        : e
      )
    );
  }
}
