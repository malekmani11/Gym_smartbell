package com.gymapp.service.impl;

import com.gymapp.dto.CourseDTO;
import com.gymapp.dto.CourseReservationDTO;
import com.gymapp.entity.*;
import com.gymapp.entity.enums.ReservationStatus;
import com.gymapp.mapper.EntityMapper;
import com.gymapp.repository.*;
import com.gymapp.service.CourseService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class CourseServiceImpl implements CourseService {

    private final CourseRepository courseRepository;
    private final CourseReservationRepository reservationRepository;
    private final CoachRepository coachRepository;
    private final MemberRepository memberRepository;
    private final EntityMapper mapper;

    @Override
    public CourseDTO createCourse(CourseDTO dto) {
        log.info("Creating course: {}", dto.getName());
        Coach coach = coachRepository.findById(dto.getCoachId())
                .orElseThrow(() -> new EntityNotFoundException("Coach not found"));

        Course course = Course.builder()
                .name(dto.getName())
                .description(dto.getDescription())
                .coach(coach)
                .dayOfWeek(dto.getDayOfWeek())
                .startTime(dto.getStartTime())
                .endTime(dto.getEndTime())
                .maxParticipants(dto.getMaxParticipants())
                .location(dto.getLocation())
                .active(true)
                .build();

        return mapper.toCourseDTO(courseRepository.save(course));
    }

    @Override
    @Transactional(readOnly = true)
    public CourseDTO getCourseById(Long id) {
        return mapper.toCourseDTO(courseRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Course not found with id: " + id)));
    }

    @Override
    @Transactional(readOnly = true)
    public Page<CourseDTO> getActiveCourses(Pageable pageable) {
        return courseRepository.findByActiveTrue(pageable).map(mapper::toCourseDTO);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<CourseDTO> getCoursesByCoach(Long coachId, Pageable pageable) {
        return courseRepository.findByCoachIdAndActiveTrue(coachId, pageable).map(mapper::toCourseDTO);
    }

    @Override
    public CourseDTO updateCourse(Long id, CourseDTO dto) {
        log.info("Updating course: {}", id);
        Course course = courseRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Course not found with id: " + id));

        if (dto.getName() != null)
            course.setName(dto.getName());
        if (dto.getDescription() != null)
            course.setDescription(dto.getDescription());
        if (dto.getDayOfWeek() != null)
            course.setDayOfWeek(dto.getDayOfWeek());
        if (dto.getStartTime() != null)
            course.setStartTime(dto.getStartTime());
        if (dto.getEndTime() != null)
            course.setEndTime(dto.getEndTime());
        if (dto.getMaxParticipants() != null)
            course.setMaxParticipants(dto.getMaxParticipants());
        if (dto.getLocation() != null)
            course.setLocation(dto.getLocation());
        if (dto.getActive() != null)
            course.setActive(dto.getActive());

        return mapper.toCourseDTO(courseRepository.save(course));
    }

    @Override
    public void deleteCourse(Long id) {
        if (!courseRepository.existsById(id)) {
            throw new EntityNotFoundException("Course not found with id: " + id);
        }
        courseRepository.deleteById(id);
    }

    @Override
    public CourseReservationDTO createReservation(CourseReservationDTO dto) {
        log.info("Creating reservation for course {} by member {}", dto.getCourseId(), dto.getMemberId());

        Course course = courseRepository.findById(dto.getCourseId())
                .orElseThrow(() -> new EntityNotFoundException("Course not found"));
        Member member = memberRepository.findById(dto.getMemberId())
                .orElseThrow(() -> new EntityNotFoundException("Member not found"));

        // Check duplicate reservation
        if (reservationRepository.existsByMemberIdAndCourseIdAndReservationDate(
                dto.getMemberId(), dto.getCourseId(), dto.getReservationDate())) {
            throw new IllegalStateException("Member already has a reservation for this course on this date");
        }

        // Check capacity
        Long confirmedCount = reservationRepository.countByCourseAndDateAndStatus(
                dto.getCourseId(), dto.getReservationDate(), ReservationStatus.CONFIRMED);
        if (confirmedCount >= course.getMaxParticipants()) {
            throw new IllegalStateException("Course is full for this date");
        }

        CourseReservation reservation = CourseReservation.builder()
                .course(course)
                .member(member)
                .reservationDate(dto.getReservationDate())
                .status(ReservationStatus.CONFIRMED)
                .build();

        return mapper.toCourseReservationDTO(reservationRepository.save(reservation));
    }

    @Override
    @Transactional(readOnly = true)
    public Page<CourseReservationDTO> getReservationsByMember(Long memberId, Pageable pageable) {
        return reservationRepository.findByMemberId(memberId, pageable).map(mapper::toCourseReservationDTO);
    }

    @Override
    public CourseReservationDTO cancelReservation(Long reservationId) {
        log.info("Cancelling reservation: {}", reservationId);
        CourseReservation reservation = reservationRepository.findById(reservationId)
                .orElseThrow(() -> new EntityNotFoundException("Reservation not found"));
        reservation.setStatus(ReservationStatus.CANCELLED);
        return mapper.toCourseReservationDTO(reservationRepository.save(reservation));
    }
}
