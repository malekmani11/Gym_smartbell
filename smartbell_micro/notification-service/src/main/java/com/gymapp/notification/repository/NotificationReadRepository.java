package com.gymapp.notification.repository;

import com.gymapp.notification.entity.NotificationRead;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Set;

@Repository
public interface NotificationReadRepository extends JpaRepository<NotificationRead, Long> {

    boolean existsByBroadcastIdAndUserId(Long broadcastId, Long userId);

    void deleteAllByBroadcastId(Long broadcastId);

    /** IDs de tous les broadcasts lus par cet utilisateur */
    @Query("SELECT r.broadcast.id FROM NotificationRead r WHERE r.user.id = :userId")
    Set<Long> findReadBroadcastIdsByUserId(@Param("userId") Long userId);

    /** Nombre de broadcasts non lus par cet utilisateur parmi ceux qui le concernent */
    @Query("SELECT COUNT(n) FROM NotificationBroadcast n WHERE " +
           "(n.targetAll = true OR n.targetRole = :role OR n.targetUserId = :userId) AND " +
           "n.id NOT IN (SELECT r.broadcast.id FROM NotificationRead r WHERE r.user.id = :userId)")
    long countUnreadForUser(@Param("role") com.gymapp.notification.entity.Role role, @Param("userId") Long userId);
}
