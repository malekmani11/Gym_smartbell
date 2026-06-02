package com.gymapp.complaint.service;

import com.gymapp.complaint.dto.ComplaintDTO;
import com.gymapp.complaint.entity.enums.ComplaintStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface ComplaintService {

    ComplaintDTO createComplaint(Long userId, ComplaintDTO dto);

    ComplaintDTO getComplaintById(Long id);

    Page<ComplaintDTO> getComplaintsByUser(Long userId, Pageable pageable);

    Page<ComplaintDTO> getComplaintsByStatus(ComplaintStatus status, Pageable pageable);

    Page<ComplaintDTO> getAllComplaints(Pageable pageable);

    ComplaintDTO respondToComplaint(Long id, String response, ComplaintStatus status);

    ComplaintDTO markAsRead(Long id);
}
