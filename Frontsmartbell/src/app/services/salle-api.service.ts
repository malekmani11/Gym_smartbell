import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export type SalleStatus = 'DISPONIBLE' | 'OCCUPEE' | 'MAINTENANCE';

export interface Salle {
  id?: number;
  name: string;
  capacity: number;
  currentOccupancy: number;
  status: SalleStatus;
  location: string;
  description: string;
  occupancyRate?: number | null;
  hasCourses?: boolean;
  confirmedReservationsToday?: number;
}

@Injectable({ providedIn: 'root' })
export class SalleApiService {
  private http = inject(HttpClient);
  private readonly BASE = `${environment.apiUrl}/salles`;

  getAll(): Observable<Salle[]> {
    return this.http.get<Salle[]>(this.BASE);
  }

  getById(id: number): Observable<Salle> {
    return this.http.get<Salle>(`${this.BASE}/${id}`);
  }

  create(salle: Salle): Observable<Salle> {
    return this.http.post<Salle>(this.BASE, salle);
  }

  update(id: number, salle: Salle): Observable<Salle> {
    return this.http.put<Salle>(`${this.BASE}/${id}`, salle);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.BASE}/${id}`);
  }
}
