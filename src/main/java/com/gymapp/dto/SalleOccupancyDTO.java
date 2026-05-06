package com.gymapp.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SalleOccupancyDTO {

    private Long    salleId;
    private String  salleName;
    private Integer capacity;
    private Integer currentOccupancy;
    private Double  occupancyRate;
    private Boolean hasCourses;
    private Integer totalCoursesToday;
    private String  status;
}
