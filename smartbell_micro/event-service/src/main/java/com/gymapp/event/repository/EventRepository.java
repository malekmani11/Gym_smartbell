package com.gymapp.event.repository;

import com.gymapp.event.entity.Event;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface EventRepository extends JpaRepository<Event, Long> {

    Page<Event> findByActiveTrue(Pageable pageable);

    List<Event> findByEventDateAfterAndActiveTrue(LocalDateTime date);

    Page<Event> findByCreatedById(Long userId, Pageable pageable);
}
