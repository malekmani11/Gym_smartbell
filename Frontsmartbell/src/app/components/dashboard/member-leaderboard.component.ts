import { Component, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';

export type Period = 'month' | 'quarter' | 'year';
export type Level  = 'Bronze' | 'Silver' | 'Gold' | 'Platinum';

export interface LeaderboardMember {
  id: string;
  name: string;
  avatar: string;
  points: Record<Period, number>;
}

const LEVEL_THRESHOLDS: Record<Level, number> = {
  Bronze:   100,
  Silver:   200,
  Gold:     350,
  Platinum: Infinity,
};

@Component({
  selector: 'app-member-leaderboard',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './member-leaderboard.component.html',
})
export class MemberLeaderboardComponent {

  activePeriod = signal<Period>('month');

  periods: { key: Period; label: string }[] = [
    { key: 'month',   label: 'Ce mois'      },
    { key: 'quarter', label: 'Ce trimestre' },
    { key: 'year',    label: 'Cette année'  },
  ];

  private readonly rawMembers: LeaderboardMember[] = [
    { id: 'l01', name: 'Sophie Laurent',    avatar: 'https://i.pravatar.cc/150?u=sophie1',  points: { month: 420, quarter: 1180, year: 4250 } },
    { id: 'l02', name: 'Thomas Renard',     avatar: 'https://i.pravatar.cc/150?u=thomas2',  points: { month: 395, quarter: 1050, year: 3980 } },
    { id: 'l03', name: 'Lucas Martin',      avatar: 'https://i.pravatar.cc/150?u=lucas3',   points: { month: 370, quarter:  990, year: 3720 } },
    { id: 'l04', name: 'Emma Bernard',      avatar: 'https://i.pravatar.cc/150?u=l4',  points: { month: 340, quarter:  920, year: 3400 } },
    { id: 'l05', name: 'Inès Charpentier', avatar: 'https://i.pravatar.cc/150?u=l5',  points: { month: 310, quarter:  870, year: 3100 } },
    { id: 'l06', name: 'Karim Benali',      avatar: 'https://i.pravatar.cc/150?u=l6',  points: { month: 285, quarter:  780, year: 2850 } },
    { id: 'l07', name: 'Yasmine Trabelsi',  avatar: 'https://i.pravatar.cc/150?u=l7',  points: { month: 250, quarter:  700, year: 2500 } },
    { id: 'l08', name: 'Rayan Sfar',        avatar: 'https://i.pravatar.cc/150?u=l8',  points: { month: 210, quarter:  620, year: 2100 } },
    { id: 'l09', name: 'Camille Morin',     avatar: 'https://i.pravatar.cc/150?u=l9',  points: { month: 180, quarter:  540, year: 1800 } },
    { id: 'l10', name: 'Antoine Faure',     avatar: 'https://i.pravatar.cc/150?u=l10', points: { month: 150, quarter:  460, year: 1500 } },
  ];

  // ── Sorted ranking for active period ─────────────────────────────────
  ranked = computed(() =>
    [...this.rawMembers]
      .sort((a, b) => b.points[this.activePeriod()] - a.points[this.activePeriod()])
  );

  top3    = computed(() => this.ranked().slice(0, 3));
  rest    = computed(() => this.ranked().slice(3));
  topPts  = computed(() => this.ranked()[0]?.points[this.activePeriod()] ?? 1);

  // ── Helpers ───────────────────────────────────────────────────────────
  getPoints(m: LeaderboardMember): number {
    return m.points[this.activePeriod()];
  }

  getLevel(pts: number): Level {
    if (pts > 350) return 'Platinum';
    if (pts > 200) return 'Gold';
    if (pts > 100) return 'Silver';
    return 'Bronze';
  }

  getLevelStyle(level: Level): string {
    switch (level) {
      case 'Platinum': return 'bg-purple-500/15 text-purple-300 border-purple-500/30';
      case 'Gold':     return 'bg-[#D4AF37]/15 text-[#D4AF37] border-[#D4AF37]/30';
      case 'Silver':   return 'bg-gray-400/15 text-gray-300 border-gray-400/30';
      case 'Bronze':   return 'bg-orange-500/15 text-orange-400 border-orange-500/30';
    }
  }

  getLevelIcon(level: Level): string {
    switch (level) {
      case 'Platinum': return 'fas fa-gem';
      case 'Gold':     return 'fas fa-star';
      case 'Silver':   return 'fas fa-circle';
      case 'Bronze':   return 'fas fa-shield-alt';
    }
  }

  /** Points needed to reach the next level threshold */
  nextLevelPts(pts: number): number {
    const thresholds = [100, 200, 350, 600];
    return thresholds.find(t => t > pts) ?? thresholds[thresholds.length - 1];
  }

  /** Progress % toward next level (within current level range) */
  levelProgress(pts: number): number {
    const levels = [0, 100, 200, 350];
    const floor = [...levels].reverse().find(l => pts >= l) ?? 0;
    const ceil  = this.nextLevelPts(pts);
    return Math.min(Math.round(((pts - floor) / (ceil - floor)) * 100), 100);
  }

  /** Width % of bar relative to the top scorer */
  barWidth(pts: number): number {
    return Math.round((pts / this.topPts()) * 100);
  }

  /** Podium heights: 2nd shorter, 1st tallest, 3rd shortest */
  podiumOrder = [1, 0, 2]; // indices into top3: [2nd, 1st, 3rd]

  podiumHeight(podiumSlot: number): string {
    return ['h-24', 'h-32', 'h-20'][podiumSlot];
  }

  rankMedal(rank: number): string {
    return ['🥇', '🥈', '🥉'][rank] ?? '';
  }

  firstName(member: LeaderboardMember | undefined): string {
    return member?.name?.split(' ')[0] ?? '';
  }
}
