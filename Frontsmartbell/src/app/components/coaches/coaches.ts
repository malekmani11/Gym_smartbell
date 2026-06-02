import { Component, signal, computed, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ToastService } from '../../services/toast.service';
import { CoachApiService } from '../../services/coach-api.service';
import { CoachRatingService } from '../../services/coach-rating.service';
import { AuthService } from '../../services/auth.service';

type Specialization =
  | 'BODYBUILDING' | 'YOGA' | 'PILATES' | 'CROSSFIT'
  | 'HIIT' | 'CARDIO' | 'NUTRITION' | 'STRETCHING' | 'FUNCTIONAL';

const SPECIALIZATION_LABELS: Record<Specialization, string> = {
  BODYBUILDING: 'Musculation',
  YOGA:         'Yoga',
  PILATES:      'Pilates',
  CROSSFIT:     'CrossFit',
  HIIT:         'HIIT',
  CARDIO:       'Cardio',
  NUTRITION:    'Nutrition',
  STRETCHING:   'Stretching',
  FUNCTIONAL:   'Entraînement fonctionnel',
};

const SPECIALIZATIONS = Object.keys(SPECIALIZATION_LABELS) as Specialization[];

interface Coach {
  id: string;
  rawId: number;
  userId?: number;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  avatar: string;
  specialty: string;
  specialization?: Specialization;
  status: 'active' | 'inactive' | 'away';
  hireDate: Date;
  profileImageUrl?: string;
  ratingAvg?: number;
  enabled?: boolean;
}

@Component({
  selector: 'app-coaches',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './coaches.html',
  styleUrl: './coaches.css'
})
export class Coaches implements OnInit {
  private toast       = inject(ToastService);
  private coachApi    = inject(CoachApiService);
  private ratingApi   = inject(CoachRatingService);
  private auth        = inject(AuthService);

  ngOnInit() {
    this.loadCoaches();
  }

  loadCoaches() {
    this.loading.set(true);
    this.loadError.set(null);
    this.coachApi.getAll().subscribe({
      next: (response) => {
        const list = response.content || [];
        const mapped = list.map((c: any) => ({
          id:              `C-${String(c.id).padStart(3, '0')}`,
          rawId:           c.id,
          firstName:       c.firstName || '',
          lastName:        c.lastName  || '',
          email:           c.email     || '',
          phone:           c.phone     || '—',
          avatar:          c.profileImageUrl || `https://i.pravatar.cc/150?u=coach${c.id}`,
          specialization:  c.specialization  as Specialization | undefined,
          specialty:       c.specialization ? (SPECIALIZATION_LABELS[c.specialization as Specialization] ?? c.specialization) : 'Non défini',
          status:          this.mapAvailabilityStatus(c.availabilityStatus),
          hireDate:        c.hireDate ? new Date(c.hireDate) : new Date(),
          profileImageUrl: c.profileImageUrl,
          ratingAvg:       c.ratingAvg ?? 0,
          userId:          c.userId ?? c.id,
          enabled:         c.enabled !== false,
        }));
        this.coachesList.set(mapped);
        this.loading.set(false);
      },
      error: (err) => {
        console.error('Erreur chargement coachs:', err);
        this.loadError.set(err.error?.message || `Erreur ${err.status || 'réseau'} — impossible de charger les coachs.`);
        this.loading.set(false);
      }
    });
  }

  private mapAvailabilityStatus(status?: string): Coach['status'] {
    switch (status) {
      case 'AVAILABLE':   return 'active';
      case 'UNAVAILABLE': return 'inactive';
      case 'ON_LEAVE':    return 'away';
      default:            return 'active';
    }
  }

  loading         = signal(false);
  loadError       = signal<string | null>(null);

  showAddModal    = signal(false);
  isProcessing    = signal(false);
  selectedCoach   = signal<Coach | null>(null);

  // ── Coach stats ───────────────────────────────────────
  coachStats = signal<{ totalCourses: number; totalEnrollments: number; activeMembers: number; avgOccupancyRate: number } | null>(null);

