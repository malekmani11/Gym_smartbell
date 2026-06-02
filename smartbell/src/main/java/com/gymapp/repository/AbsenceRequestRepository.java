package com.gymapp.repository;

import com.gymapp.entity.AbsenceRequest;
import com.gymapp.entity.enums.AbsenceStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AbsenceRequestRepository extends JpaRepository<AbsenceRequest, Long> {

    Page<AbsenceRequest> findByCoachId(Long coachId, Pageable pageable);

    Page<AbsenceRequest> findByStatus(AbsenceStatus status, Pageable pageable);
}
