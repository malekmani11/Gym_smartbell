package com.gymapp.member.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;

import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MeasurementDTO {
    private Long id;
    private Long memberId;
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate date;
    private Double weight;
    private Double height;
    private String notes;
}
