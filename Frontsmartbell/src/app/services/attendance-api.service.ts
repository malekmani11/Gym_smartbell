import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface AttendanceEntry {
  memberId: number;
  present: boolean;
  notes?: string;
}

export interface AttendanceRecord {
  id: number;
  courseId: number;
  courseName: string;
  memberId: number;
  memberFirstName: string;
  memberLastName: string;
  sessionDate: string;
  present: boolean;
  notes?: string;
}

@Injectable({ providedIn: 'root' })
export class AttendanceApiService {
  private http = inject(HttpClient);
  private readonly BASE = `${environment.apiUrl}/attendances`;

  record(courseId: number, sessionDate: string, attendances: AttendanceEntry[]): Observable<AttendanceRecord[]> {
    return this.http.post<AttendanceRecord[]>(`${this.BASE}/course/${courseId}`, {
      sessionDate,
      attendances,
    });
  }

  getByCourseAndDate(courseId: number, date: string): Observable<AttendanceRecord[]> {
    return this.http.get<AttendanceRecord[]>(`${this.BASE}/course/${courseId}`, {
      params: { date },
    });
  }

  getByMember(memberId: number): Observable<AttendanceRecord[]> {
    return this.http.get<AttendanceRecord[]>(`${this.BASE}/member/${memberId}`);
  }
}
