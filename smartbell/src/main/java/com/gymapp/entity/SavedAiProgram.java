package com.gymapp.entity;

import com.gymapp.entity.enums.AiProgramStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "saved_ai_programs")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SavedAiProgram {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "member_id", nullable = false)
    private Member member;

    @Column(name = "coach_id")
    private Long coachId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private AiProgramStatus status = AiProgramStatus.PENDING;

    @Column(name = "program_json", columnDefinition = "TEXT", nullable = false)
    private String programJson;

    @Column(name = "note_coach", columnDefinition = "TEXT")
    private String noteCoach;

    @Column(name = "type_programme", length = 50)
    private String typeProgramme;

    private Integer intensite;

    @Column(length = 100)
    private String split;

    private Double imc;

    @Column(name = "imc_categorie", length = 50)
    private String imcCategorie;

    @Column(name = "coach_comment", columnDefinition = "TEXT")
    private String coachComment;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "validated_at")
    private LocalDateTime validatedAt;
}
