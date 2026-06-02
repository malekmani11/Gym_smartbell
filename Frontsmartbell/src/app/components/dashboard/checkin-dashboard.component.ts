import { Component, signal, inject, OnInit, Input, ElementRef, ViewChild, AfterViewInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { CheckinApiService } from '../../services/checkin-api.service';
import { MemberApiService } from '../../services/member-api.service';
import { ToastService } from '../../services/toast.service';
import { CheckInDTO } from '../../models/api.models';

interface MemberOption {
  id: number;
  name: string;
  avatar: string;
}

@Component({
  selector: 'app-checkin-dashboard',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="panel-card">

      <!-- ── Header ── -->
      <div class="flex items-center justify-between mb-5">
        <div class="flex items-center gap-3">
          <div class="section-accent"></div>
          <div>
            <h3 class="text-sm font-bold text-white uppercase tracking-widest">Check-ins du jour</h3>
            <p class="text-[10px] text-gray-500 mt-0.5">Présences enregistrées aujourd'hui</p>
          </div>
        </div>
        <div class="flex gap-2">
          <button (click)="openQrModal(null)"
                  title="Scanner un QR code"
                  class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-purple-500/10 border border-purple-500/30 text-purple-400 text-[10px] font-bold uppercase tracking-wider hover:bg-purple-500/20 transition-all cursor-pointer">
            <i class="fas fa-qrcode text-[11px]"></i>
            QR Scan
          </button>
          <button (click)="toggleForm()"
                  class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#D4A017]/10 border border-[#D4A017]/30 text-[#D4A017] text-[10px] font-bold uppercase tracking-wider hover:bg-[#D4A017]/20 transition-all cursor-pointer">
            <i class="fas fa-user-check text-[9px]"></i>
            Manuel
          </button>
        </div>
      </div>

      <!-- ── Mini stats ── -->
      <div class="grid grid-cols-3 gap-3 mb-5">
        <div class="p-3 rounded-xl bg-[#0D0D0D] border border-white/5 text-center">
          <p class="text-xl font-bold text-[#D4A017]">{{ checkInsToday() }}</p>
          <p class="text-[9px] text-gray-500 font-bold uppercase tracking-wider mt-0.5">Aujourd'hui</p>
        </div>
        <div class="p-3 rounded-xl bg-[#0D0D0D] border border-white/5 text-center">
          <p class="text-xl font-bold text-white">{{ checkInsThisWeek() }}</p>
          <p class="text-[9px] text-gray-500 font-bold uppercase tracking-wider mt-0.5">Cette semaine</p>
        </div>
        <div class="p-3 rounded-xl bg-[#0D0D0D] border border-white/5 text-center">
          <p class="text-xl font-bold text-purple-400">{{ checkInsThisMonth() }}</p>
          <p class="text-[9px] text-gray-500 font-bold uppercase tracking-wider mt-0.5">Ce mois</p>
        </div>
      </div>

      <!-- ── Formulaire manuel ── -->
      @if (showForm()) {
        <div class="mb-5 p-4 rounded-xl bg-[#0D0D0D] border border-[#D4A017]/20">
          <p class="text-[10px] text-gray-400 font-bold uppercase tracking-wider mb-3">Sélectionner un membre</p>
          <div class="flex gap-2">
            <select [(ngModel)]="selectedMemberId"
                    class="flex-1 bg-[#1A1A1A] border border-white/10 text-white text-xs rounded-lg px-3 py-2 focus:outline-none focus:border-[#D4A017]/50">
              <option value="">— Choisir un membre —</option>
              @for (m of memberOptions(); track m.id) {
                <option [value]="m.id">{{ m.name }}</option>
              }
            </select>
            <button (click)="showMemberQr()"
                    [disabled]="!selectedMemberId"
                    title="Afficher le QR code du membre"
                    class="px-3 py-2 rounded-lg bg-purple-500/10 border border-purple-500/30 text-purple-400 hover:bg-purple-500/20 disabled:opacity-30 disabled:cursor-not-allowed transition-all cursor-pointer">
              <i class="fas fa-qrcode text-sm"></i>
            </button>
            <button (click)="submitCheckIn()"
                    [disabled]="!selectedMemberId || isProcessing()"
                    class="px-4 py-2 rounded-lg bg-[#D4A017] text-black text-xs font-bold uppercase tracking-wider hover:bg-[#F0C040] disabled:opacity-40 disabled:cursor-not-allowed transition-all cursor-pointer">
              @if (isProcessing()) { <i class="fas fa-spinner fa-spin"></i> } @else { Valider }
            </button>
          </div>
        </div>
      }

      <!-- ── Liste des check-ins récents ── -->
      <div class="space-y-2.5">
        @if (recentCheckIns().length === 0) {
          <div class="py-8 text-center">
            <i class="fas fa-door-open text-2xl text-gray-700 mb-2 block"></i>
            <p class="text-xs text-gray-600">Aucun check-in aujourd'hui</p>
          </div>
        }
        @for (ci of recentCheckIns().slice(0, 6); track ci.id) {
          <div class="flex items-center gap-3 p-2.5 rounded-xl bg-[#0D0D0D] border border-white/[0.04] hover:border-[#D4A017]/15 transition-colors group">
            <img [src]="ci.profileImageUrl || ('https://i.pravatar.cc/150?u=member' + ci.memberId)"
                 class="w-8 h-8 rounded-lg object-cover ring-1 ring-white/10 shrink-0" alt="">
            <div class="flex-1 min-w-0">
              <p class="text-xs font-bold text-white truncate">{{ ci.memberFirstName }} {{ ci.memberLastName }}</p>
              <p class="text-[9px] text-gray-500 truncate">{{ ci.memberEmail }}</p>
            </div>
            <div class="flex items-center gap-2 shrink-0">
              <button (click)="openQrModal(ci.memberId)"
                      title="QR code du membre"
                      class="opacity-0 group-hover:opacity-100 w-6 h-6 flex items-center justify-center rounded-lg bg-purple-500/10 text-purple-400 hover:bg-purple-500/20 transition-all cursor-pointer">
                <i class="fas fa-qrcode text-[10px]"></i>
              </button>
              <div class="text-right">
                <p class="text-[10px] font-mono text-[#D4A017]">{{ formatTime(ci.checkInTime) }}</p>
                @if (ci.checkOutTime) {
                  <p class="text-[9px] text-gray-600">sortie {{ formatTime(ci.checkOutTime) }}</p>
                } @else {
                  <span class="text-[8px] px-1.5 py-0.5 rounded-full bg-green-500/10 text-green-400 font-bold">EN SALLE</span>
                }
              </div>
            </div>
          </div>
        }
      </div>

      @if (recentCheckIns().length > 6) {
        <p class="text-center text-[10px] text-gray-600 mt-3">+{{ recentCheckIns().length - 6 }} autres check-ins</p>
      }
    </div>

    <!-- ══════════════════════════════════════════════════════
         MODALE QR CODE
    ══════════════════════════════════════════════════════ -->
    @if (showQrModal()) {
      <div class="fixed inset-0 z-50 flex items-center justify-center p-4"
           style="background:rgba(0,0,0,0.75);backdrop-filter:blur(6px)"
           (click)="closeQrModal()">
        <div class="relative w-full max-w-sm rounded-2xl border border-white/10 p-6 text-center"
             style="background:linear-gradient(145deg,#1e1e1e,#111)"
             (click)="$event.stopPropagation()">

          <!-- Fermer -->
          <button (click)="closeQrModal()"
                  class="absolute top-4 right-4 w-7 h-7 flex items-center justify-center rounded-lg bg-white/5 hover:bg-white/10 text-gray-400 transition-all cursor-pointer">
            <i class="fas fa-times text-xs"></i>
          </button>

          @if (qrScanMode()) {
            <!-- ── Mode scan QR ── -->
            <div class="mb-4">
              <div class="w-12 h-12 rounded-xl bg-purple-500/10 border border-purple-500/20 flex items-center justify-center mx-auto mb-3">
                <i class="fas fa-qrcode text-purple-400 text-xl"></i>
              </div>
              <h3 class="text-sm font-bold text-white uppercase tracking-widest">Scanner un QR code</h3>
              <p class="text-[10px] text-gray-500 mt-1">Pointez votre scanner vers le QR code membre</p>
            </div>

            <div class="relative mb-4">
              <div class="absolute inset-0 flex items-center">
                <span class="w-full border-t border-dashed border-purple-500/20"></span>
              </div>
              <div class="relative flex justify-center">
                <span class="bg-[#1A1A1A] px-3 text-[9px] text-gray-600 uppercase tracking-widest">ou saisie manuelle</span>
              </div>
            </div>

            <input #qrInput
                   [(ngModel)]="qrCodeInput"
                   (keydown.enter)="processQrCode()"
                   (input)="onQrInput()"
                   placeholder="Code QR membre..."
                   autofocus
                   class="w-full bg-[#0D0D0D] border border-purple-500/30 text-white text-xs rounded-xl px-4 py-3 text-center font-mono focus:outline-none focus:border-purple-400 placeholder-gray-700 mb-4">

            @if (qrError()) {
              <p class="text-[11px] text-red-400 mb-3"><i class="fas fa-exclamation-circle mr-1"></i>{{ qrError() }}</p>
            }

            <button (click)="processQrCode()"
                    [disabled]="!qrCodeInput.trim() || isProcessing()"
                    class="w-full py-2.5 rounded-xl bg-purple-600 text-white text-xs font-bold uppercase tracking-wider hover:bg-purple-500 disabled:opacity-40 disabled:cursor-not-allowed transition-all cursor-pointer">
              @if (isProcessing()) { <i class="fas fa-spinner fa-spin mr-1"></i>Traitement... }
              @else { <i class="fas fa-check mr-1"></i>Valider le check-in }
            </button>

          } @else {
            <!-- ── Mode affichage QR ── -->
            <div class="mb-4">
              <div class="w-12 h-12 rounded-xl bg-[#D4A017]/10 border border-[#D4A017]/20 flex items-center justify-center mx-auto mb-3">
                <i class="fas fa-id-badge text-[#D4A017] text-xl"></i>
              </div>
              <h3 class="text-sm font-bold text-white uppercase tracking-widest">QR Code membre</h3>
              <p class="text-[10px] text-gray-500 mt-1 font-mono">{{ qrMemberName() }}</p>
            </div>

            <!-- QR Image -->
            <div class="flex justify-center mb-4">
              <div class="p-3 rounded-2xl bg-white">
                <img [src]="qrImageUrl()"
                     width="180" height="180"
                     alt="QR Code membre"
                     class="block">
              </div>
            </div>

            <p class="text-[9px] text-gray-600 font-mono mb-4">{{ qrCodeValue() }}</p>

            <button (click)="printQr()"
                    class="w-full py-2.5 rounded-xl bg-[#D4A017]/10 border border-[#D4A017]/30 text-[#D4A017] text-xs font-bold uppercase tracking-wider hover:bg-[#D4A017]/20 transition-all cursor-pointer">
              <i class="fas fa-print mr-1"></i>Imprimer
            </button>
          }
        </div>
      </div>
    }
  `
})
export class CheckinDashboardComponent implements OnInit, AfterViewInit {
  @Input() set statsCheckInsToday(v: number)        { this.checkInsToday.set(v); }
  @Input() set statsCheckInsWeek(v: number)         { this.checkInsThisWeek.set(v); }
  @Input() set statsCheckInsMonth(v: number)        { this.checkInsThisMonth.set(v); }
  @Input() set statsRecentCheckIns(v: CheckInDTO[]) { if (v?.length) this.recentCheckIns.set(v); }

  @ViewChild('qrInput') qrInputRef?: ElementRef<HTMLInputElement>;

  private checkinApi = inject(CheckinApiService);
  private memberApi  = inject(MemberApiService);
  private toast      = inject(ToastService);

  checkInsToday     = signal(0);
  checkInsThisWeek  = signal(0);
  checkInsThisMonth = signal(0);
  recentCheckIns    = signal<CheckInDTO[]>([]);
  memberOptions     = signal<MemberOption[]>([]);

  showForm      = signal(false);
  isProcessing  = signal(false);
  selectedMemberId = '';

  // ── QR modal state ──────────────────────────────────────────
  showQrModal   = signal(false);
  qrScanMode    = signal(false);
  qrCodeInput   = '';
  qrError       = signal('');
  qrMemberId    = signal<number | null>(null);
  qrMemberName  = signal('');

  qrCodeValue = () => `SMARTBELL-MEMBER-${this.qrMemberId() ?? ''}`;

  qrImageUrl = () => {
    const val = encodeURIComponent(this.qrCodeValue());
    return `https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=${val}&bgcolor=ffffff&color=000000&margin=8`;
  };

  ngOnInit() {
    this.loadTodayCheckIns();
    this.loadMembers();
  }

  ngAfterViewInit() {}

  // ── Form manuel ─────────────────────────────────────────────

  toggleForm() { this.showForm.update(v => !v); }

  submitCheckIn() {
    const id = parseInt(this.selectedMemberId, 10);
    if (!id) return;
    this.isProcessing.set(true);
    this.checkinApi.checkIn(id).subscribe({
      next: (ci) => this.onCheckInSuccess(ci),
      error: (err) => this.onCheckInError(err)
    });
  }

  showMemberQr() {
    const id = parseInt(this.selectedMemberId, 10);
    if (!id) return;
    const member = this.memberOptions().find(m => m.id === id);
    this.qrMemberId.set(id);
    this.qrMemberName.set(member?.name ?? `Membre #${id}`);
    this.qrScanMode.set(false);
    this.showQrModal.set(true);
  }

  // ── QR modal ────────────────────────────────────────────────

  openQrModal(memberId: number | null) {
    this.qrError.set('');
    this.qrCodeInput = '';
    if (memberId) {
      // Afficher le QR du membre
      const member = this.memberOptions().find(m => m.id === memberId)
                  ?? this.recentCheckIns().find(c => c.memberId === memberId);
      this.qrMemberId.set(memberId);
      this.qrMemberName.set(
        member ? ('name' in member ? (member as MemberOption).name
                                   : `${(member as CheckInDTO).memberFirstName} ${(member as CheckInDTO).memberLastName}`)
               : `Membre #${memberId}`
      );
      this.qrScanMode.set(false);
    } else {
      // Mode scan
      this.qrScanMode.set(true);
    }
    this.showQrModal.set(true);
    // Focus input scanner
    if (!memberId) {
      setTimeout(() => this.qrInputRef?.nativeElement?.focus(), 100);
    }
  }

  closeQrModal() {
    this.showQrModal.set(false);
    this.qrCodeInput = '';
    this.qrError.set('');
  }

  onQrInput() {
    // Un scanner USB envoie le code + Enter automatiquement.
    // Ici on détecte aussi si la valeur est un code complet sans Enter.
    const val = this.qrCodeInput.trim();
    if (val.startsWith('SMARTBELL-MEMBER-') && val.length > 18) {
      setTimeout(() => this.processQrCode(), 50);
    }
  }

  processQrCode() {
    const raw = this.qrCodeInput.trim();
    if (!raw) return;

    const match = raw.match(/^SMARTBELL-MEMBER-(\d+)$/);
    if (!match) {
      this.qrError.set('QR code invalide. Format attendu : SMARTBELL-MEMBER-{id}');
      return;
    }

    const memberId = parseInt(match[1], 10);
    this.qrError.set('');
    this.isProcessing.set(true);
    this.checkinApi.checkIn(memberId).subscribe({
      next: (ci) => {
        this.closeQrModal();
        this.onCheckInSuccess(ci);
      },
      error: (err) => {
        this.isProcessing.set(false);
        this.qrError.set(err.error?.message || 'Erreur lors du check-in.');
      }
    });
  }

  printQr() {
    const win = window.open('', '_blank');
    if (!win) return;
    win.document.write(`
      <html><head><title>QR Code — ${this.qrMemberName()}</title>
      <style>body{display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:100vh;font-family:sans-serif;background:#fff;}
      h2{margin-bottom:12px}p{color:#555;font-size:12px;margin-top:8px}</style></head>
      <body>
        <h2>${this.qrMemberName()}</h2>
        <img src="${this.qrImageUrl()}" width="200" height="200">
        <p>${this.qrCodeValue()}</p>
        <script>window.onload=()=>window.print()</script>
      </body></html>
    `);
    win.document.close();
  }

  // ── Helpers ─────────────────────────────────────────────────

  formatTime(dt: string): string {
    if (!dt) return '';
    return new Date(dt).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
  }

  private onCheckInSuccess(ci: CheckInDTO) {
    this.recentCheckIns.update(list => [ci, ...list]);
    this.checkInsToday.update(n => n + 1);
    this.checkInsThisWeek.update(n => n + 1);
    this.checkInsThisMonth.update(n => n + 1);
    this.toast.success('Check-in enregistré', `${ci.memberFirstName} ${ci.memberLastName} est arrivé(e).`);
    this.selectedMemberId = '';
    this.showForm.set(false);
    this.isProcessing.set(false);
  }

  private onCheckInError(err: { error?: { message?: string } }) {
    this.toast.error('Erreur', err.error?.message || 'Impossible d\'enregistrer le check-in.');
    this.isProcessing.set(false);
  }

  private loadTodayCheckIns() {
    this.checkinApi.getTodayCheckIns().subscribe({
      next: (list) => {
        this.recentCheckIns.set(list);
        this.checkInsToday.set(list.length);
      },
      error: () => {}
    });
  }

  private loadMembers() {
    this.memberApi.getAll().subscribe({
      next: (res) => {
        this.memberOptions.set((res.content || []).map(m => ({
          id:     m.id!,
          name:   `${m.firstName} ${m.lastName}`,
          avatar: m.profileImageUrl || '',
        })));
      },
      error: () => {}
    });
  }
}
