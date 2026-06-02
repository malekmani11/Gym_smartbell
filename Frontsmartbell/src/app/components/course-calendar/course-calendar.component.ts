import { Component, signal, computed, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { CourseApiService } from '../../services/course-api.service';
import { CoachApiService } from '../../services/coach-api.service';
import { ToastService } from '../../services/toast.service';
import { AttendanceApiService } from '../../services/attendance-api.service';
import { CourseDTO, CoachDTO } from '../../models/api.models';

interface AttendanceRow {
  memberId: number;
  memberName: string;
  present: boolean;
}

const DAY_KEYS   = ['MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY'];
const DAY_LABELS = ['Lun.','Mar.','Mer.','Jeu.','Ven.','Sam.','Dim.'];
const PX_PER_MIN = 2;
const START_HOUR = 6;
const END_HOUR   = 22;

const TYPE_STYLES: Record<string, { bg: string; border: string; text: string }> = {
  yoga:         { bg: 'rgba(147,51,234,0.18)',  border: '#9333ea', text: '#d8b4fe' },
  crossfit:     { bg: 'rgba(249,115,22,0.18)',  border: '#f97316', text: '#fdba74' },
  powerlifting: { bg: 'rgba(239,68,68,0.18)',   border: '#ef4444', text: '#fca5a5' },
  cardio:       { bg: 'rgba(59,130,246,0.18)',  border: '#3b82f6', text: '#93c5fd' },
};
const DEFAULT_STYLE = { bg: 'rgba(212,160,23,0.18)', border: '#D4A017', text: '#F5D77A' };

export interface CourseBlock {
  id: number;
  name: string;
  dayOfWeek: string;
  startTime: string;
  endTime: string;
  coach: string;
  coachId: number | null;
  enrolled: number;
  capacity: number;
  type: string;
  style: { bg: string; border: string; text: string };
  top: number;
  height: number;
  startMin: number;
  endMin: number;
  left: number;
  widthPct: number;
}

@Component({
  selector: 'app-course-calendar',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './course-calendar.component.html',
  styleUrl: './course-calendar.component.css',
})
export class CourseCalendarComponent implements OnInit {
  private courseApi      = inject(CourseApiService);
  private coachApi       = inject(CoachApiService);
  private toast          = inject(ToastService);
  private attendanceApi  = inject(AttendanceApiService);

  isLoading        = signal(true);
  isProcessing     = signal(false);
  typeFilter       = signal<string>('all');
  courses          = signal<CourseDTO[]>([]);
  coaches          = signal<CoachDTO[]>([]);
  isLoadingCoaches = signal(false);
  showNewModal         = signal(false);
  showEditModal        = signal(false);
  showAttendanceModal  = signal(false);
  attendanceRows       = signal<AttendanceRow[]>([]);
  attendanceDate       = signal<string>(new Date().toISOString().split('T')[0]);
  isLoadingAttendance  = signal(false);
  selectedCourse       = signal<CourseBlock | null>(null);
  weekOffset           = signal(0);

  currentWeekLabel = computed(() => {
    const today  = new Date();
    const monday = new Date(today);
    monday.setDate(today.getDate() - ((today.getDay() + 6) % 7) + this.weekOffset() * 7);
    const sunday = new Date(monday);
    sunday.setDate(monday.getDate() + 6);
    const fmt = (d: Date) => d.toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' });
    return `${fmt(monday)} – ${fmt(sunday)} ${monday.getFullYear()}`;
  });

  weekDates = computed(() => {
    const today  = new Date();
    const monday = new Date(today);
    monday.setDate(today.getDate() - ((today.getDay() + 6) % 7) + this.weekOffset() * 7);
    return DAY_KEYS.map((_, i) => {
      const d = new Date(monday);
      d.setDate(monday.getDate() + i);
      return d;
    });
  });

  todayDayKey = computed(() => {
    if (this.weekOffset() !== 0) return '';
    const days = ['SUNDAY','MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY'];
    return days[new Date().getDay()];
  });

  timeSlots = Array.from({ length: END_HOUR - START_HOUR }, (_, i) => {
    const h = START_HOUR + i;
    return `${String(h).padStart(2, '0')}:00`;
  });

  coursesByDay = computed(() => {
    const filter = this.typeFilter();
    return DAY_KEYS.map(day => {
      const blocks = this.courses()
        .filter(c => c.dayOfWeek === day)
        .filter(c => filter === 'all' || this._inferType(c.name) === filter)
        .map(c => this._toBlock(c));
      return this._resolveOverlaps(blocks);
    });
  });

  legendItems = [
    { color: '#9333ea', label: 'Yoga' },
    { color: '#f97316', label: 'CrossFit' },
    { color: '#ef4444', label: 'Powerlifting' },
    { color: '#3b82f6', label: 'Cardio' },
    { color: '#D4A017', label: 'Autre' },
  ];

  editForm = {
    name: '', coachId: null as number | null, dayOfWeek: 'MONDAY',
    timeStart: '08:00', timeEnd: '09:00', capacity: 15,
  };

  newForm = {
    name: '', coachId: null as number | null, type: 'yoga',
    timeStart: '08:00', timeEnd: '09:00', capacity: 15,
    level: 'Tous niveaux', dayOfWeek: 'MONDAY',
  };

  readonly DAY_KEYS       = DAY_KEYS;
  readonly DAY_LABELS     = DAY_LABELS;
  readonly TOTAL_HEIGHT   = (END_HOUR - START_HOUR) * 60 * PX_PER_MIN;
  readonly DAY_FORM_LABELS = [
    { value: 'MONDAY',    label: 'Lundi'    },
    { value: 'TUESDAY',   label: 'Mardi'    },
    { value: 'WEDNESDAY', label: 'Mercredi' },
    { value: 'THURSDAY',  label: 'Jeudi'    },
    { value: 'FRIDAY',    label: 'Vendredi' },
    { value: 'SATURDAY',  label: 'Samedi'   },
    { value: 'SUNDAY',    label: 'Dimanche' },
  ];

  ngOnInit() { this.loadCourses(); this.loadCoaches(); }

  loadCourses() {
    this.isLoading.set(true);
    this.courseApi.getAll().subscribe({
      next:  (page) => { this.courses.set(page.content || []); this.isLoading.set(false); },
      error: ()     => { this.courses.set([]);                 this.isLoading.set(false); },
    });
  }

  loadCoaches() {
    this.isLoadingCoaches.set(true);
    this.coachApi.getAll().subscribe({
      next:  (res) => { this.coaches.set(res.content || []); this.isLoadingCoaches.set(false); },
      error: ()    => { this.isLoadingCoaches.set(false); },
    });
  }

  prevWeek() { this.weekOffset.update(v => v - 1); }
  nextWeek() { this.weekOffset.update(v => v + 1); }
  goToday()  { this.weekOffset.set(0); }

  openCourse(block: CourseBlock) {
    this.selectedCourse.set(block);
    this.editForm = {
      name:      block.name,
      coachId:   block.coachId,
      dayOfWeek: block.dayOfWeek,
      timeStart: block.startTime,
      timeEnd:   block.endTime,
      capacity:  block.capacity,
    };
    this.showEditModal.set(true);
  }

  openNewCourse() {
    this.newForm = {
      name: '', coachId: this.coaches().length > 0 ? this.coaches()[0].id : null,
      type: 'yoga', timeStart: '08:00', timeEnd: '09:00',
      capacity: 15, level: 'Tous niveaux', dayOfWeek: 'MONDAY',
    };
    this.showNewModal.set(true);
  }

  saveNewCourse() {
    if (!this.newForm.name.trim() || !this.newForm.coachId || this.isProcessing()) return;
    if (!this._isTimeValid(this.newForm.timeStart, this.newForm.timeEnd)) {
      this.toast.error('Horaires invalides', "L'heure de fin doit être après l'heure de début.");
      return;
    }
    this.isProcessing.set(true);
    this.courseApi.create({
      name: this.newForm.name.trim(), coachId: this.newForm.coachId,
      dayOfWeek: this.newForm.dayOfWeek, startTime: this.newForm.timeStart,
      endTime: this.newForm.timeEnd, maxParticipants: this.newForm.capacity,
    }).subscribe({
      next: (created) => {
        this.toast.success('Cours créé', `${created.name} ajouté.`);
        this.isProcessing.set(false); this.showNewModal.set(false); this.loadCourses();
      },
      error: () => { this.isProcessing.set(false); this.toast.error('Erreur', 'Impossible de créer le cours.'); },
    });
  }

  saveEdit() {
    const c = this.selectedCourse();
    if (!c || this.isProcessing()) return;
    if (!this._isTimeValid(this.editForm.timeStart, this.editForm.timeEnd)) {
      this.toast.error('Horaires invalides', "L'heure de fin doit être après l'heure de début.");
      return;
    }
    this.isProcessing.set(true);
    this.courseApi.update(c.id, {
      name: this.editForm.name.trim(), dayOfWeek: this.editForm.dayOfWeek,
      startTime: this.editForm.timeStart, endTime: this.editForm.timeEnd,
      maxParticipants: this.editForm.capacity,
      ...(this.editForm.coachId != null ? { coachId: this.editForm.coachId } : {}),
    }).subscribe({
      next: () => {
        this.toast.success('Cours modifié', `${this.editForm.name} mis à jour.`);
        this.isProcessing.set(false); this.showEditModal.set(false); this.loadCourses();
      },
      error: () => { this.isProcessing.set(false); this.toast.error('Erreur', 'Impossible de modifier.'); },
    });
  }

  deleteCourse() {
    const c = this.selectedCourse();
    if (!c || this.isProcessing()) return;
    if (!confirm(`Supprimer "${c.name}" ?`)) return;
    this.isProcessing.set(true);
    this.courseApi.delete(c.id).subscribe({
      next: () => {
        this.toast.success('Supprimé', `${c.name} supprimé.`);
        this.isProcessing.set(false); this.showEditModal.set(false); this.loadCourses();
      },
      error: () => { this.isProcessing.set(false); this.toast.error('Erreur', 'Impossible de supprimer.'); },
    });
  }

  openAttendanceModal() {
    const c = this.selectedCourse();
    if (!c) return;
    this.showEditModal.set(false);
    this.isLoadingAttendance.set(true);
    this.showAttendanceModal.set(true);

    this.courseApi.getReservationsByCourse(c.id).subscribe({
      next: (reservations) => {
        const rows: AttendanceRow[] = reservations
          .filter((r: any) => r.status === 'CONFIRMED')
          .map((r: any) => ({
            memberId:   r.memberId,
            memberName: `${r.memberFirstName ?? ''} ${r.memberLastName ?? ''}`.trim() || `Membre #${r.memberId}`,
            present:    true,
          }));
        this.attendanceRows.set(rows);
        this.isLoadingAttendance.set(false);
      },
      error: () => {
        this.toast.error('Erreur', 'Impossible de charger les inscrits.');
        this.isLoadingAttendance.set(false);
        this.showAttendanceModal.set(false);
      },
    });
  }

  saveAttendance() {
    const c = this.selectedCourse();
    if (!c || this.isProcessing()) return;
    this.isProcessing.set(true);
    this.attendanceApi.record(
      c.id,
      this.attendanceDate(),
      this.attendanceRows().map(r => ({ memberId: r.memberId, present: r.present }))
    ).subscribe({
      next: () => {
        this.toast.success('Présences enregistrées', `${c.name} — ${this.attendanceDate()}`);
        this.isProcessing.set(false);
        this.showAttendanceModal.set(false);
      },
      error: () => {
        this.toast.error('Erreur', 'Impossible d\'enregistrer les présences.');
        this.isProcessing.set(false);
      },
    });
  }

  printSchedule() { window.print(); }

  badgeColor(block: CourseBlock): string {
    if (block.capacity === 0) return '#6b7280';
    const pct = block.enrolled / block.capacity;
    if (pct >= 1)   return '#ef4444';
    if (pct >= 0.8) return '#f97316';
    return '#22c55e';
  }

  badgeLabel(block: CourseBlock): string {
    if (block.capacity === 0) return '—';
    return block.enrolled >= block.capacity ? 'Complet' : `${block.enrolled}/${block.capacity}`;
  }

  private _toBlock(c: CourseDTO): CourseBlock {
    const type  = this._inferType(c.name);
    const style = TYPE_STYLES[type] ?? DEFAULT_STYLE;
    const start = c.startTime?.slice(0, 5) ?? '08:00';
    const end   = c.endTime?.slice(0, 5)   ?? '09:00';
    const [sh, sm] = start.split(':').map(Number);
    const [eh, em] = end.split(':').map(Number);
    const startMin = (sh - START_HOUR) * 60 + sm;
    const endMin   = (eh - START_HOUR) * 60 + em;
    return {
      id: c.id, name: c.name, dayOfWeek: c.dayOfWeek,
      startTime: start, endTime: end,
      coach: c.coachName ?? '—', coachId: c.coachId ?? null,
      enrolled: c.currentParticipants ?? 0,
      capacity: c.maxParticipants ?? 0,
      type, style,
      top:    Math.max(0, startMin) * PX_PER_MIN,
      height: Math.max(30, endMin - startMin) * PX_PER_MIN,
      startMin, endMin,
      left: 0, widthPct: 100,
    };
  }

  private _resolveOverlaps(blocks: CourseBlock[]): CourseBlock[] {
    if (blocks.length === 0) return [];

    const sorted = [...blocks].sort((a, b) => a.startMin - b.startMin);
    const groups: CourseBlock[][] = [];
    let currentGroup: CourseBlock[] = [];
    let maxEnd = -1;

    for (const block of sorted) {
      if (block.startMin < maxEnd) {
        currentGroup.push(block);
        maxEnd = Math.max(maxEnd, block.endMin);
      } else {
        if (currentGroup.length > 0) groups.push(currentGroup);
        currentGroup = [block];
        maxEnd = block.endMin;
      }
    }
    if (currentGroup.length > 0) groups.push(currentGroup);

    const result: CourseBlock[] = [];
    for (const group of groups) {
      const count = group.length;
      group.forEach((block, idx) => {
        result.push({ ...block, widthPct: 100 / count, left: idx * (100 / count) });
      });
    }
    return result;
  }

  private _inferType(name: string): string {
    const n = name.toLowerCase();
    if (n.includes('yoga'))                          return 'yoga';
    if (n.includes('crossfit') || n.includes('cross')) return 'crossfit';
    if (n.includes('power')    || n.includes('lifting')) return 'powerlifting';
    return 'cardio';
  }

  private _isTimeValid(s: string, e: string): boolean {
    const [sh, sm] = s.split(':').map(Number);
    const [eh, em] = e.split(':').map(Number);
    return (eh * 60 + em) > (sh * 60 + sm);
  }
}
