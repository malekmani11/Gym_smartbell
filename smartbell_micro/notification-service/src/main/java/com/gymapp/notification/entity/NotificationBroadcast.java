package com.gymapp.notification.entity;

import com.gymapp.notification.entity.enums.NotificationType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "notification_broadcasts")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationBroadcast {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String message;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private NotificationType type = NotificationType.INFO;

    /** true → tous les utilisateurs */
    @Column(name = "target_all", nullable = false)
    @Builder.Default
    private Boolean targetAll = false;

    /** non null → envoyé à un rôle spécifique */
    @Enumerated(EnumType.STRING)
    @Column(name = "target_role")
    private Role targetRole;

    /** non null → envoyé à un utilisateur spécifique */
    @Column(name = "target_user_id")
    private Long targetUserId;

    /** true quand l'admin a marqué cette diffusion comme lue dans son panneau */
    @Column(name = "is_read_by_admin", nullable = false)
    @Builder.Default
    private Boolean isReadByAdmin = false;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @OneToMany(mappedBy = "broadcast", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<NotificationRead> reads = new ArrayList<>();
}
