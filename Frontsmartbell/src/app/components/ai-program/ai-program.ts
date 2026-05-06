import { Component, signal, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../services/auth.service';
import { AiProgramApiService, AiProgramRequest, AiProgramResponse } from '../../services/ai-program-api.service';
import { ToastService } from '../../services/toast.service';

@Component({
  selector: 'app-ai-program',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './ai-program.html',
  styleUrl: './ai-program.css'
})
export class AiProgram {
  private auth      = inject(AuthService);
  private aiApi     = inject(AiProgramApiService);
  private toast     = inject(ToastService);

  isLoading = signal(false);
  result    = signal<AiProgramResponse | null>(null);
  errorMsg  = signal<string | null>(null);

  form: AiProgramRequest = {
    poids:    0,
    taille:   0,
    age:      0,
    sexe:     'homme',
    objectif: 'prise_masse',
    niveau:   'debutant',
    seances:  4,
  };

  generate() {
    const memberId = this.auth.currentUserId();
    if (!memberId) {
      this.toast.error('Utilisateur non connecté');
      return;
    }

    this.isLoading.set(true);
    this.result.set(null);
    this.errorMsg.set(null);

    this.aiApi.generate(memberId, this.form).subscribe({
      next: (res) => {
        this.result.set(res);
        this.isLoading.set(false);
        this.toast.success('Programme généré avec succès !');
      },
      error: (err) => {
        const msg = err?.error?.message || 'Erreur lors de la génération du programme';
        this.errorMsg.set(msg);
        this.isLoading.set(false);
        this.toast.error(msg);
      }
    });
  }

  intensiteStars(n: number): number[] {
    return Array.from({ length: n });
  }

  intensiteEmpty(n: number): number[] {
    return Array.from({ length: 5 - n });
  }

  objectifLabel(v: string): string {
    const map: Record<string, string> = {
      prise_masse:    'Prise de masse',
      perte_poids:    'Perte de poids',
      endurance:      'Endurance',
      tonification:   'Tonification',
    };
    return map[v] ?? v;
  }

  niveauLabel(v: string): string {
    const map: Record<string, string> = {
      debutant:       'Débutant',
      intermediaire:  'Intermédiaire',
      avance:         'Avancé',
    };
    return map[v] ?? v;
  }

  programmeSections(): { title: string; lines: string[] }[] {
    const raw = this.result()?.programme ?? '';
    const sections: { title: string; lines: string[] }[] = [];
    let current: { title: string; lines: string[] } | null = null;

    for (const line of raw.split('\n')) {
      const trimmed = line.trim();
      if (!trimmed) continue;
      if (/^#{1,3}\s/.test(trimmed) || /^\*\*[^*]+\*\*\s*$/.test(trimmed)) {
        if (current) sections.push(current);
        current = { title: trimmed.replace(/^#+\s*/, '').replace(/\*\*/g, ''), lines: [] };
      } else {
        if (!current) current = { title: '', lines: [] };
        current.lines.push(trimmed.replace(/^[-*•]\s*/, ''));
      }
    }
    if (current) sections.push(current);
    return sections;
  }
}
