import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { MemberDTO, PageResponse } from '../models/api.models';

@Injectable({ providedIn: 'root' })
export class MemberApiService {
  private http = inject(HttpClient);
  private readonly BASE       = `${environment.apiUrl}/members`;
  private readonly AUTH_BASE  = `${environment.apiUrl}/auth`;
  private readonly USERS_BASE = `${environment.apiUrl}/users`;

  // GET /members
  getAll(page = 0, size = 20, search = '', status = ''): Observable<PageResponse<MemberDTO>> {
    const params: Record<string, string> = { page: page.toString(), size: size.toString() };
    if (search.trim()) params['search'] = search.trim();
    if (status.trim()) params['status'] = status.trim();
    return this.http.get<PageResponse<MemberDTO>>(this.BASE, { params });
  }

  // POST /auth/register (crée user + entité member automatiquement)
  register(data: { firstName: string; lastName: string; email: string; password: string; phone?: string }): Observable<any> {
    return this.http.post<any>(`${this.AUTH_BASE}/register`, {
      firstName: data.firstName,
      lastName:  data.lastName,
      email:     data.email,
      password:  data.password,
      phone:     data.phone,
      roleName:  'ROLE_MEMBER',
    });
  }

  // GET /members/{id}
  getById(id: number): Observable<MemberDTO> {
    return this.http.get<MemberDTO>(`${this.BASE}/${id}`);
  }

  // GET /members/user/{userId}
  getByUserId(userId: number): Observable<MemberDTO> {
    return this.http.get<MemberDTO>(`${this.BASE}/user/${userId}`);
  }

  // POST /members  (admin creates member directly — no pre-existing user needed)
  create(dto: Partial<MemberDTO>): Observable<MemberDTO> {
    return this.http.post<MemberDTO>(this.BASE, dto);
  }

  // POST /members/user/{userId}
  createForUser(userId: number, dto: Partial<MemberDTO>): Observable<MemberDTO> {
    return this.http.post<MemberDTO>(`${this.BASE}/user/${userId}`, dto);
  }

  // PUT /members/{id}
  update(id: number, dto: Partial<MemberDTO>): Observable<MemberDTO> {
    return this.http.put<MemberDTO>(`${this.BASE}/${id}`, dto);
  }

  // PATCH /members/{id}/status?status=
  updateStatus(id: number, status: string): Observable<void> {
    return this.http.patch<void>(`${this.BASE}/${id}/status`, null, { params: { status } });
  }

  // PATCH /members/{id}/assign-coach?coachId=
  assignCoach(memberId: number, coachId: number | null): Observable<void> {
    const params: Record<string, string> = {};
    if (coachId !== null) params['coachId'] = coachId.toString();
    return this.http.patch<void>(`${this.BASE}/${memberId}/assign-coach`, null, { params });
  }

  // PATCH /members/{id}/messaging-access?enabled=
  setMessagingAccess(memberId: number, enabled: boolean): Observable<void> {
    return this.http.patch<void>(`${this.BASE}/${memberId}/messaging-access`, null, { params: { enabled: enabled.toString() } });
  }

  // PATCH /users/{userId}/status?enabled=
  toggleStatus(userId: number, enabled: boolean): Observable<void> {
    return this.http.patch<void>(`${this.USERS_BASE}/${userId}/status`, null, {
      params: { enabled: enabled.toString() }
    });
  }

  // DELETE /members/{id}
  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.BASE}/${id}`);
  }
}
