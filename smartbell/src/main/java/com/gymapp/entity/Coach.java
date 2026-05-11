package com.gymapp.entity;

import com.gymapp.entity.enums.AvailabilityStatus;
import com.gymapp.entity.enums.Specialization;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;

import java.time.LocalDate;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "coaches")
@PrimaryKeyJoinColumn(name = "user_id")
@DiscriminatorValue("COACH")
@Getter
@Setter
@NoArgsConstructor
@SuperBuilder
public class Coach extends User {

    @Enumerated(EnumType.STRING)
    @Column(length = 50)
    private Specialization specialization;

    @Column(columnDefinition = "TEXT")
    private String bio;

    private String certification;

    @Column(name = "hire_date")
    private LocalDate hireDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "availability_status", nullable = false)
    @Builder.Default
    private AvailabilityStatus availabilityStatus = AvailabilityStatus.AVAILABLE;

    @Column(name = "rating_avg")
    private Double ratingAvg;

    // ── Relationships ──────────────────────────────────────

    @OneToMany(mappedBy = "coach", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private Set<Course> courses = new HashSet<>();

    @OneToMany(mappedBy = "coach", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private Set<TrainingProgram> trainingPrograms = new HashSet<>();
}
