package com.gymapp.complaint.dto;

import com.gymapp.complaint.entity.enums.ComplaintStatus;
import lombok.Data;

@Data
public class RespondComplaintRequest {
    private String response;
    private ComplaintStatus status;
}
