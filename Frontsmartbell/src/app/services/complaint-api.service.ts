import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { environment } from '../../environments/environment';
import { ComplaintDTO, ComplaintStatus } from '../models/api.models';

@Injectable({ providedIn: 'root' })
export class ComplaintApiService {
  private http = inject(HttpClient);
  private readonly BASE = `${environment.apiUrl}/complaints`;

  getAll(): Observable<ComplaintDTO[]> {
    return this.http.get<any>(`${this.BASE}?size=200&sort=createdAt,desc`)
      .pipe(map(page => page.content ?? []));
  }

  getById(id: number): Observable<ComplaintDTO> {
    return this.http.get<ComplaintDTO>(`${this.BASE}/${id}`);
  }

  respond(id: number, response: string, status: ComplaintStatus): Observable<ComplaintDTO> {
    return this.http.patch<ComplaintDTO>(`${this.BASE}/${id}/respond`, { response, status });
  }

  markAsRead(id: number): Observable<ComplaintDTO> {
    return this.http.patch<ComplaintDTO>(`${this.BASE}/${id}/read`, {});
  }
}