  // ── Rating state ──────────────────────────────────────
  ratingAvg            = signal<number>(0);
  ratingCount          = signal<number>(0);
  selectedStars        = signal<number>(0);
  hoverStars           = signal<number>(0);
  ratingComment        = signal<string>('');
  hasRated             = signal<boolean>(false);
  isSubmittingRating   = signal<boolean>(false);
  ratingLoading        = signal<boolean>(false);

  /** Étoiles affichées = hover si actif, sinon sélection */
  displayStars = computed(() => this.hoverStars() || this.selectedStars());

  viewCoach(coach: Coach) {
    this.selectedCoach.set(coach);
    this.loadRatingData(coach.rawId);
    this.loadCoachStats(coach.rawId);
  }

  closeCoachProfile() {
    this.selectedCoach.set(null);
    this.coachStats.set(null);
    this.resetRatingState();
  }

  toggleAccountStatus(coach: Coach) {
    if (!coach.userId || this.isProcessing()) return;
    const newEnabled = !coach.enabled;
    this.isProcessing.set(true);
    this.coachApi.toggleStatus(coach.userId, newEnabled).subscribe({
      next: () => {
        this.coachesList.update(list =>
          list.map(c => c.rawId === coach.rawId ? { ...c, enabled: newEnabled } : c)
        );
        this.selectedCoach.update(c => c ? { ...c, enabled: newEnabled } : c);
        const action = newEnabled ? 'réactivé' : 'désactivé';
        this.toast.success(`Compte ${action}`, `${coach.firstName} ${coach.lastName}`);
        this.isProcessing.set(false);
      },
      error: () => {
        this.toast.error('Erreur', 'Impossible de modifier le statut du compte.');
        this.isProcessing.set(false);
      }
    });
  }

  loadCoachStats(coachId: number) {
    this.coachApi.getStats(coachId).subscribe({
      next: (stats) => this.coachStats.set(stats),
      error: () => this.coachStats.set(null),
    });
  }

  private resetRatingState() {
    this.ratingAvg.set(0);
    this.ratingCount.set(0);
    this.selectedStars.set(0);
    this.hoverStars.set(0);
    this.ratingComment.set('');
    this.hasRated.set(false);
    this.isSubmittingRating.set(false);
  }

  loadRatingData(coachId: number) {
    this.ratingLoading.set(true);
    const currentUserId = this.auth.currentUserId();

    // Charger la moyenne
    this.ratingApi.getAverageRating(coachId).subscribe({
      next: (avg) => this.ratingAvg.set(avg ?? 0),
      error: () => {}
    });

    // Charger la liste pour compter et détecter si l'utilisateur a déjà noté
    this.ratingApi.getCoachRatings(coachId).subscribe({
      next: (ratings) => {
        this.ratingCount.set(ratings.length);
        if (currentUserId) {
          const userRating = ratings.find(r => r.memberId === currentUserId);
          if (userRating) {
            this.hasRated.set(true);
            this.selectedStars.set(userRating.rating);
            this.ratingComment.set(userRating.comment ?? '');
          }
        }
        this.ratingLoading.set(false);
      },
      error: () => { this.ratingLoading.set(false); }
    });
  }

  setHoverStars(n: number)  { if (!this.hasRated()) this.hoverStars.set(n); }
  clearHover()              { this.hoverStars.set(0); }
  selectStar(n: number)     { if (!this.hasRated()) this.selectedStars.set(n); }

  starLabel(n: number): string {
    const labels = ['', 'Mauvais', 'Passable', 'Correct', 'Bien', 'Excellent'];
    return labels[n] ?? '';
  }

