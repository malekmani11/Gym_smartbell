package com.gymapp.complaint.service.impl;

import com.gymapp.complaint.dto.ComplaintDTO;
import com.gymapp.complaint.entity.Complaint;
import com.gymapp.complaint.entity.User;
import com.gymapp.complaint.entity.enums.ComplaintStatus;
import com.gymapp.complaint.mapper.EntityMapper;
import com.gymapp.complaint.repository.ComplaintRepository;
import com.gymapp.complaint.repository.UserRepository;
import com.gymapp.complaint.service.ComplaintService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class ComplaintServiceImpl implements ComplaintService {

    private final ComplaintRepository complaintRepository;
    private final UserRepository userRepository;
    private final EntityMapper mapper;

    @Override
    public ComplaintDTO createComplaint(Long userId, ComplaintDTO dto) {
        log.info("User {} creating complaint: {}", userId, dto.getSubject());
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User not found"));

        Complaint complaint = Complaint.builder()
                .user(user)
                .subject(dto.getSubject())
                .description(dto.getDescription())
                .status(ComplaintStatus.OPEN)
                .build();

        return mapper.toComplaintDTO(complaintRepository.save(complaint));
    }

    @Override
    @Transactional(readOnly = true)
    public ComplaintDTO getComplaintById(Long id) {
        return mapper.toComplaintDTO(complaintRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Complaint not found")));
    }

    @Override
    @Transactional(readOnly = true)
    public Page<ComplaintDTO> getComplaintsByUser(Long userId, Pageable pageable) {
        return complaintRepository.findByUserId(userId, pageable).map(mapper::toComplaintDTO);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<ComplaintDTO> getComplaintsByStatus(ComplaintStatus status, Pageable pageable) {
        return complaintRepository.findByStatus(status, pageable).map(mapper::toComplaintDTO);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<ComplaintDTO> getAllComplaints(Pageable pageable) {
        return complaintRepository.findAll(pageable).map(mapper::toComplaintDTO);
    }

    @Override
    public ComplaintDTO respondToComplaint(Long id, String response, ComplaintStatus status) {
        log.info("Responding to complaint: {} with status: {}", id, status);
        Complaint complaint = complaintRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Complaint not found"));

        complaint.setResponse(response);
        complaint.setStatus(status);
        if (status == ComplaintStatus.RESOLVED || status == ComplaintStatus.CLOSED) {
            complaint.setResolvedAt(LocalDateTime.now());
        }

        return mapper.toComplaintDTO(complaintRepository.save(complaint));
    }

    @Override
    public ComplaintDTO markAsRead(Long id) {
        log.info("Marking complaint {} as read", id);
        if (id == null) throw new EntityNotFoundException("Complaint id is null");
        Complaint complaint = complaintRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Complaint not found"));
        if (complaint.getStatus() == ComplaintStatus.OPEN) {
            complaint.setStatus(ComplaintStatus.IN_PROGRESS);
            return mapper.toComplaintDTO(complaintRepository.save(complaint));
        }
        return mapper.toComplaintDTO(complaint);
    }
}
