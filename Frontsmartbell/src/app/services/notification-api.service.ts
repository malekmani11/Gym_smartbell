import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { NotificationDTO, CreateNotificationRequest } from '../models/api.models';

@Injectable({ providedIn: 'root' })
export class NotificationApiService {
  private http = inject(HttpClient);
  private readonly BASE = `${environment.apiUrl}/notifications`;

  getAll(): Observable<NotificationDTO[]> {
    return this.http.get<NotificationDTO[]>(this.BASE);
  }

  getUnreadCount(): Observable<number> {
    return this.http.get<number>(`${this.BASE}/unread/count`);
  }

  markAsRead(id: number): Observable<void> {
    return this.http.patch<void>(`${this.BASE}/${id}/read`, {});
  }

  markAsReadByUser(broadcastId: number, userId: number): Observable<void> {
    return this.http.patch<void>(`${this.BASE}/${broadcastId}/read/user/${userId}`, {});
  }

  markAllAsRead(): Observable<void> {
    return this.http.patch<void>(`${this.BASE}/mark-all-read`, {});
  }

  send(request: CreateNotificationRequest): Observable<NotificationDTO[]> {
    return this.http.post<NotificationDTO[]>(this.BASE, request);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.BASE}/${id}`);
  }

  deleteAll(): Observable<void> {
    return this.http.delete<void>(this.BASE);
  }
}
