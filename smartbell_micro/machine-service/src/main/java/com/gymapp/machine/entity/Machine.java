package com.gymapp.machine.entity;

import com.gymapp.machine.entity.enums.MachineStatus;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "machines")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Machine {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 150)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(length = 100)
    private String location;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private MachineStatus status = MachineStatus.AVAILABLE;

    @Column(name = "image_url", length = 500)
    private String imageUrl;

    @Column(name = "tutorial_url", length = 500)
    private String tutorialUrl;

    // QrCode est dans machine-service — relation interne valide
    @OneToOne(mappedBy = "machine", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private QrCode qrCode;
}
