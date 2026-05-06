package com.gymapp.repository;

import com.gymapp.entity.CourseReservation;
import com.gymapp.entity.enums.ReservationStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface CourseReservationRepository extends JpaRepository<CourseReservation, Long> {

    Page<CourseReservation> findByMemberId(Long memberId, Pageable pageable);

    List<CourseReservation> findByCourseIdAndReservationDate(Long courseId, LocalDate date);

    @Query("SELECT COUNT(cr) FROM CourseReservation cr WHERE cr.course.id = :courseId AND cr.reservationDate = :date AND cr.status = :status")
    Long countByCourseAndDateAndStatus(@Param("courseId") Long courseId, @Param("date") LocalDate date,
            @Param("status") ReservationStatus status);

    Boolean existsByMemberIdAndCourseIdAndReservationDate(Long memberId, Long courseId, LocalDate date);

    Long countByCourseIdAndStatus(Long courseId, ReservationStatus status);

    Long countByCourseIdAndStatusAndReservationDate(Long courseId, ReservationStatus status, LocalDate reservationDate);
}
