import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface AiProgramRequest {
  poids: number;
  taille: number;
  age: number;
  sexe: string;
  objectif: string;
  niveau: string;
  seances: number;
}

export interface AiProgramResponse {
  programme: string;
  type_programme: string;
  intensite: number;
  split: string;
  imc: number;
  imc_categorie: string;
}

@Injectable({ providedIn: 'root' })
export class AiProgramApiService {
  private http = inject(HttpClient);
  private readonly API = environment.apiUrl;

  generate(memberId: number, req: AiProgramRequest): Observable<AiProgramResponse> {
    return this.http.post<AiProgramResponse>(
      `${this.API}/ai/generate-program/${memberId}`,
      req
    );
  }
}
