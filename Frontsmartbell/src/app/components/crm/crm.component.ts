import { Component, signal, computed, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { ToastService } from '../../services/toast.service';
import { environment } from '../../../environments/environment';

export type CrmStage = 'PROSPECT' | 'ACTIVE' | 'AT_RISK' | 'CHURNED';

export interface CrmCard {
  memberId: number;
  firstName: string;
  lastName: string;
  email: string;
  membershipType: string;
  membershipStatus: string;
  crmStage: CrmStage;
  joinDate?: string;
  expiryDate?: string;
  daysUntilExpiry?: number;
  lastVisit?: string;
  notes?: string;
}

const STAGE_META: Record<CrmStage, { label: string; color: string; icon: string; border: string }> = {
  PROSPECT: { label: 'Prospects',   color: 'text-blue-400',    icon: 'fas fa-user-plus',    border: 'border-blue-500/25'   },
  ACTIVE:   { label: 'Actifs',      color: 'text-green-400',   icon: 'fas fa-check-circle', border: 'border-green-500/25'  },
  AT_RISK:  { label: 'À risque',    color: 'text-[#D4A017]',   icon: 'fas fa-exclamation-triangle', border: 'border-[#D4A017]/30' },
  CHURNED:  { label: 'Résiliés',    color: 'text-red-400',     icon: 'fas fa-times-circle', border: 'border-red-500/25'    },
};

const MOCK_CARDS: CrmCard[] = [
  { memberId:1,  firstName:'Sophie',   lastName:'Laurent',     email:'sophie.l@email.com',  membershipType:'Yoga Premium',  membershipStatus:'ACTIVE',   crmStage:'ACTIVE',   daysUntilExpiry:45,  joinDate:'2024-01-15' },
  { memberId:2,  firstName:'Lucas',    lastName:'Martin',      email:'lucas.m@email.com',   membershipType:'CrossFit Elite',membershipStatus:'ACTIVE',   crmStage:'ACTIVE',   daysUntilExpiry:60,  joinDate:'2024-02-01' },
  { memberId:3,  firstName:'Emma',     lastName:'Bernard',     email:'emma.b@email.com',    membershipType:'Standard',      membershipStatus:'INACTIVE',  crmStage:'PROSPECT', joinDate:'2024-03-10' },
  { memberId:4,  firstName:'Thomas',   lastName:'Renard',      email:'thomas.r@email.com',  membershipType:'Premium',       membershipStatus:'ACTIVE',   crmStage:'AT_RISK',  daysUntilExpiry:5,   joinDate:'2024-01-01' },
  { memberId:5,  firstName:'Camille',  lastName:'Morin',       email:'camille.m@email.com', membershipType:'Annuel VIP',    membershipStatus:'ACTIVE',   crmStage:'AT_RISK',  daysUntilExpiry:3,   joinDate:'2023-06-01' },
  { memberId:6,  firstName:'Antoine',  lastName:'Faure',       email:'antoine.f@email.com', membershipType:'Standard',      membershipStatus:'SUSPENDED', crmStage:'CHURNED',  daysUntilExpiry:-10, joinDate:'2023-11-01' },
  { memberId:7,  firstName:'Nadia',    lastName:'Ferhat',      email:'nadia.f@email.com',   membershipType:'CrossFit Elite',membershipStatus:'SUSPENDED', crmStage:'CHURNED',  daysUntilExpiry:-20, joinDate:'2023-12-01' },
  { memberId:8,  firstName:'Karim',    lastName:'Aziz',        email:'karim.a@email.com',   membershipType:'Premium',       membershipStatus:'INACTIVE',  crmStage:'PROSPECT', joinDate:'2024-03-20' },
  { memberId:9,  firstName:'Inès',     lastName:'Charpentier', email:'ines.c@email.com',    membershipType:'VIP Elite',     membershipStatus:'ACTIVE',   crmStage:'ACTIVE',   daysUntilExpiry:120, joinDate:'2023-09-01' },
  { memberId:10, firstName:'Omar',     lastName:'Khalil',      email:'omar.k@email.com',    membershipType:'Standard',      membershipStatus:'ACTIVE',   crmStage:'AT_RISK',  daysUntilExpiry:8,   joinDate:'2023-08-01' },
];

@Component({
  selector: 'app-crm',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './crm.component.html',
  styleUrl: './crm.component.css',
})
export class CrmComponent implements OnInit {
  private http  = inject(HttpClient);
  private toast = inject(ToastService);
  private BASE  = `${environment.apiUrl}/crm`;

  readonly stages: CrmStage[]  = ['PROSPECT', 'ACTIVE', 'AT_RISK', 'CHURNED'];
  readonly stageMeta = STAGE_META;

  cards       = signal<CrmCard[]>(MOCK_CARDS);
  isLoading   = signal(false);
  filterStatus= signal('');
  filterType  = signal('');

  // Note modal
  noteCard    = signal<CrmCard | null>(null);
  noteText    = signal('');

  // Drag state
  draggedId   = signal<number | null>(null);

  // ── Filtered pipeline ─────────────────────────────────────────────────────
  filteredCards = computed(() => {
    let list = this.cards();
    const s = this.filterStatus();
    const t = this.filterType();
    if (s) list = list.filter(c => c.membershipStatus === s);
    if (t) list = list.filter(c => c.membershipType.toLowerCase().includes(t.toLowerCase()));
    return list;
  });

  cardsForStage(stage: CrmStage): CrmCard[] {
    return this.filteredCards().filter(c => c.crmStage === stage);
  }

  // ── Stats ─────────────────────────────────────────────────────────────────
  totalProspects  = computed(() => this.cards().filter(c => c.crmStage === 'PROSPECT').length);
  totalActive     = computed(() => this.cards().filter(c => c.crmStage === 'ACTIVE').length);
  totalAtRisk     = computed(() => this.cards().filter(c => c.crmStage === 'AT_RISK').length);
  totalChurned    = computed(() => this.cards().filter(c => c.crmStage === 'CHURNED').length);

  conversionRate  = computed(() => {
    const prospects = this.totalProspects() + this.totalActive();
    return prospects ? Math.round((this.totalActive() / prospects) * 100) : 0;
  });

  churnRate = computed(() => {
    const total = this.cards().length;
    return total ? Math.round((this.totalChurned() / total) * 100) : 0;
  });

  membershipTypes = computed(() =>
    [...new Set(this.cards().map(c => c.membershipType))].sort()
  );

  ngOnInit() {
    this.loadPipeline();
  }

  loadPipeline() {
    this.isLoading.set(true);
    this.http.get<Record<string, CrmCard[]>>(`${this.BASE}/pipeline`).subscribe({
      next: (pipeline) => {
        const all: CrmCard[] = [];
        for (const [stage, members] of Object.entries(pipeline)) {
          members.forEach(m => all.push({ ...m, crmStage: stage as CrmStage }));
        }
        if (all.length > 0) this.cards.set(all);
        this.isLoading.set(false);
      },
      error: () => this.isLoading.set(false),
    });
  }

  // ── Drag & drop ───────────────────────────────────────────────────────────
  onDragStart(id: number) { this.draggedId.set(id); }
  onDragOver(e: DragEvent) { e.preventDefault(); }

  onDrop(e: DragEvent, targetStage: CrmStage) {
    e.preventDefault();
    const id = this.draggedId();
    if (id === null) return;

    const card = this.cards().find(c => c.memberId === id);
    if (!card || card.crmStage === targetStage) { this.draggedId.set(null); return; }

    this.cards.update(list =>
      list.map(c => c.memberId === id ? { ...c, crmStage: targetStage } : c)
    );
    this.draggedId.set(null);

    this.http.put(`${this.BASE}/member/${id}/status`, null, { params: { stage: targetStage } })
      .subscribe({
        next: () => this.toast.success('Statut mis à jour', `Déplacé vers ${STAGE_META[targetStage].label}`),
        error: () => {},
      });
  }

  // ── Notes modal ───────────────────────────────────────────────────────────
  openNote(card: CrmCard) {
    this.noteCard.set(card);
    this.noteText.set('');
  }

  closeNote() { this.noteCard.set(null); }

  saveNote() {
    const card = this.noteCard();
    const note = this.noteText().trim();
    if (!card || !note) return;

    this.http.post<CrmCard>(`${this.BASE}/member/${card.memberId}/note`, { note }).subscribe({
      next: (updated) => {
        this.cards.update(list => list.map(c => c.memberId === card.memberId ? { ...c, notes: updated.notes } : c));
        this.toast.success('Note ajoutée', 'La note a été enregistrée.');
        this.closeNote();
      },
      error: () => {
        this.cards.update(list => list.map(c =>
          c.memberId === card.memberId ? { ...c, notes: (c.notes || '') + `\n${note}` } : c
        ));
        this.toast.success('Note ajoutée', 'La note a été enregistrée.');
        this.closeNote();
      },
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  avatar(card: CrmCard): string {
    return `https://i.pravatar.cc/150?u=crm${card.memberId}`;
  }

  daysColor(days?: number | null): string {
    if (days == null)   return 'text-gray-500';
    if (days < 0)       return 'text-red-400';
    if (days < 7)       return 'text-red-400';
    if (days < 14)      return 'text-[#D4A017]';
    return 'text-green-400';
  }

  daysLabel(days?: number | null): string {
    if (days == null)  return '—';
    if (days < 0)      return `Expiré il y a ${-days}j`;
    if (days === 0)    return 'Expire aujourd\'hui';
    return `J-${days}`;
  }
}
