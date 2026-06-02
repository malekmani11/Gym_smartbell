package com.gymapp.complaint.mapper;

import com.gymapp.complaint.dto.ComplaintDTO;
import com.gymapp.complaint.entity.Complaint;
import org.springframework.stereotype.Component;

@Component
public class EntityMapper {

    public ComplaintDTO toComplaintDTO(Complaint complaint) {
        if (complaint == null) return null;
        return ComplaintDTO.builder()
                .id(complaint.getId())
                .userId(complaint.getUser() != null ? complaint.getUser().getId() : null)
                .firstName(complaint.getUser() != null ? complaint.getUser().getFirstName() : null)
                .lastName(complaint.getUser() != null ? complaint.getUser().getLastName() : null)
                .userName(complaint.getUser() != null
                        ? complaint.getUser().getFirstName() + " " + complaint.getUser().getLastName() : null)
                .subject(complaint.getSubject())
                .description(complaint.getDescription())
                .status(complaint.getStatus())
                .response(complaint.getResponse())
                .createdAt(complaint.getCreatedAt())
                .resolvedAt(complaint.getResolvedAt())
                .build();
    }
}
