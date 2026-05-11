package com.gymapp.repository;

import com.gymapp.entity.DeviceToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DeviceTokenRepository extends JpaRepository<DeviceToken, Long> {

    Optional<DeviceToken> findByUserIdAndToken(Long userId, String token);

    @Query("SELECT dt.token FROM DeviceToken dt WHERE dt.user.id = :userId")
    List<String> findTokensByUserId(@Param("userId") Long userId);

    @Query("SELECT dt.token FROM DeviceToken dt")
    List<String> findAllTokens();

    @Query("SELECT dt.token FROM DeviceToken dt WHERE dt.user.role = :role")
    List<String> findTokensByRole(@Param("role") com.gymapp.entity.Role role);

    void deleteByUserIdAndToken(Long userId, String token);
}