  submitRating() {
    const stars = this.selectedStars();
    if (stars < 1 || stars > 5) {
      this.toast.error('Note requise', 'Veuillez sélectionner une note entre 1 et 5 étoiles.');
      return;
    }
    const coach = this.selectedCoach();
    if (!coach) return;

    this.isSubmittingRating.set(true);
    this.ratingApi.rateCoach(coach.rawId, {
      rating:  stars,
      comment: this.ratingComment().trim() || undefined,
    }).subscribe({
      next: () => {
        this.hasRated.set(true);
        this.isSubmittingRating.set(false);
        // Recharger la vraie moyenne depuis le backend
        this.ratingApi.getAverageRating(coach.rawId).subscribe({
          next: (avg) => {
            this.ratingAvg.set(avg ?? 0);
            this.coachesList.update(list =>
              list.map(c => c.rawId === coach.rawId ? { ...c, ratingAvg: avg } : c)
            );
          },
          error: () => {}
        });
        this.ratingCount.update(n => n + 1);
        this.toast.success('Note soumise', 'Merci pour votre évaluation !');
      },
      error: (err) => {
        this.isSubmittingRating.set(false);
        const msg = err.error?.message || 'Impossible de soumettre la note.';
        if (msg.includes('déjà')) {
          this.hasRated.set(true);
        }
        this.toast.error('Erreur', msg);
      }
    });
  }

  /** 5 étoiles SVG : retourne tableau [true/false] selon la note */
  starFill(rating: number): boolean[] {
    return Array.from({ length: 5 }, (_, i) => i < Math.round(rating));
  }

  /** Années d'expérience depuis la date d'embauche */
  yearsExp(coach: Coach): number {
    return Math.max(1, new Date().getFullYear() - coach.hireDate.getFullYear());
  }

  editingCoach = signal<Coach | null>(null);

  editCoach(coach: Coach) {
    this.editingCoach.set({ ...coach });
  }

  closeEditModal() {
    this.editingCoach.set(null);
  }

  updateEditField(patch: Partial<Coach>) {
    this.editingCoach.update(c => c ? { ...c, ...patch } : c);
  }

  deleteCoach(id: string) {
    const coach = this.coachesList().find(c => c.id === id);
    if (!coach) return;

    const confirmed = confirm(
      `Supprimer ${coach.firstName} ${coach.lastName} ?\nCette action est irréversible.`
    );
    if (!confirmed) return;

    this.coachApi.delete(coach.rawId).subscribe({
      next: () => {
        this.coachesList.update(list => list.filter(c => c.id !== id));
        this.toast.success('Coach supprimé', `${coach.firstName} ${coach.lastName} a été retiré de l'équipe.`);
      },
      error: (err) => {
        this.toast.error('Erreur', err.error?.message || 'Impossible de supprimer le coach.');
      }
    });
  }

  saveCoach() {
    const edited = this.editingCoach();
    if (!edited) return;

    const statusMap: Record<string, string> = {
      'active':   'AVAILABLE',
      'inactive': 'UNAVAILABLE',
      'away':     'ON_LEAVE',
    };

    this.coachApi.update(edited.rawId, {
      firstName:          edited.firstName,
      lastName:           edited.lastName,
      email:              edited.email,
      phone:              edited.phone,
      specialization:     edited.specialization,
      profileImageUrl:    edited.profileImageUrl,
      availabilityStatus: (statusMap[edited.status] ?? 'AVAILABLE') as any,
    }).subscribe({
      next: () => {
        this.loadCoaches();
        this.editingCoach.set(null);
        this.toast.success('Coach mis à jour', 'Les modifications ont été enregistrées.');
      },
      error: (err) => {
        this.toast.error('Erreur', err.error?.message || 'Impossible de mettre à jour le coach.');
      }
    });
  }

  newCoachForm = signal({
    firstName: '',
    lastName: '',
    email: '',
    password: '',
    phone: '',
    specialty: '' as Specialization | '',
    status: 'active' as Coach['status'],
    photoUrl: '',
  });

  openAddModal() {
    this.newCoachForm.set({ firstName: '', lastName: '', email: '', password: '', phone: '', specialty: '', status: 'active', photoUrl: '' });
    this.showAddModal.set(true);
  }

  closeAddModal() {
    this.newCoachForm.set({ firstName: '', lastName: '', email: '', password: '', phone: '', specialty: '', status: 'active', photoUrl: '' });
    this.showAddModal.set(false);
  }

