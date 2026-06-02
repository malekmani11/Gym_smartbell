import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { CheckInDTO } from '../models/api.models';

@Injectable({ providedIn: 'root' })
export class CheckinApiService {
  private http = inject(HttpClient);
  private readonly BASE = `${environment.apiUrl}/checkins`;

  checkIn(memberId: number): Observable<CheckInDTO> {
    return this.http.post<CheckInDTO>(`${this.BASE}/member/${memberId}`, {});
  }

  checkOut(memberId: number): Observable<CheckInDTO> {
    return this.http.put<CheckInDTO>(`${this.BASE}/checkout/${memberId}`, {});
  }

  getTodayCheckIns(): Observable<CheckInDTO[]> {
    return this.http.get<CheckInDTO[]>(`${this.BASE}/today`);
  }

  getMemberCheckIns(memberId: number): Observable<CheckInDTO[]> {
    return this.http.get<CheckInDTO[]>(`${this.BASE}/member/${memberId}`);
  }
}
