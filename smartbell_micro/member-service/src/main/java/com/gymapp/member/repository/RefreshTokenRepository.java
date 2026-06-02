package com.gymapp.member.repository;

import com.gymapp.member.entity.RefreshToken;
import com.gymapp.member.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Repository pour la gestion des refresh tokens.
 */
@Repository
public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {

    /**
     * Trouve un refresh token par son token string
     */
    Optional<RefreshToken> findByToken(String token);

    /**
     * Trouve tous les refresh tokens valides pour un utilisateur
     */
    List<RefreshToken> findByUserAndIsRevokedFalseAndExpiresAtAfter(User user, LocalDateTime now);

    /**
     * Trouve tous les refresh tokens d'un utilisateur
     */
    List<RefreshToken> findByUser(User user);

    /**
     * Compte les refresh tokens valides pour un utilisateur
     */
    long countByUserAndIsRevokedFalseAndExpiresAtAfter(User user, LocalDateTime now);

    /**
     * Révoque tous les refresh tokens d'un utilisateur
     */
    @Modifying
    @Query("UPDATE RefreshToken r SET r.isRevoked = true WHERE r.user = :user AND r.isRevoked = false")
    int revokeAllByUser(@Param("user") User user);

    /**
     * Supprime les tokens expirés et révoqués
     */
    @Modifying
    @Query("DELETE FROM RefreshToken r WHERE r.expiresAt < :now OR r.isRevoked = true")
    int deleteExpiredOrRevoked(@Param("now") LocalDateTime now);

    /**
     * Trouve les tokens expirés pour nettoyage
     */
    @Query("SELECT r FROM RefreshToken r WHERE r.expiresAt < :now OR r.isRevoked = true")
    List<RefreshToken> findExpiredOrRevoked(@Param("now") LocalDateTime now);

    void deleteByUser(User user);
}
