import { Component, input, output } from '@angular/core';
import { CommonModule } from '@angular/common';

export interface CourseHistory {
  name: string;
  date: Date;
  coach: string;
  duration: string;
}

export interface MemberProfile {
  id: string;
  name: string;
  email: string;
  avatar: string;
  plan: string;
  status: 'active' | 'expired' | 'pending';
  joinDate: Date;
  assignedCoach: string;
  // Objectifs & Mesures
  goal: 'Prise de masse' | 'Perte de poids' | 'Cardio' | 'Maintien';
  currentWeight: number;
  targetWeight: number;
  progressPercent: number;
  // Activité
  sessionsThisMonth: number;
  currentStreak: number;
  lastVisit: Date;
  favoriteCourses: string[];
  // Historique
  courseHistory: CourseHistory[];
}

@Component({
  selector: 'app-member-profile-modal',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './member-profile-modal.component.html',
})
export class MemberProfileModalComponent {

  member = input.required<MemberProfile>();
  closed = output<void>();

  close() {
    this.closed.emit();
  }

  getStatusClass(status: string): string {
    switch (status) {
      case 'active':  return 'bg-green-500/15 text-green-400 border-green-500/30';
      case 'expired': return 'bg-red-500/15 text-red-400 border-red-500/30';
      case 'pending': return 'bg-[#D4AF37]/15 text-[#D4AF37] border-[#D4AF37]/30';
      default:        return 'bg-gray-500/15 text-gray-400 border-gray-500/30';
    }
  }

  getStatusLabel(status: string): string {
    switch (status) {
      case 'active':  return 'Actif';
      case 'expired': return 'Expiré';
      case 'pending': return 'En attente';
      default:        return status;
    }
  }

  getGoalIcon(goal: string): string {
    switch (goal) {
      case 'Prise de masse': return 'fas fa-dumbbell';
      case 'Perte de poids': return 'fas fa-fire';
      case 'Cardio':         return 'fas fa-heartbeat';
      case 'Maintien':       return 'fas fa-balance-scale';
      default:               return 'fas fa-bullseye';
    }
  }

  getProgressColor(pct: number): string {
    if (pct >= 75) return 'bg-green-500';
    if (pct >= 40) return 'bg-[#D4AF37]';
    return 'bg-red-500';
  }
}
