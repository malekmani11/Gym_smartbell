package com.gymapp.member.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "qr_codes")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class QrCode {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Référence l'ID de la machine dans machine-service (pas de JPA cross-service)
    @Column(name = "machine_id", nullable = false, unique = true)
    private Long machineId;

    @Column(name = "qr_data", nullable = false, unique = true, length = 500)
    private String qrData;

    @Column(name = "generated_at", nullable = false)
    private LocalDateTime generatedAt;
}
