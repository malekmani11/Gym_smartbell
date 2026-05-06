import { Component, signal, computed, inject, input, OnInit, ViewChild, AfterViewInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { FullCalendarModule, FullCalendarComponent } from '@fullcalendar/angular';
import type { CalendarOptions, EventApi, EventInput } from '@fullcalendar/core';
import type { EventClickArg, DateSelectArg } from '@fullcalendar/core';
import timeGridPlugin from '@fullcalendar/timegrid';
import dayGridPlugin from '@fullcalendar/daygrid';
import interactionPlugin from '@fullcalendar/interaction';
import listPlugin from '@fullcalendar/list';
import frLocale from '@fullcalendar/core/locales/fr';
import { CourseApiService } from '../../services/course-api.service';
import { CoachApiService } from '../../services/coach-api.service';
import { ToastService } from '../../services/toast.service';
import { CourseDTO, CoachDTO } from '../../models/api.models';

type CourseType = 'yoga' | 'crossfit' | 'powerlifting' | 'cardio';

const DAY_OF_WEEK_FC: Record<string, number> = {
  MONDAY: 1, TUESDAY: 2, WEDNESDAY: 3, THURSDAY: 4,
  FRIDAY: 5, SATURDAY: 6, SUNDAY: 0,
};

const DAY_ENUM = ['SUNDAY', 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY'];

const TYPE_COLORS: Record<string, string> = {
  yoga:         '#9333ea',
  crossfit:     '#f97316',
  powerlifting: '#ef4444',
  cardio:       '#3b82f6',
};

const PLUGINS = [timeGridPlugin, dayGridPlugin, interactionPlugin, listPlugin];

@Component({
  selector: 'app-course-calendar',
  standalone: true,
  imports: [CommonModule, FormsModule, FullCalendarModule],
  templateUrl: './course-calendar.component.html',
  styleUrl: './course-calendar.component.css',
})
export class CourseCalendarComponent implements OnInit, AfterViewInit {
  @ViewChild('fcEl') fcComponent?: FullCalendarComponent;

  private courseApi = inject(CourseApiService);
  private coachApi  = inject(CoachApiService);
  private toast     = inject(ToastService);

  typeFilter = input<string>('all');

  allEvents     = signal<EventInput[]>([]);
  isLoading     = signal(true);
  selectedEvent = signal<EventApi | null>(null);
  showNewModal  = signal(false);
  showEditModal = signal(false);
  isProcessing  = signal(false);

  editForm = {
    name: '', coachId: null as number | null, dayOfWeek: 'MONDAY',
    timeStart: '08:00', timeEnd: '09:00', capacity: 15,
  };

  coaches = signal<CoachDTO[]>([]);
  isLoadingCoaches = signal(false);

  newForm = {
    name: '', coachId: null as number | null, type: 'yoga' as CourseType,
    timeStart: '08:00', timeEnd: '09:00', capacity: 15,
    level: 'Tous niveaux', dayOfWeek: 'MONDAY',
  };

  calendarOptions = computed((): CalendarOptions => {
    const filter = this.typeFilter();
    const events = filter === 'all'
      ? this.allEvents()
      : this.allEvents().filter(e => (e as any)['extendedProps']?.courseType === filter);

    return {
      plugins:      PLUGINS,
      initialView:  'timeGridWeek',
      locale:       frLocale,
      slotMinTime:  '06:00:00',
      slotMaxTime:  '23:00:00',
      nowIndicator: true,
      selectable:   true,
      selectMirror: true,
      editable:     false,
      weekends:     true,
      allDaySlot:   false,
      headerToolbar: {
        left:   'prev,next today',
        center: 'title',
        right:  'timeGridWeek,timeGridDay,listWeek',
      },
      slotDuration:      '00:30:00',
      slotLabelInterval: '01:00:00',
      slotLabelFormat:   { hour: '2-digit', minute: '2-digit', hour12: false } as any,
      eventTimeFormat:   { hour: '2-digit', minute: '2-digit', hour12: false } as any,
      height:  'auto',
      events,
      eventClick:  (info: EventClickArg) => this._onEventClick(info),
      select:      (info: DateSelectArg) => this._onSlotSelect(info),
    };
  });

  ngOnInit() {
    this.loadCourses();
    this.loadCoaches();
  }

  ngAfterViewInit() {}

  private _buildEvents(list: CourseDTO[]): EventInput[] {
    return list.map((c: CourseDTO) => ({
      id:          String(c.id),
      title:       c.name,
      daysOfWeek:  [DAY_OF_WEEK_FC[c.dayOfWeek] ?? 1],
      startTime:   c.startTime?.slice(0, 5) ?? '08:00',
      endTime:     c.endTime?.slice(0, 5)   ?? '09:00',
      startRecur:  '2020-01-01',
      backgroundColor: TYPE_COLORS[this._inferType(c.name)] ?? '#D4A017',
      borderColor:     'transparent',
      textColor:       '#fff',
      extendedProps: {
        courseType: this._inferType(c.name),
        coach:      c.coachName ?? '—',
        enrolled:   c.currentParticipants ?? 0,
        capacity:   c.maxParticipants,
        level:      'Tous niveaux',
        dayOfWeek:  c.dayOfWeek,
        startTime:  c.startTime?.slice(0, 5) ?? '08:00',
        endTime:    c.endTime?.slice(0, 5)   ?? '09:00',
      },
    }));
  }

  private _applyEventsToCalendar(events: EventInput[]) {
    const api = this.fcComponent?.getApi();
    if (api) {
      api.removeAllEvents();
      events.forEach(e => api.addEvent(e as any));
    } else {
      this.allEvents.set(events);
    }
  }

  loadCourses(refresh = false) {
    if (!refresh) this.isLoading.set(true);
    this.courseApi.getAll().subscribe({
      next: (page) => {
        const list = page.content || [];
        const events = list.length ? this._buildEvents(list) : this._mockEvents();
        this.allEvents.set(events);
        if (refresh) {
          this._applyEventsToCalendar(events);
        } else {
          this.isLoading.set(false);
        }
      },
      error: () => {
        const mock = this._mockEvents();
        this.allEvents.set(mock);
        if (refresh) {
          this._applyEventsToCalendar(mock);
        } else {
          this.isLoading.set(false);
        }
      },
    });
  }

  loadCoaches() {
    this.isLoadingCoaches.set(true);
    this.coachApi.getAll().subscribe({
      next: (res) => {
        this.coaches.set(res.content || []);
        this.isLoadingCoaches.set(false);
      },
      error: () => {
        this.isLoadingCoaches.set(false);
        this.toast.error('Erreur', 'Impossible de charger les coachs.');
      }
    });
  }

  openNewCourse() {
    this.newForm = {
      name: '', coachId: this.coaches().length > 0 ? this.coaches()[0].id : null, type: 'yoga',
      timeStart: '08:00', timeEnd: '09:00', capacity: 15,
      level: 'Tous niveaux', dayOfWeek: 'MONDAY',
    };
    this.showNewModal.set(true);
  }

  saveNewCourse() {
    if (!this.newForm.name.trim() || !this.newForm.coachId || this.isProcessing()) {
      if (!this.newForm.coachId && this.newForm.name.trim()) {
        this.toast.error('Champ requis', 'Veuillez sélectionner un coach.');
      }
      return;
    }
    this.isProcessing.set(true);

    this.courseApi.create({
      name:            this.newForm.name.trim(),
      coachId:         this.newForm.coachId,
      dayOfWeek:       this.newForm.dayOfWeek,
      startTime:       this.newForm.timeStart,
      endTime:         this.newForm.timeEnd,
      maxParticipants: this.newForm.capacity,
    }).subscribe({
      next: (created) => {
        this.toast.success('Cours créé', `${created.name} ajouté au planning.`);
        this.isProcessing.set(false);
        this.showNewModal.set(false);
        this.loadCourses(true);
      },
      error: () => {
        this.isProcessing.set(false);
        this.toast.error('Erreur', 'Impossible de créer le cours.');
      },
    });
  }

  closeDetail() { this.selectedEvent.set(null); }

  openEditModal() {
    const evt = this.selectedEvent();
    if (!evt) return;
    this.editForm = {
      name:       evt.title,
      coachId:    evt.extendedProps['coachId'] ?? null,
      dayOfWeek:  evt.extendedProps['dayOfWeek'] ?? 'MONDAY',
      timeStart:  evt.extendedProps['startTime'] ?? '08:00',
      timeEnd:    evt.extendedProps['endTime']   ?? '09:00',
      capacity:   evt.extendedProps['capacity']  ?? 15,
    };
    this.showEditModal.set(true);
  }

  saveEdit() {
    const evt = this.selectedEvent();
    if (!evt || this.isProcessing()) return;
    const id = Number(evt.id);
    this.isProcessing.set(true);
    const updatePayload: Partial<CourseDTO> = {
      name:            this.editForm.name.trim(),
      dayOfWeek:       this.editForm.dayOfWeek,
      startTime:       this.editForm.timeStart,
      endTime:         this.editForm.timeEnd,
      maxParticipants: this.editForm.capacity,
    };
    if (this.editForm.coachId != null) updatePayload['coachId'] = this.editForm.coachId;
    this.courseApi.update(id, updatePayload).subscribe({
      next: () => {
        this.toast.success('Cours modifié', `${this.editForm.name} mis à jour.`);
        this.isProcessing.set(false);
        this.showEditModal.set(false);
        this.closeDetail();
        this.loadCourses(true);
      },
      error: () => {
        this.isProcessing.set(false);
        this.toast.error('Erreur', 'Impossible de modifier le cours.');
      },
    });
  }

  cancelCourse() {
    const evt = this.selectedEvent();
    if (!evt || this.isProcessing()) return;
    const id = Number(evt.id);
    this.isProcessing.set(true);
    this.courseApi.update(id, { active: false }).subscribe({
      next: () => {
        this.toast.success('Cours annulé', `${evt.title} a été annulé.`);
        this.isProcessing.set(false);
        this.closeDetail();
        this.loadCourses(true);
      },
      error: () => {
        this.isProcessing.set(false);
        this.toast.error('Erreur', 'Impossible d\'annuler le cours.');
      },
    });
  }

  deleteCourse() {
    const evt = this.selectedEvent();
    if (!evt || this.isProcessing()) return;
    const id = Number(evt.id);
    this.isProcessing.set(true);
    this.courseApi.delete(id).subscribe({
      next: () => {
        this.toast.success('Cours supprimé', `${evt.title} a été supprimé.`);
        this.isProcessing.set(false);
        this.closeDetail();
        this.loadCourses(true);
      },
      error: () => {
        this.isProcessing.set(false);
        this.toast.error('Erreur', 'Impossible de supprimer le cours.');
      },
    });
  }

  getTypeLabel(type: string): string {
    return ({ yoga: 'Yoga', crossfit: 'CrossFit', powerlifting: 'Powerlifting', cardio: 'Cardio' } as any)[type] ?? type;
  }

  getTypeIcon(type: string): string {
    return ({
      yoga:         'fas fa-om text-purple-400',
      crossfit:     'fas fa-fire text-orange-400',
      powerlifting: 'fas fa-dumbbell text-red-400',
      cardio:       'fas fa-heartbeat text-blue-400',
    } as any)[type] ?? 'fas fa-running text-gray-400';
  }

  readonly DAY_LABELS = [
    { value: 'MONDAY',    label: 'Lundi'    },
    { value: 'TUESDAY',   label: 'Mardi'    },
    { value: 'WEDNESDAY', label: 'Mercredi' },
    { value: 'THURSDAY',  label: 'Jeudi'    },
    { value: 'FRIDAY',    label: 'Vendredi' },
    { value: 'SATURDAY',  label: 'Samedi'   },
    { value: 'SUNDAY',    label: 'Dimanche' },
  ];

  private _onEventClick(info: EventClickArg) {
    this.selectedEvent.set(info.event);
  }

  private _onSlotSelect(info: DateSelectArg) {
    const dow = DAY_ENUM[info.start.getDay()];
    const hhmm = (d: Date) => d.toTimeString().slice(0, 5);
    this.newForm = {
      name: '', coachId: this.coaches().length > 0 ? this.coaches()[0].id : null, type: 'yoga',
      timeStart: hhmm(info.start),
      timeEnd:   hhmm(info.end),
      capacity: 15, level: 'Tous niveaux',
      dayOfWeek: dow,
    };
    this.showNewModal.set(true);
  }

  private _inferType(name: string): CourseType {
    const n = name.toLowerCase();
    if (n.includes('yoga')) return 'yoga';
    if (n.includes('crossfit') || n.includes('cross')) return 'crossfit';
    if (n.includes('power') || n.includes('lifting')) return 'powerlifting';
    return 'cardio';
  }

  private _mockEvents(): EventInput[] {
    const raw = [
      { id: 'C-001', name: 'Yoga Premium Flow',     coach: 'Elena R.',  day: 'MONDAY',    s: '08:00', e: '09:30', t: 'yoga'         as CourseType, cap: 15, enr: 15 },
      { id: 'C-002', name: 'Powerlifting Elite VIP', coach: 'Marcus T.', day: 'MONDAY',    s: '10:00', e: '11:15', t: 'powerlifting' as CourseType, cap: 8,  enr: 6  },
      { id: 'C-003', name: 'HIIT Cardio Blast',      coach: 'Sarah J.',  day: 'MONDAY',    s: '12:30', e: '13:15', t: 'cardio'       as CourseType, cap: 25, enr: 22 },
      { id: 'C-004', name: 'CrossFit WOD Elite',     coach: 'David B.',  day: 'MONDAY',    s: '18:00', e: '19:00', t: 'crossfit'     as CourseType, cap: 20, enr: 18 },
      { id: 'C-011', name: 'CrossFit Morning',       coach: 'David B.',  day: 'TUESDAY',   s: '07:00', e: '08:00', t: 'crossfit'     as CourseType, cap: 20, enr: 14 },
      { id: 'C-012', name: 'Cardio Endurance',       coach: 'Sarah J.',  day: 'TUESDAY',   s: '09:30', e: '10:30', t: 'cardio'       as CourseType, cap: 30, enr: 25 },
      { id: 'C-021', name: 'Yoga Vinyasa',           coach: 'Elena R.',  day: 'WEDNESDAY', s: '08:30', e: '10:00', t: 'yoga'         as CourseType, cap: 15, enr: 9  },
      { id: 'C-022', name: 'HIIT Full Body',         coach: 'Sarah J.',  day: 'WEDNESDAY', s: '12:00', e: '12:45', t: 'cardio'       as CourseType, cap: 25, enr: 21 },
      { id: 'C-031', name: 'Powerlifting Débutant',  coach: 'Marcus T.', day: 'THURSDAY',  s: '09:00', e: '10:15', t: 'powerlifting' as CourseType, cap: 8,  enr: 5  },
      { id: 'C-032', name: 'Cardio Boxing',          coach: 'Sarah J.',  day: 'THURSDAY',  s: '11:30', e: '12:30', t: 'cardio'       as CourseType, cap: 20, enr: 18 },
      { id: 'C-041', name: 'HIIT Cardio Express',    coach: 'Sarah J.',  day: 'FRIDAY',    s: '07:30', e: '08:15', t: 'cardio'       as CourseType, cap: 25, enr: 20 },
      { id: 'C-042', name: 'Yoga Flow Dynamique',    coach: 'Elena R.',  day: 'FRIDAY',    s: '10:00', e: '11:30', t: 'yoga'         as CourseType, cap: 15, enr: 15 },
      { id: 'C-051', name: 'CrossFit Open',          coach: 'David B.',  day: 'SATURDAY',  s: '09:00', e: '10:30', t: 'crossfit'     as CourseType, cap: 25, enr: 23 },
      { id: 'C-052', name: 'Yoga Méditation',        coach: 'Elena R.',  day: 'SATURDAY',  s: '11:00', e: '12:00', t: 'yoga'         as CourseType, cap: 20, enr: 16 },
      { id: 'C-061', name: 'Yoga Restauratif',       coach: 'Elena R.',  day: 'SUNDAY',    s: '09:00', e: '10:30', t: 'yoga'         as CourseType, cap: 15, enr: 10 },
      { id: 'C-062', name: 'CrossFit Récup',         coach: 'David B.',  day: 'SUNDAY',    s: '11:00', e: '12:00', t: 'crossfit'     as CourseType, cap: 15, enr: 7  },
    ];
    return raw.map(c => ({
      id:          c.id,
      title:       c.name,
      daysOfWeek:  [DAY_OF_WEEK_FC[c.day]],
      startTime:   c.s,
      endTime:     c.e,
      startRecur:  '2020-01-01',
      backgroundColor: TYPE_COLORS[c.t],
      borderColor:     'transparent',
      textColor:       '#fff',
      extendedProps: {
        courseType: c.t,
        coach:      c.coach,
        enrolled:   c.enr,
        capacity:   c.cap,
        level:      'Tous niveaux',
        dayOfWeek:  c.day,
        startTime:  c.s,
        endTime:    c.e,
      },
    }));
  }
}
