package com.gymapp.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CoachStatsDto {

    private int totalCourses;
    private int totalEnrollments;
    private int activeMembers;
    private double avgOccupancyRate;
}
