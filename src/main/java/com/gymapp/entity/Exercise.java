package com.gymapp.entity;

import com.gymapp.entity.enums.DifficultyLevel;
import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "exercises")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Exercise {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 150)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "muscle_group", length = 100)
    private String muscleGroup;

    @Enumerated(EnumType.STRING)
    @Column(name = "difficulty_level")
    private DifficultyLevel difficultyLevel;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "machine_id")
    private Machine machine;

    @Column(name = "image_url", length = 500)
    private String imageUrl;

    // ── Relationships ──────────────────────────────────────

    @OneToMany(mappedBy = "exercise", fetch = FetchType.LAZY)
    @Builder.Default
    private List<TrainingProgramExercise> programExercises = new ArrayList<>();
}
