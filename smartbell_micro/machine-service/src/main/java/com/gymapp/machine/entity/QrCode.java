package com.gymapp.machine.entity;

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

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "machine_id", nullable = false, unique = true)
    private Machine machine;

    @Column(name = "qr_data", nullable = false, unique = true, length = 500)
    private String qrData;

    @Column(name = "generated_at", nullable = false)
    private LocalDateTime generatedAt;
}
