import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { CourseDTO, CourseReservationDTO, CreateCourseRequest, PageResponse } from '../models/api.models';

@Injectable({ providedIn: 'root' })
export class CourseApiService {
  private http = inject(HttpClient);
  private readonly BASE = `${environment.apiUrl}/courses`;

  // GET /courses  (active courses, paginated)
  getAll(): Observable<PageResponse<CourseDTO>> {
    return this.http.get<PageResponse<CourseDTO>>(this.BASE);
  }

  // GET /courses/{id}
  getById(id: number): Observable<CourseDTO> {
    return this.http.get<CourseDTO>(`${this.BASE}/${id}`);
  }

  // GET /courses/coach/{coachId}
  getByCoach(coachId: number): Observable<PageResponse<CourseDTO>> {
    return this.http.get<PageResponse<CourseDTO>>(`${this.BASE}/coach/${coachId}`);
  }

  // POST /courses
  create(req: CreateCourseRequest): Observable<CourseDTO> {
    return this.http.post<CourseDTO>(this.BASE, req);
  }

  // PUT /courses/{id}
  update(id: number, req: Partial<CourseDTO>): Observable<CourseDTO> {
    return this.http.put<CourseDTO>(`${this.BASE}/${id}`, req);
  }

  // DELETE /courses/{id}
  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.BASE}/${id}`);
  }

  // POST /courses/reservations
  reserve(dto: CourseReservationDTO): Observable<CourseReservationDTO> {
    return this.http.post<CourseReservationDTO>(`${this.BASE}/reservations`, dto);
  }

  // GET /courses/reservations/member/{memberId}
  getReservationsByMember(memberId: number): Observable<PageResponse<CourseReservationDTO>> {
    return this.http.get<PageResponse<CourseReservationDTO>>(
      `${this.BASE}/reservations/member/${memberId}`
    );
  }

  // PATCH /courses/reservations/{id}/cancel
  cancelReservation(id: number): Observable<CourseReservationDTO> {
    return this.http.patch<CourseReservationDTO>(
      `${this.BASE}/reservations/${id}/cancel`, {}
    );
  }

  // GET /courses/{id}/reservations
  getReservationsByCourse(courseId: number): Observable<any[]> {
    return this.http.get<any[]>(`${this.BASE}/${courseId}/reservations`);
  }
}
