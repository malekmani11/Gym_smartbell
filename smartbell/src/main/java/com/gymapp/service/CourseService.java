package com.gymapp.service;

import com.gymapp.dto.CourseDTO;
import com.gymapp.dto.CourseReservationDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.time.LocalDate;

public interface CourseService {

    CourseDTO createCourse(CourseDTO dto);

    CourseDTO getCourseById(Long id);

    Page<CourseDTO> getActiveCourses(Pageable pageable);

    Page<CourseDTO> getCoursesByCoach(Long coachId, Pageable pageable);

    CourseDTO updateCourse(Long id, CourseDTO dto);

    void deleteCourse(Long id);

    // Reservations
    CourseReservationDTO createReservation(CourseReservationDTO dto);

    Page<CourseReservationDTO> getReservationsByMember(Long memberId, Pageable pageable);

    CourseReservationDTO cancelReservation(Long reservationId);
}
