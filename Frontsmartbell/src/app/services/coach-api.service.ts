import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { CoachDTO, CreateCoachRequest, PageResponse } from '../models/api.models';

@Injectable({ providedIn: 'root' })
export class CoachApiService {
  private http = inject(HttpClient);
  private readonly BASE     = `${environment.apiUrl}/coaches`;
  private readonly AUTH_BASE = `${environment.apiUrl}/auth`;
  private readonly USERS_BASE = `${environment.apiUrl}/users`;

  // GET /coaches
  getAll(): Observable<PageResponse<CoachDTO>> {
    return this.http.get<PageResponse<CoachDTO>>(this.BASE, {
      params: { size: '100' }
    });
  }

  // POST /auth/register (crée user + entité coach automatiquement)
  register(data: { firstName: string; lastName: string; email: string; password: string; phone?: string; specialization?: string }): Observable<any> {
    return this.http.post<any>(`${this.AUTH_BASE}/register`, {
      firstName:      data.firstName,
      lastName:       data.lastName,
      email:          data.email,
      password:       data.password,
      phone:          data.phone,
      roleName:       'ROLE_COACH',
      specialization: data.specialization || null,
    });
  }

  // GET /coaches/{id}
  getById(id: number): Observable<CoachDTO> {
    return this.http.get<CoachDTO>(`${this.BASE}/${id}`);
  }

  // GET /coaches/user/{userId}
  getByUserId(userId: number): Observable<CoachDTO> {
    return this.http.get<CoachDTO>(`${this.BASE}/user/${userId}`);
  }

  // POST /coaches  (admin creates coach directly — no pre-existing user needed)
  create(req: Partial<CoachDTO>): Observable<CoachDTO> {
    return this.http.post<CoachDTO>(this.BASE, req);
  }

  // POST /coaches/user/{userId}
  createForUser(userId: number, req: CreateCoachRequest): Observable<CoachDTO> {
    return this.http.post<CoachDTO>(`${this.BASE}/user/${userId}`, req);
  }

  // PUT /coaches/{id}
  update(id: number, req: Partial<CoachDTO>): Observable<CoachDTO> {
    return this.http.put<CoachDTO>(`${this.BASE}/${id}`, req);
  }

  // DELETE /coaches/{id}
  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.BASE}/${id}`);
  }
}