  updateForm(patch: Partial<{ firstName: string; lastName: string; email: string; password: string; phone: string; specialty: Specialization | ''; status: Coach['status']; photoUrl: string }>) {
    this.newCoachForm.update(f => ({ ...f, ...patch }));
  }

  addCoach() {
    const f = this.newCoachForm();

    if (!f.firstName.trim() || !f.lastName.trim() || !f.email.trim() || !f.password.trim()) {
      this.toast.error('Champs requis', 'Prénom, nom, email et mot de passe sont obligatoires.');
      return;
    }
    if (f.password.trim().length < 6) {
      this.toast.error('Mot de passe trop court', 'Le mot de passe doit contenir au moins 6 caractères.');
      return;
    }

    this.isProcessing.set(true);

    this.coachApi.register({
      firstName:      f.firstName.trim(),
      lastName:       f.lastName.trim(),
      email:          f.email.trim(),
      password:       f.password.trim(),
      phone:          f.phone.trim() || undefined,
      specialization: f.specialty || undefined,
    }).subscribe({
      next: (created) => {
        this.loadCoaches();
        this.isProcessing.set(false);
        this.closeAddModal();
        this.toast.success('Coach ajouté', `${created.firstName} ${created.lastName} a rejoint l'équipe.`);
      },
      error: (err) => {
        this.isProcessing.set(false);
        const body = err.error;
        if (err.status === 400) {
          if (body?.validationErrors?.length) {
            this.toast.error('Données invalides', body.validationErrors[0]);
          } else if (body?.message?.includes('déjà')) {
            this.toast.error('Email déjà utilisé', 'Un compte avec cet email existe déjà.');
          } else {
            this.toast.error('Erreur 400', body?.message || 'Requête invalide.');
          }
        } else {
          this.toast.error(`Erreur ${err.status}`, body?.message || 'Impossible d\'ajouter le coach.');
        }
      }
    });
  }

  isAdmin = computed(() => this.auth.isAdmin());

  readonly specializations = SPECIALIZATIONS;
  readonly specializationLabels = SPECIALIZATION_LABELS;

  specializationLabel(s?: string): string {
    return s ? (SPECIALIZATION_LABELS[s as Specialization] ?? s) : 'Non défini';
  }

  searchQuery   = signal('');
  filterStatus  = signal<'all' | 'active' | 'inactive' | 'away'>('all');

  totalCoaches      = computed(() => this.coachesList().length);
  activeCoaches     = computed(() => this.coachesList().filter(c => c.status === 'active').length);
  awayCoaches       = computed(() => this.coachesList().filter(c => c.status === 'away').length);
  uniqueSpecialties = computed(() => new Set(this.coachesList().map(c => c.specialty)).size);

  filteredCoaches = computed(() => {
    const q      = this.searchQuery().toLowerCase().trim();
    const status = this.filterStatus();
    return this.coachesList().filter(c => {
      const matchesSearch = !q ||
        c.firstName.toLowerCase().includes(q) ||
        c.lastName.toLowerCase().includes(q)  ||
        c.email.toLowerCase().includes(q)     ||
        c.specialty.toLowerCase().includes(q);
      const matchesStatus = status === 'all' || c.status === status;
      return matchesSearch && matchesStatus;
    });
  });

  coachesList = signal<Coach[]>([]);

  getStatusBadgeClass(status: string): string {
    switch (status) {
      case 'active':   return 'bg-green-500/15 text-green-400 border border-green-500/30';
      case 'inactive': return 'bg-red-500/15 text-red-400 border border-red-500/30';
      case 'away':     return 'bg-yellow-500/15 text-yellow-400 border border-yellow-500/30';
      default:         return 'bg-green-500/15 text-green-400 border border-green-500/30';
    }
  }

  getStatusLabel(status: string): string {
    switch (status) {
      case 'active':   return 'Actif';
      case 'inactive': return 'Inactif';
      case 'away':     return 'Absent';
      default:         return status;
    }
  }
}
