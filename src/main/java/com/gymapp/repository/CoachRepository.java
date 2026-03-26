package com.gymapp.repository;

import com.gymapp.entity.Coach;
import com.gymapp.entity.enums.AvailabilityStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CoachRepository extends JpaRepository<Coach, Long> {

    Optional<Coach> findByUserId(Long userId);

    Page<Coach> findByAvailabilityStatus(AvailabilityStatus status, Pageable pageable);

    Boolean existsByUserId(Long userId);
}
