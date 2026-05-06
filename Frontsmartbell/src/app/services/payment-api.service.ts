import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { PaymentDTO, PageResponse } from '../models/api.models';

@Injectable({ providedIn: 'root' })
export class PaymentApiService {
  private http = inject(HttpClient);
  private readonly BASE = `${environment.apiUrl}/payments`;

  // GET /payments/{id}
  getById(id: number): Observable<PaymentDTO> {
    return this.http.get<PaymentDTO>(`${this.BASE}/${id}`);
  }

  // GET /payments/subscription/{subscriptionId}
  getBySubscription(subscriptionId: number): Observable<PageResponse<PaymentDTO>> {
    return this.http.get<PageResponse<PaymentDTO>>(
      `${this.BASE}/subscription/${subscriptionId}`
    );
  }

  // GET /payments/user/{userId}
  getByUser(userId: number): Observable<PageResponse<PaymentDTO>> {
    return this.http.get<PageResponse<PaymentDTO>>(
      `${this.BASE}/user/${userId}`
    );
  }

  // POST /payments
  create(req: Partial<PaymentDTO>): Observable<PaymentDTO> {
    return this.http.post<PaymentDTO>(this.BASE, req);
  }

  // PATCH /payments/{id}/status?status=...
  updateStatus(id: number, status: string): Observable<PaymentDTO> {
    return this.http.patch<PaymentDTO>(
      `${this.BASE}/${id}/status`, null, { params: { status } }
    );
  }
}
