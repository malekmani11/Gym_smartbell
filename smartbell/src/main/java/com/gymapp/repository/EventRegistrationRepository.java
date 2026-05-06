package com.gymapp.repository;

import com.gymapp.entity.EventRegistration;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface EventRegistrationRepository extends JpaRepository<EventRegistration, Long> {

    Page<EventRegistration> findByUserId(Long userId, Pageable pageable);

    List<EventRegistration> findByUserId(Long userId);

    List<EventRegistration> findByEventId(Long eventId);

    Optional<EventRegistration> findByEventIdAndUserId(Long eventId, Long userId);

    Boolean existsByUserIdAndEventId(Long userId, Long eventId);

    Long countByEventId(Long eventId);
}
