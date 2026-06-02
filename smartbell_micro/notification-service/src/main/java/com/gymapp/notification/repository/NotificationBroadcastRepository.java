package com.gymapp.notification.repository;

import com.gymapp.notification.entity.NotificationBroadcast;
import com.gymapp.notification.entity.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificationBroadcastRepository extends JpaRepository<NotificationBroadcast, Long> {

    List<NotificationBroadcast> findAllByOrderByCreatedAtDesc();

    long countByIsReadByAdminFalse();

    @Modifying
    @Query("UPDATE NotificationBroadcast n SET n.isReadByAdmin = true WHERE n.isReadByAdmin = false")
    void markAllAsReadByAdmin();

    /** Retourne les broadcasts visibles par un utilisateur donné (targetAll, son rôle, ou son id) */
    @Query("SELECT n FROM NotificationBroadcast n WHERE n.targetAll = true OR n.targetRole = :role OR n.targetUserId = :userId ORDER BY n.createdAt DESC")
    List<NotificationBroadcast> findForUser(@Param("role") Role role, @Param("userId") Long userId);
}
