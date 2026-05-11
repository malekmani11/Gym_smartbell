import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { CoachRatingDTO, RatingRequest } from '../models/api.models';

@Injectable({ providedIn: 'root' })
export class CoachRatingService {
  private http = inject(HttpClient);
  private readonly BASE = `${environment.apiUrl}/coaches`;

  rateCoach(coachId: number, request: RatingRequest): Observable<CoachRatingDTO> {
    return this.http.post<CoachRatingDTO>(`${this.BASE}/${coachId}/ratings`, request);
  }

  getAverageRating(coachId: number): Observable<number> {
    return this.http.get<number>(`${this.BASE}/${coachId}/ratings/average`);
  }

  getCoachRatings(coachId: number): Observable<CoachRatingDTO[]> {
    return this.http.get<CoachRatingDTO[]>(`${this.BASE}/${coachId}/ratings`);
  }
}
