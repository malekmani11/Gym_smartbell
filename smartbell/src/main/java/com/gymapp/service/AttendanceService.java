package com.gymapp.service;

import com.gymapp.dto.AttendanceDto;
import com.gymapp.dto.RecordAttendanceRequest;

import java.time.LocalDate;
import java.util.List;

public interface AttendanceService {

    List<AttendanceDto> recordAttendance(Long courseId, RecordAttendanceRequest request);

    List<AttendanceDto> getAttendanceByCourseAndDate(Long courseId, LocalDate date);

    List<AttendanceDto> getAttendanceByMember(Long memberId);
}
