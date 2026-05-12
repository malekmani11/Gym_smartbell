package com.gymapp.repository;

import com.gymapp.entity.Course;
import com.gymapp.entity.enums.DayOfWeek;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalTime;
import java.util.List;

@Repository
public interface CourseRepository extends JpaRepository<Course, Long> {

    Page<Course> findByActiveTrue(Pageable pageable);

    List<Course> findByCoachId(Long coachId);

    List<Course> findByDayOfWeekAndActiveTrue(DayOfWeek dayOfWeek);

    Page<Course> findByCoachIdAndActiveTrue(Long coachId, Pageable pageable);

    List<Course> findBySalleIdAndDayOfWeekAndActiveTrue(Long salleId, DayOfWeek dayOfWeek);

    List<Course> findBySalleId(Long salleId);

    boolean existsBySalleId(Long salleId);

    @Query("""
        SELECT c FROM Course c
        WHERE c.salle.id = :salleId
          AND c.dayOfWeek = :dayOfWeek
          AND c.active = true
          AND (:excludeId IS NULL OR c.id <> :excludeId)
          AND c.startTime < :endTime
          AND c.endTime > :startTime
        """)
    List<Course> findOverlappingInSalle(
        @Param("salleId")  Long salleId,
        @Param("dayOfWeek") DayOfWeek dayOfWeek,
        @Param("startTime") LocalTime startTime,
        @Param("endTime")   LocalTime endTime,
        @Param("excludeId") Long excludeId
    );
}
