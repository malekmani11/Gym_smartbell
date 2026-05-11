import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { EventDTO, EventRegistrationDTO, PageResponse } from '../models/api.models';

@Injectable({ providedIn: 'root' })
export class EventApiService {
  private http = inject(HttpClient);
  private readonly BASE = `${environment.apiUrl}/events`;

  getAll(): Observable<PageResponse<EventDTO>> {
    return this.http.get<PageResponse<EventDTO>>(this.BASE);
  }

  getById(id: number): Observable<EventDTO> {
    return this.http.get<EventDTO>(`${this.BASE}/${id}`);
  }

  create(dto: Partial<EventDTO>): Observable<EventDTO> {
    return this.http.post<EventDTO>(this.BASE, dto);
  }

  update(id: number, dto: Partial<EventDTO>): Observable<EventDTO> {
    return this.http.put<EventDTO>(`${this.BASE}/${id}`, dto);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.BASE}/${id}`);
  }

  getRegistrations(eventId: number): Observable<EventRegistrationDTO[]> {
    return this.http.get<EventRegistrationDTO[]>(`${this.BASE}/${eventId}/registrations`);
  }

  register(eventId: number): Observable<EventRegistrationDTO> {
    return this.http.post<EventRegistrationDTO>(`${this.BASE}/${eventId}/register`, {});
  }

  unregister(eventId: number): Observable<void> {
    return this.http.delete<void>(`${this.BASE}/${eventId}/register`);
  }

  getMyRegistrations(): Observable<EventRegistrationDTO[]> {
    return this.http.get<EventRegistrationDTO[]>(`${this.BASE}/my-registrations`);
  }
}
