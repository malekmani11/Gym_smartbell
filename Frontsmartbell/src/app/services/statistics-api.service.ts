import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { StatisticsDTO } from '../models/api.models';

@Injectable({ providedIn: 'root' })
export class StatisticsApiService {
  private http = inject(HttpClient);
  private readonly BASE = `${environment.apiUrl}/statistics`;

  // GET /statistics
  getDashboard(): Observable<StatisticsDTO> {
    return this.http.get<StatisticsDTO>(this.BASE);
  }
}
