import { Component, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

export interface CourseSlot {
  id: string;
  name: string;
  coach: string;
  day: number;        // 0 = Lun … 6 = Dim
  startHour: number;  // ex: 9.5 = 9h30
  duration: number;   // en heures (ex: 1, 1.5)
  capacity: number;
  enrolled: number;
  color: string;      // classe Tailwind de base (bg-…)
}

interface SlotForm {
  name: string;
  coach: string;
  day: number;
  startHour: number;
  duration: number;
  capacity: number;
}

// ── Category → course names mapping ──────────────────────────────────────────
const CATEGORY_MAP: Record<string, string[]> = {
  'Yoga':         ['Yoga Flow', 'Pilates'],
  'CrossFit':     ['CrossFit WOD'],
  'Powerlifting': ['Powerlifting'],
  'Cardio':       ['HIIT Cardio', 'Spinning'],
};

// ── Coach avatars ─────────────────────────────────────────────────────────────
const COACH_AVATARS: Record<string, string> = {
  'Marc Leroux':   'https://i.pravatar.cc/150?u=coach_marc_l',
  'Julie Vernet':  'https://i.pravatar.cc/150?u=coach_julie_v',
  'Sarah Garnier': 'https://i.pravatar.cc/150?u=coach_sarah_g',
  'Thomas Dumont': 'https://i.pravatar.cc/150?u=coach_thomas_d',
};

const COURSE_PRICE_PER_SESSION = 15; // DT par participant

// ── Seed data ─────────────────────────────────────────────────────────────────
const SEED_SLOTS: CourseSlot[] = [
  { id: 's1',  name: 'CrossFit WOD',  coach: 'Marc Leroux',   day: 0, startHour: 7,  duration: 1,   capacity: 20, enrolled: 18, color: 'bg-orange-500' },
  { id: 's2',  name: 'Yoga Flow',     coach: 'Julie Vernet',  day: 0, startHour: 9,  duration: 1.5, capacity: 15, enrolled: 14, color: 'bg-purple-500' },
  { id: 's3',  name: 'HIIT Cardio',   coach: 'Sarah Garnier', day: 1, startHour: 7,  duration: 1,   capacity: 25, enrolled: 24, color: 'bg-red-500'    },
  { id: 's4',  name: 'Powerlifting',  coach: 'Thomas Dumont', day: 1, startHour: 18, duration: 1.5, capacity: 10, enrolled: 6,  color: 'bg-blue-500'   },
  { id: 's5',  name: 'Spinning',      coach: 'Marc Leroux',   day: 2, startHour: 12, duration: 1,   capacity: 20, enrolled: 12, color: 'bg-cyan-500'   },
  { id: 's6',  name: 'Pilates',       coach: 'Julie Vernet',  day: 2, startHour: 17, duration: 1,   capacity: 12, enrolled: 11, color: 'bg-pink-500'   },
  { id: 's7',  name: 'CrossFit WOD',  coach: 'Marc Leroux',   day: 3, startHour: 7,  duration: 1,   capacity: 20, enrolled: 20, color: 'bg-orange-500' },
  { id: 's8',  name: 'Yoga Flow',     coach: 'Julie Vernet',  day: 3, startHour: 19, duration: 1.5, capacity: 15, enrolled: 8,  color: 'bg-purple-500' },
  { id: 's9',  name: 'HIIT Cardio',   coach: 'Sarah Garnier', day: 4, startHour: 12, duration: 1,   capacity: 25, enrolled: 15, color: 'bg-red-500'    },
  { id: 's10', name: 'Powerlifting',  coach: 'Thomas Dumont', day: 5, startHour: 9,  duration: 2,   capacity: 10, enrolled: 9,  color: 'bg-blue-500'   },
  { id: 's11', name: 'Spinning',      coach: 'Marc Leroux',   day: 5, startHour: 16, duration: 1,   capacity: 20, enrolled: 7,  color: 'bg-cyan-500'   },
  { id: 's12', name: 'Pilates',       coach: 'Julie Vernet',  day: 6, startHour: 10, duration: 1.5, capacity: 12, enrolled: 5,  color: 'bg-pink-500'   },
];

const SLOT_COLORS = [
  'bg-orange-500', 'bg-purple-500', 'bg-red-500', 'bg-blue-500',
  'bg-cyan-500',   'bg-pink-500',   'bg-green-500', 'bg-yellow-500',
];

@Component({
  selector: 'app-weekly-schedule',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './weekly-schedule.component.html',
})
export class WeeklyScheduleComponent {

  // ── Grid constants ────────────────────────────────────────────────────────
  readonly DAY_LABELS  = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  readonly START_HOUR  = 7;
  readonly END_HOUR    = 21;
  readonly HOURS       = Array.from({ length: this.END_HOUR - this.START_HOUR }, (_, i) => this.START_HOUR + i);
  readonly PX_PER_HOUR = 64;
  readonly CATEGORIES  = ['Tous', 'Yoga', 'CrossFit', 'Powerlifting', 'Cardio'];

  // ── State ─────────────────────────────────────────────────────────────────
  weekOffset     = signal(0);
  coachFilter    = signal('');
  activeCategory = signal('Tous');
  searchQuery    = signal('');
  slots          = signal<CourseSlot[]>(SEED_SLOTS);
  selectedSlot   = signal<CourseSlot | null>(null);
  showSlotModal  = signal(false);
  showAddForm    = signal(false);
  reservedSlots  = signal<Set<string>>(new Set());

  emptyForm = (): SlotForm => ({
    name: '', coach: '', day: 0, startHour: 7, duration: 1, capacity: 15,
  });
  addForm       = signal<SlotForm>(this.emptyForm());
  selectedColor = signal(SLOT_COLORS[0]);
  readonly slotColors = SLOT_COLORS;

  // ── Weekly summary ────────────────────────────────────────────────────────
  weeklyTotalCourses = computed(() => this.slots().length);

  weeklyTotalEnrolled = computed(() =>
    this.slots().reduce((sum, s) => sum + s.enrolled, 0)
  );

  weeklyFillRate = computed(() => {
    const cap = this.slots().reduce((sum, s) => sum + s.capacity, 0);
    return cap > 0 ? Math.round((this.weeklyTotalEnrolled() / cap) * 100) : 0;
  });

  weeklyRevenue = computed(() =>
    this.weeklyTotalEnrolled() * COURSE_PRICE_PER_SESSION
  );

  weeklyAvailableSpots = computed(() =>
    this.slots().reduce((sum, s) => sum + Math.max(0, s.capacity - s.enrolled), 0)
  );

  // ── Week label ────────────────────────────────────────────────────────────
  weekLabel = computed(() => {
    const now    = new Date();
    const monday = new Date(now);
    monday.setDate(now.getDate() - ((now.getDay() + 6) % 7) + this.weekOffset() * 7);
    const sunday = new Date(monday);
    sunday.setDate(monday.getDate() + 6);
    const fmt = (d: Date) => d.toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' });
    return `${fmt(monday)} – ${fmt(sunday)}`;
  });

  // ── Coaches list ──────────────────────────────────────────────────────────
  coaches = computed(() =>
    [...new Set(this.slots().map(s => s.coach))].sort()
  );

  // ── Filtered slots (coach + category + search) ────────────────────────────
  filteredSlots = computed(() => {
    const coach    = this.coachFilter();
    const category = this.activeCategory();
    const query    = this.searchQuery().toLowerCase().trim();

    return this.slots().filter(s => {
      const matchCoach    = !coach    || s.coach === coach;
      const matchCategory = category === 'Tous' || (CATEGORY_MAP[category]?.includes(s.name) ?? false);
      const matchSearch   = !query   || s.name.toLowerCase().includes(query) || s.coach.toLowerCase().includes(query);
      return matchCoach && matchCategory && matchSearch;
    });
  });

  /** Slots for a given day from the filtered set */
  slotsForDay(day: number): CourseSlot[] {
    return this.filteredSlots().filter(s => s.day === day);
  }

  // ── CSS positioning ────────────────────────────────────────────────────────
  topPx(slot: CourseSlot): number {
    return (slot.startHour - this.START_HOUR) * this.PX_PER_HOUR;
  }

  heightPx(slot: CourseSlot): number {
    return slot.duration * this.PX_PER_HOUR - 4;
  }

  // ── Fill helpers ───────────────────────────────────────────────────────────
  fillClass(slot: CourseSlot): string {
    const pct = slot.enrolled / slot.capacity;
    if (pct >= 1)   return 'border-red-500/50 shadow-red-500/15';
    if (pct >= 0.8) return 'border-[#D4A017]/50 shadow-[#D4A017]/15';
    return 'border-green-500/40 shadow-green-500/10';
  }

  fillBadgeClass(slot: CourseSlot): string {
    const pct = slot.enrolled / slot.capacity;
    if (pct >= 1)   return 'text-red-400';
    if (pct >= 0.8) return 'text-[#D4A017]';
    return 'text-green-400';
  }

  fillBarClass(slot: CourseSlot): string {
    const pct = slot.enrolled / slot.capacity;
    if (pct >= 1)   return 'bg-red-500';
    if (pct >= 0.8) return 'bg-[#D4A017]';
    return 'bg-green-500';
  }

  fillPct(slot: CourseSlot): number {
    return Math.min(100, Math.round((slot.enrolled / slot.capacity) * 100));
  }

  // ── Status badge ──────────────────────────────────────────────────────────
  getStatusBadge(slot: CourseSlot): { label: string; cls: string } {
    const pct = slot.enrolled / slot.capacity;
    if (pct >= 1)   return { label: 'COMPLET',          cls: 'bg-red-500/15 text-red-400 border border-red-500/30'           };
    if (pct >= 0.8) return { label: 'BIENTÔT COMPLET',  cls: 'bg-[#D4A017]/12 text-[#D4A017] border border-[#D4A017]/30'    };
    return              { label: 'DISPONIBLE',          cls: 'bg-green-500/12 text-green-400 border border-green-500/30'    };
  }

  // ── Spots remaining ────────────────────────────────────────────────────────
  spotsRemaining(slot: CourseSlot): number {
    return Math.max(0, slot.capacity - slot.enrolled);
  }

  // ── Coach avatar ──────────────────────────────────────────────────────────
  coachAvatar(coach: string): string {
    return COACH_AVATARS[coach] ?? `https://i.pravatar.cc/150?u=${encodeURIComponent(coach)}`;
  }

  // ── Reservation ───────────────────────────────────────────────────────────
  isReserved(slotId: string): boolean {
    return this.reservedSlots().has(slotId);
  }

  reserveSlot(slot: CourseSlot, event: Event) {
    event.stopPropagation();
    const wasReserved = this.isReserved(slot.id);
    if (!wasReserved && slot.enrolled >= slot.capacity) return;

    this.reservedSlots.update(set => {
      const next = new Set(set);
      wasReserved ? next.delete(slot.id) : next.add(slot.id);
      return next;
    });

    this.slots.update(list =>
      list.map(s =>
        s.id === slot.id
          ? { ...s, enrolled: wasReserved ? s.enrolled - 1 : s.enrolled + 1 }
          : s
      )
    );

    // Keep selected slot in sync when modal is open
    if (this.selectedSlot()?.id === slot.id) {
      const updated = this.slots().find(s => s.id === slot.id) ?? null;
      this.selectedSlot.set(updated);
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  prevWeek() { this.weekOffset.update(n => n - 1); }
  nextWeek()  { this.weekOffset.update(n => n + 1); }

  // ── Slot modal ────────────────────────────────────────────────────────────
  openSlot(slot: CourseSlot) {
    this.selectedSlot.set(slot);
    this.showSlotModal.set(true);
  }

  closeSlot() {
    this.showSlotModal.set(false);
    this.selectedSlot.set(null);
  }

  // ── Add form ──────────────────────────────────────────────────────────────
  toggleAddForm() {
    this.showAddForm.update(v => !v);
    if (!this.showAddForm()) {
      this.addForm.set(this.emptyForm());
      this.selectedColor.set(SLOT_COLORS[0]);
    }
  }

  updateAddForm(patch: Partial<SlotForm>) {
    this.addForm.update(f => ({ ...f, ...patch }));
  }

  get addFormValid(): boolean {
    const f = this.addForm();
    return !!f.name.trim() && !!f.coach.trim() && f.capacity > 0
      && f.startHour >= this.START_HOUR && f.startHour + f.duration <= this.END_HOUR;
  }

  submitAdd() {
    if (!this.addFormValid) return;
    const f = this.addForm();
    this.slots.update(list => [...list, {
      id:        `s-${Date.now()}`,
      name:      f.name.trim(),
      coach:     f.coach.trim(),
      day:       f.day,
      startHour: f.startHour,
      duration:  f.duration,
      capacity:  f.capacity,
      enrolled:  0,
      color:     this.selectedColor(),
    }]);
    this.addForm.set(this.emptyForm());
    this.selectedColor.set(SLOT_COLORS[0]);
    this.showAddForm.set(false);
  }

  // ── Mock member list ───────────────────────────────────────────────────────
  mockMembers(slot: CourseSlot): string[] {
    const names = [
      'Sophie Laurent', 'Lucas Martin', 'Emma Bernard', 'Thomas Renard',
      'Camille Morin',  'Antoine Faure', 'Nadia Ferhat', 'Karim Aziz',
      'Sonia Marchand', 'Omar Khalil',   'Rayan Sfar',   'Hela Mansouri',
    ];
    return names.slice(0, slot.enrolled);
  }

  hourLabel(h: number): string {
    return `${h}h`;
  }

  setCategory(cat: string) {
    this.activeCategory.set(cat);
  }
}
