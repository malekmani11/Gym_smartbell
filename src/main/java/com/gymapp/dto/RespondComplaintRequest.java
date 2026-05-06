package com.gymapp.dto;

import com.gymapp.entity.enums.ComplaintStatus;
import lombok.Data;

@Data
public class RespondComplaintRequest {
    private String response;
    private ComplaintStatus status;
}
