package com.gymapp.repository;

import com.gymapp.entity.CheckIn;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface CheckInRepository extends JpaRepository<CheckIn, Long> {

    List<CheckIn> findByMember_IdOrderByCheckInTimeDesc(Long memberId);

    Page<CheckIn> findAllByOrderByCheckInTimeDesc(Pageable pageable);

    List<CheckIn> findByCheckInTimeBetweenOrderByCheckInTimeDesc(LocalDateTime start, LocalDateTime end);

    long countByCheckInTimeBetween(LocalDateTime start, LocalDateTime end);

    Optional<CheckIn> findFirstByMember_IdAndCheckOutTimeIsNullOrderByCheckInTimeDesc(Long memberId);
}
