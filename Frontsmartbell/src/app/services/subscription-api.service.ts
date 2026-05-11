import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { SubscriptionDTO, SubscriptionPlanDTO, PageResponse } from '../models/api.models';

@Injectable({ providedIn: 'root' })
export class SubscriptionApiService {
  private http = inject(HttpClient);
  private readonly BASE = `${environment.apiUrl}/subscriptions`;
  private readonly PLANS = `${environment.apiUrl}/subscription-plans`;

  // POST /subscriptions
  create(req: Partial<SubscriptionDTO>): Observable<SubscriptionDTO> {
    return this.http.post<SubscriptionDTO>(this.BASE, req);
  }

  // GET /subscriptions/{id}
  getById(id: number): Observable<SubscriptionDTO> {
    return this.http.get<SubscriptionDTO>(`${this.BASE}/${id}`);
  }

  // GET /subscriptions/user/{userId}
  getByUser(userId: number): Observable<PageResponse<SubscriptionDTO>> {
    return this.http.get<PageResponse<SubscriptionDTO>>(`${this.BASE}/user/${userId}`);
  }

  // GET /subscriptions/status/{status}
  getByStatus(status: string): Observable<PageResponse<SubscriptionDTO>> {
    return this.http.get<PageResponse<SubscriptionDTO>>(`${this.BASE}/status/${status}`);
  }

  // PATCH /subscriptions/{id}/cancel
  cancel(id: number): Observable<SubscriptionDTO> {
    return this.http.patch<SubscriptionDTO>(`${this.BASE}/${id}/cancel`, {});
  }

  // PATCH /subscriptions/{id}/renew
  renew(subscriptionId: number): Observable<SubscriptionDTO> {
    return this.http.patch<SubscriptionDTO>(`${this.BASE}/${subscriptionId}/renew`, {});
  }

  // ── Plans ──────────────────────────────────────

  // GET /subscription-plans  (activeOnly defaults to true on backend)
  getAllPlans(activeOnly?: boolean): Observable<SubscriptionPlanDTO[]> {
    if (activeOnly !== undefined) {
      return this.http.get<SubscriptionPlanDTO[]>(this.PLANS, { params: { activeOnly: String(activeOnly) } });
    }
    return this.http.get<SubscriptionPlanDTO[]>(this.PLANS);
  }

  // GET /subscription-plans/{id}
  getPlanById(id: number): Observable<SubscriptionPlanDTO> {
    return this.http.get<SubscriptionPlanDTO>(`${this.PLANS}/${id}`);
  }

  // POST /subscription-plans
  createPlan(req: Partial<SubscriptionPlanDTO>): Observable<SubscriptionPlanDTO> {
    return this.http.post<SubscriptionPlanDTO>(this.PLANS, req);
  }

  // PUT /subscription-plans/{id}
  updatePlan(id: number, req: Partial<SubscriptionPlanDTO>): Observable<SubscriptionPlanDTO> {
    return this.http.put<SubscriptionPlanDTO>(`${this.PLANS}/${id}`, req);
  }

  // DELETE /subscription-plans/{id}
  deletePlan(id: number): Observable<void> {
    return this.http.delete<void>(`${this.PLANS}/${id}`);
  }
}
