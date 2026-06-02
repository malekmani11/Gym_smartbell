package com.gymapp.member.entity;

import com.gymapp.member.entity.enums.Specialization;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;

/**
 * Entité Coach minimale dans member-service.
 * Utilisée UNIQUEMENT pour créer la ligne dans la table "coaches"
 * lors du register (même DB partagée avec coach-service).
 * Les données métier complètes (bio, cours, ratings) sont dans coach-service.
 */
@Entity
@Table(name = "coaches")
@DiscriminatorValue("COACH")
@PrimaryKeyJoinColumn(name = "user_id")
@Getter
@Setter
@NoArgsConstructor
@SuperBuilder
public class Coach extends User {

    @Enumerated(EnumType.STRING)
    @Column(length = 50)
    private Specialization specialization;

    @Column(name = "availability_status", nullable = false, length = 30)
    @Builder.Default
    private String availabilityStatus = "AVAILABLE";
}
