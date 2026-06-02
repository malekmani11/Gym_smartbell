import { Component, signal, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { ToastService } from '../../services/toast.service';
import { environment } from '../../../environments/environment';

interface SeanceAi {
  nom: string;
  exercices: any[];
}

interface AiProgram {
  id: number;
  memberId: number;
  memberFirstName: string;
  memberLastName: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
  seances: SeanceAi[];
  noteCoach: string;
  typeProgramme: string;
  intensite: number;
  split: string;
  imc: number;
  imcCategorie: string;
  coachComment: string | null;
  createdAt: string;
  validatedAt: string | null;
}

@Component({
  selector: 'app-ai-programs',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './ai-programs.component.html',
  styleUrl: './ai-programs.component.css',
})
export class AiProgramsComponent implements OnInit {
  private http  = inject(HttpClient);
  private toast = inject(ToastService);
  private readonly BASE = `${environment.apiUrl}/ai/programs`;

  programs     = signal<AiProgram[]>([]);
  isLoading    = signal(true);
  isProcessing = signal(false);
  statusFilter = signal<'ALL' | 'PENDING' | 'APPROVED' | 'REJECTED'>('PENDING');
  selected     = signal<AiProgram | null>(null);
  comment      = signal('');

  // For demo we use coachId=1; in production retrieve from auth service
  private coachId = 1;

  ngOnInit() { this.load(); }

  load() {
    this.isLoading.set(true);
    const params: any = { };
    if (this.statusFilter() !== 'ALL') params['status'] = this.statusFilter();

    this.http.get<AiProgram[]>(`${this.BASE}/coach/${this.coachId}`, { params }).subscribe({
      next: (list) => { this.programs.set(list); this.isLoading.set(false); },
      error: () => { this.toast.error('Erreur', 'Impossible de charger les programmes.'); this.isLoading.set(false); },
    });
  }

  openProgram(p: AiProgram) {
    this.selected.set(p);
    this.comment.set(p.coachComment ?? '');
  }

  validate(status: 'APPROVED' | 'REJECTED') {
    const p = this.selected();
    if (!p || this.isProcessing()) return;
    this.isProcessing.set(true);
    this.http.put<AiProgram>(`${this.BASE}/${p.id}/validate?coachId=${this.coachId}`, {
      status,
      coachComment: this.comment(),
    }).subscribe({
      next: (updated) => {
        this.toast.success(
          status === 'APPROVED' ? 'Programme approuvé' : 'Programme refusé',
          `${p.memberFirstName} ${p.memberLastName}`
        );
        this.programs.update(list => list.map(x => x.id === updated.id ? updated : x));
        this.selected.set(null);
        this.isProcessing.set(false);
        this.load();
      },
      error: () => { this.toast.error('Erreur', 'Impossible de valider.'); this.isProcessing.set(false); },
    });
  }

  pendingCount()   { return this.programs().filter(p => p.status === 'PENDING').length; }
  approvedCount()  { return this.programs().filter(p => p.status === 'APPROVED').length; }
  rejectedCount()  { return this.programs().filter(p => p.status === 'REJECTED').length; }

  statusLabel(s: string) {
    if (s === 'PENDING')  return 'En attente';
    if (s === 'APPROVED') return 'Approuvé';
    if (s === 'REJECTED') return 'Refusé';
    return s;
  }

  statusColor(s: string) {
    if (s === 'PENDING')  return '#F59E0B';
    if (s === 'APPROVED') return '#10B981';
    if (s === 'REJECTED') return '#EF4444';
    return '#6B7280';
  }
}
