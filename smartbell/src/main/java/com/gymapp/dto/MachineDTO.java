package com.gymapp.dto;

import com.gymapp.entity.enums.MachineStatus;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MachineDTO {

    private Long id;

    @NotBlank(message = "Machine name is required")
    private String name;

    private String description;
    private String location;
    private MachineStatus status;
    private String imageUrl;
    private String tutorialUrl;
    private String qrCodeData;
}
