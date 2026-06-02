package com.gymapp.service.impl;

import com.gymapp.dto.AttendanceDto;
import com.gymapp.dto.RecordAttendanceRequest;
import com.gymapp.entity.Course;
import com.gymapp.entity.CourseAttendance;
import com.gymapp.entity.Member;
import com.gymapp.repository.CourseAttendanceRepository;
import com.gymapp.repository.CourseRepository;
import com.gymapp.repository.MemberRepository;
import com.gymapp.service.AttendanceService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AttendanceServiceImpl implements AttendanceService {

    private final CourseAttendanceRepository attendanceRepository;
    private final CourseRepository courseRepository;
    private final MemberRepository memberRepository;

    @Override
    @Transactional
    public List<AttendanceDto> recordAttendance(Long courseId, RecordAttendanceRequest request) {
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new EntityNotFoundException("Cours introuvable : " + courseId));

        List<AttendanceDto> result = request.getAttendances().stream().map(entry -> {
            Member member = memberRepository.findById(entry.getMemberId())
                    .orElseThrow(() -> new EntityNotFoundException("Membre introuvable : " + entry.getMemberId()));

            Optional<CourseAttendance> existing = attendanceRepository
                    .findByCourseIdAndMemberIdAndSessionDate(courseId, member.getId(), request.getSessionDate());

            CourseAttendance attendance;
            if (existing.isPresent()) {
                attendance = existing.get();
                attendance.setPresent(entry.getPresent());
                attendance.setNotes(entry.getNotes());
            } else {
                attendance = CourseAttendance.builder()
                        .course(course)
                        .member(member)
                        .sessionDate(request.getSessionDate())
                        .present(entry.getPresent())
                        .notes(entry.getNotes())
                        .build();
            }
            return toDto(attendanceRepository.save(attendance));
        }).collect(Collectors.toList());

        log.info("Présence enregistrée pour le cours {} — session du {}", courseId, request.getSessionDate());
        return result;
    }

    @Override
    @Transactional(readOnly = true)
    public List<AttendanceDto> getAttendanceByCourseAndDate(Long courseId, LocalDate date) {
        return attendanceRepository.findByCourseIdAndSessionDate(courseId, date)
                .stream().map(this::toDto).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<AttendanceDto> getAttendanceByMember(Long memberId) {
        return attendanceRepository.findByMemberId(memberId)
                .stream().map(this::toDto).collect(Collectors.toList());
    }

    private AttendanceDto toDto(CourseAttendance a) {
        return AttendanceDto.builder()
                .id(a.getId())
                .courseId(a.getCourse().getId())
                .courseName(a.getCourse().getName())
                .memberId(a.getMember().getId())
                .memberFirstName(a.getMember().getFirstName())
                .memberLastName(a.getMember().getLastName())
                .sessionDate(a.getSessionDate())
                .present(a.getPresent())
                .notes(a.getNotes())
                .createdAt(a.getCreatedAt())
                .build();
    }
}
