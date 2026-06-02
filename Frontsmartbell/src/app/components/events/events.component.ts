import { Component, OnInit, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { EventApiService } from '../../services/event-api.service';
import { EventDTO, EventRegistrationDTO } from '../../models/api.models';
import { ToastService } from '../../services/toast.service';

@Component({
  selector: 'app-events',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './events.component.html',
  styleUrl: './events.component.css'
})
export class EventsComponent implements OnInit {
  private eventApi = inject(EventApiService);
  private toast    = inject(ToastService);

  events = signal<EventDTO[]>([]);
  loading = signal(true);
  
  // Filters
  filter = signal<'ALL' | 'UPCOMING' | 'PAST' | 'FULL'>('ALL');

  // Modals
  showCreateModal = signal(false);
  showRegistrationsModal = signal(false);
  isEditing = signal(false);
  selectedEvent = signal<EventDTO | null>(null);
  registrations = signal<EventRegistrationDTO[]>([]);

  // Date validation touched state
  dateStartTouched = signal(false);
  dateEndTouched   = signal(false);

  // Form
  eventForm = signal<Partial<EventDTO>>({
    title: '',
    description: '',
    eventDate: '',
    endDate: '',
    location: '',
    maxParticipants: 10,
    imageUrl: '',
    active: true
  });

  filteredEvents = computed(() => {
    let list = this.events();
    const now = new Date();

    if (this.filter() === 'UPCOMING') {
      list = list.filter(e => new Date(e.eventDate) > now);
    } else if (this.filter() === 'PAST') {
      list = list.filter(e => new Date(e.eventDate) < now);
    } else if (this.filter() === 'FULL') {
      list = list.filter(e => (e.registrationCount || 0) >= e.maxParticipants);
    }

    return list.sort((a, b) => new Date(a.eventDate).getTime() - new Date(b.eventDate).getTime());
  });

  stats = computed(() => {
    const all = this.events();
    const now = new Date();
    const totalInscribed = all.reduce((acc, curr) => acc + (curr.registrationCount || 0), 0);
    const totalMax = all.reduce((acc, curr) => acc + curr.maxParticipants, 0);

    return {
      active: all.filter(e => e.active).length,
      upcoming: all.filter(e => new Date(e.eventDate) > now).length,
      totalRegistrations: totalInscribed,
      avgFillRate: totalMax > 0 ? Math.round((totalInscribed / totalMax) * 100) : 0
    };
  });

  // ── Date validation ─────────────────────────────────────────────────────────

  get minDateTime(): string {
    const now = new Date();
    now.setMinutes(now.getMinutes() + 30);
    return now.toISOString().slice(0, 16);
  }

  getStartDateError(): string | null {
    const val = this.eventForm().eventDate as string | undefined;
    if (!val) return 'La date de début est obligatoire';
    if (!this.isEditing() && new Date(val) <= new Date()) {
      return 'La date de début doit être dans le futur';
    }
    return null;
  }

  getEndDateError(): string | null {
    const form = this.eventForm();
    const end  = form.endDate as string | undefined;
    if (!end) return 'La date de fin est obligatoire';
    if (form.eventDate && new Date(end) <= new Date(form.eventDate as string)) {
      return 'La date de fin doit être après la date de début';
    }
    return null;
  }

  isFormDatesValid(): boolean {
    return this.getStartDateError() === null && this.getEndDateError() === null;
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  ngOnInit() {
    this.loadEvents();
  }

  loadEvents() {
    this.loading.set(true);
    this.eventApi.getAll().subscribe({
      next: (res) => {
        this.events.set(res.content);
        this.loading.set(false);
      },
      error: () => {
        console.warn('Events: load failed');
        this.loading.set(false);
      }
    });
  }

  openCreateModal() {
    this.isEditing.set(false);
    this.dateStartTouched.set(false);
    this.dateEndTouched.set(false);
    this.eventForm.set({
      title: '',
      description: '',
      eventDate: '',
      endDate: '',
      location: '',
      maxParticipants: 10,
      imageUrl: '',
      active: true
    });
    this.showCreateModal.set(true);
  }

  openEditModal(event: EventDTO) {
    this.isEditing.set(true);
    this.dateStartTouched.set(false);
    this.dateEndTouched.set(false);
    this.selectedEvent.set(event);
    this.eventForm.set({ ...event });
    this.showCreateModal.set(true);
  }

  saveEvent() {
    this.dateStartTouched.set(true);
    this.dateEndTouched.set(true);
    if (!this.isFormDatesValid()) return;

    if (this.isEditing() && this.selectedEvent()) {
      this.eventApi.update(this.selectedEvent()!.id, this.eventForm()).subscribe({
        next: (updated) => {
          this.events.update(list => list.map(e => e.id === updated.id ? updated : e));
          this.toast.success('Succès', 'Événement mis à jour');
          this.showCreateModal.set(false);
        },
        error: () => this.toast.error('Erreur', 'Mise à jour échouée')
      });
    } else {
      this.eventApi.create(this.eventForm()).subscribe({
        next: (created) => {
          this.events.update(list => [...list, created]);
          this.toast.success('Succès', 'Événement créé');
          this.showCreateModal.set(false);
        },
        error: () => this.toast.error('Erreur', 'Création échouée')
      });
    }
  }

  deleteEvent(id: number) {
    if (!confirm('Supprimer cet événement ?')) return;
    this.eventApi.delete(id).subscribe({
      next: () => {
        this.events.update(list => list.filter(e => e.id !== id));
        this.toast.success('Succès', 'Événement supprimé');
      },
      error: () => this.toast.error('Erreur', 'Suppression échouée')
    });
  }

  viewRegistrations(event: EventDTO) {
    this.selectedEvent.set(event);
    this.eventApi.getRegistrations(event.id).subscribe({
      next: (data) => {
        this.registrations.set(data);
        this.showRegistrationsModal.set(true);
      },
      error: () => this.toast.error('Erreur', 'Impossible de charger les inscrits')
    });
  }

  getEventImage(event: EventDTO): string {
    const title = (event.title ?? '').toLowerCase();
    const desc  = (event.description ?? '').toLowerCase();
    const text  = title + ' ' + desc;
    if (text.includes('padel') || text.includes('tennis'))
      return 'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=600&q=80&fit=crop';
    if (text.includes('yoga') || text.includes('méditation') || text.includes('stretching'))
      return 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=600&q=80&fit=crop';
    if (text.includes('nutrition') || text.includes('diète') || text.includes('séminaire') || text.includes('conference') || text.includes('conférence'))
      return 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=600&q=80&fit=crop';
    if (text.includes('crossfit') || text.includes('wod') || text.includes('circuit'))
      return 'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=600&q=80&fit=crop';
    if (text.includes('boxe') || text.includes('combat') || text.includes('arts martiaux') || text.includes('mma'))
      return 'https://images.unsplash.com/photo-1555597673-b21d5c935865?w=600&q=80&fit=crop';
    if (text.includes('natation') || text.includes('piscine') || text.includes('aqua'))
      return 'https://images.unsplash.com/photo-1530549387789-4c1017266635?w=600&q=80&fit=crop';
    if (text.includes('cyclisme') || text.includes('vélo') || text.includes('spinning'))
      return 'https://images.unsplash.com/photo-1534787238916-9ba6764efd4f?w=600&q=80&fit=crop';
    if (text.includes('course') || text.includes('marathon') || text.includes('running'))
      return 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=600&q=80&fit=crop';
    if (text.includes('tournoi') || text.includes('compétition') || text.includes('championnat'))
      return 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=600&q=80&fit=crop';
    if (text.includes('musculation') || text.includes('powerlifting') || text.includes('haltère'))
      return 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600&q=80&fit=crop';
    // Default sport gym image
    return 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=600&q=80&fit=crop';
  }

  getEventStatus(event: EventDTO): 'upcoming' | 'past' | 'full' {
    const now = new Date();
    if ((event.registrationCount || 0) >= event.maxParticipants) return 'full';
    if (new Date(event.eventDate) < now) return 'past';
    return 'upcoming';
  }

  getFillPercentage(event: EventDTO): number {
    return Math.round(((event.registrationCount || 0) / event.maxParticipants) * 100);
  }

  formatDate(dateStr: string): string {
    const date = new Date(dateStr);
    const options: Intl.DateTimeFormatOptions = {
      weekday: 'short',
      day: 'numeric',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    };
    return date.toLocaleDateString('fr-FR', options).replace(',', ' à');
  }
}
