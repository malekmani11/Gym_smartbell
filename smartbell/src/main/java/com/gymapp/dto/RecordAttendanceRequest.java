package com.gymapp.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDate;
import java.util.List;

@Data
public class RecordAttendanceRequest {

    @NotNull
    private LocalDate sessionDate;

    @NotNull
    private List<MemberAttendance> attendances;

    @Data
    public static class MemberAttendance {
        @NotNull
        private Long memberId;
        @NotNull
        private Boolean present;
        private String notes;
    }
}
