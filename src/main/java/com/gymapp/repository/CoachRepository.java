package com.gymapp.repository;

import com.gymapp.entity.Coach;
import com.gymapp.entity.enums.AvailabilityStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CoachRepository extends JpaRepository<Coach, Long> {

    Page<Coach> findByAvailabilityStatus(AvailabilityStatus status, Pageable pageable);
}
