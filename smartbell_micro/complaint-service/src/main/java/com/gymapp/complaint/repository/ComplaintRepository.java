package com.gymapp.complaint.repository;

import com.gymapp.complaint.entity.Complaint;
import com.gymapp.complaint.entity.enums.ComplaintStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ComplaintRepository extends JpaRepository<Complaint, Long> {

    Page<Complaint> findByUserId(Long userId, Pageable pageable);

    Page<Complaint> findByStatus(ComplaintStatus status, Pageable pageable);
}
