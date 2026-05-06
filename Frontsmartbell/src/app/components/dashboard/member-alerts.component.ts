import { Component, signal, output } from '@angular/core';
import { CommonModule } from '@angular/common';

export interface AtRiskMember {
  id: string;
  name: string;
  avatar: string;
  plan: string;
  inactiveDays: number;
  riskScore: number; // 0-100
}

export interface ExpiringMember {
  id: string;
  name: string;
  avatar: string;
  plan: string;
  expiryDate: Date;
  daysLeft: number;
}

export type AlertAction =
  | { type: 'retention'; member: AtRiskMember }
  | { type: 'renewal';   member: ExpiringMember };

@Component({
  selector: 'app-member-alerts',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './member-alerts.component.html',
})
export class MemberAlertsComponent {

  alertAction = output<AlertAction>();

  // ── Membres à risque de résiliation ──────────────────────────────────────
  atRiskMembers = signal<AtRiskMember[]>([
    {
      id: 'R-001',
      name: 'Thomas Renard',
      avatar: 'https://i.pravatar.cc/150?u=r1',
      plan: 'CrossFit Elite',
      inactiveDays: 38,
      riskScore: 85,
    },
    {
      id: 'R-002',
      name: 'Camille Morin',
      avatar: 'https://i.pravatar.cc/150?u=r2',
      plan: 'Standard Premium',
      inactiveDays: 33,
      riskScore: 72,
    },
    {
      id: 'R-003',
      name: 'Antoine Faure',
      avatar: 'https://i.pravatar.cc/150?u=r3',
      plan: 'Yoga Flow',
      inactiveDays: 31,
      riskScore: 65,
    },
    {
      id: 'R-004',
      name: 'Inès Charpentier',
      avatar: 'https://i.pravatar.cc/150?u=r4',
      plan: 'VIP Elite',
      inactiveDays: 45,
      riskScore: 90,
    },
  ]);

  // ── Abonnements expirant bientôt ─────────────────────────────────────────
  expiringMembers = signal<ExpiringMember[]>([
    {
      id: 'E-001',
      name: 'Sophie Laurent',
      avatar: 'https://i.pravatar.cc/150?u=e1',
      plan: 'Yoga Premium',
      expiryDate: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
      daysLeft: 2,
    },
    {
      id: 'E-002',
      name: 'Lucas Martin',
      avatar: 'https://i.pravatar.cc/150?u=e2',
      plan: 'Standard Premium',
      expiryDate: new Date(Date.now() + 4 * 24 * 60 * 60 * 1000),
      daysLeft: 4,
    },
    {
      id: 'E-003',
      name: 'Emma Bernard',
      avatar: 'https://i.pravatar.cc/150?u=e3',
      plan: 'CrossFit Elite',
      expiryDate: new Date(Date.now() + 6 * 24 * 60 * 60 * 1000),
      daysLeft: 6,
    },
  ]);

  // ── Helpers ───────────────────────────────────────────────────────────────

  /** Couleur Tailwind selon l'urgence (jours restants) */
  getDaysColor(days: number): string {
    if (days <= 2) return 'text-red-400';
    if (days <= 4) return 'text-yellow-400';
    return 'text-green-400';
  }

  /** Barre de progression du score de risque */
  getRiskBarColor(score: number): string {
    if (score >= 80) return 'bg-red-500';
    if (score >= 65) return 'bg-yellow-500';
    return 'bg-green-500';
  }

  getRiskBadgeClass(score: number): string {
    if (score >= 80) return 'bg-red-500/15 text-red-400 border-red-500/30';
    if (score >= 65) return 'bg-yellow-500/15 text-yellow-400 border-yellow-500/30';
    return 'bg-green-500/15 text-green-400 border-green-500/30';
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  sendRetentionEmail(member: AtRiskMember) {
    this.alertAction.emit({ type: 'retention', member });
  }

  sendRenewalReminder(member: ExpiringMember) {
    this.alertAction.emit({ type: 'renewal', member });
  }
}
