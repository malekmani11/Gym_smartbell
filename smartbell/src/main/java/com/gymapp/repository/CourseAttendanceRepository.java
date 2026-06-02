package com.gymapp.repository;

import com.gymapp.entity.CourseAttendance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface CourseAttendanceRepository extends JpaRepository<CourseAttendance, Long> {

    List<CourseAttendance> findByCourseIdAndSessionDate(Long courseId, LocalDate sessionDate);

    List<CourseAttendance> findByMemberId(Long memberId);

    Optional<CourseAttendance> findByCourseIdAndMemberIdAndSessionDate(Long courseId, Long memberId, LocalDate sessionDate);

    @Query("SELECT COUNT(a) FROM CourseAttendance a WHERE a.course.id = :courseId AND a.sessionDate = :date AND a.present = true")
    long countPresentByCourseAndDate(@Param("courseId") Long courseId, @Param("date") LocalDate date);

    @Query("SELECT a FROM CourseAttendance a WHERE a.course.coach.id = :coachId AND a.sessionDate = :date")
    List<CourseAttendance> findByCoachIdAndSessionDate(@Param("coachId") Long coachId, @Param("date") LocalDate date);
}
