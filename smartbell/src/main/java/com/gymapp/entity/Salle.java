package com.gymapp.entity;

import com.gymapp.entity.enums.SalleStatus;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "salles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Salle {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 150)
    private String name;

    @Column(nullable = false)
    private Integer capacity;

    @Column(name = "current_occupancy")
    @Builder.Default
    private Integer currentOccupancy = 0;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private SalleStatus status = SalleStatus.DISPONIBLE;

    @Column(length = 200)
    private String location;

    @Column(columnDefinition = "TEXT")
    private String description;
}
