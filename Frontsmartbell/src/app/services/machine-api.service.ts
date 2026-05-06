import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export type MachineStatus = 'AVAILABLE' | 'MAINTENANCE' | 'OUT_OF_SERVICE';

export interface Machine {
  id?: number;
  name: string;
  description?: string;
  location?: string;
  status: MachineStatus;
  imageUrl?: string;
  tutorialUrl?: string;
  qrCodeData?: string;
}

@Injectable({ providedIn: 'root' })
export class MachineApiService {
  private http = inject(HttpClient);
  private readonly BASE = `${environment.apiUrl}/machines`;

  getAll(): Observable<Machine[]> {
    return this.http.get<Machine[]>(this.BASE);
  }

  getById(id: number): Observable<Machine> {
    return this.http.get<Machine>(`${this.BASE}/${id}`);
  }

  create(machine: Machine): Observable<Machine> {
    return this.http.post<Machine>(this.BASE, machine);
  }

  update(id: number, machine: Machine): Observable<Machine> {
    return this.http.put<Machine>(`${this.BASE}/${id}`, machine);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.BASE}/${id}`);
  }

  getQrCode(id: number): Observable<{ qrData: string }> {
    return this.http.get<{ qrData: string }>(`${this.BASE}/${id}/qrcode`);
  }
}
