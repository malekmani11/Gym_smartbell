package com.gymapp.dto;

import com.gymapp.entity.enums.SalleStatus;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SalleDTO {

    private Long id;

    @NotBlank(message = "Salle name is required")
    private String name;

    @Min(value = 1, message = "Capacity must be at least 1")
    private Integer capacity;

    private Integer currentOccupancy;
    private SalleStatus status;
    private String location;
    private String description;

    // Occupancy computed fields
    private Double  occupancyRate;
    private Boolean hasCourses;
    private Integer confirmedReservationsToday;
}
