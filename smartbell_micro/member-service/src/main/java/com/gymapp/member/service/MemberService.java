package com.gymapp.member.service;

import com.gymapp.member.dto.MeasurementDTO;
import com.gymapp.member.dto.MemberDTO;
import com.gymapp.member.entity.enums.MembershipStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.List;

public interface MemberService {

    MemberDTO createMember(Long userId, MemberDTO dto);

    MemberDTO createMemberDirect(MemberDTO dto);

    MemberDTO getMemberById(Long id);

    MemberDTO getMemberByUserId(Long userId);

    Page<MemberDTO> getAllMembers(Pageable pageable);

    Page<MemberDTO> getMembersByStatus(MembershipStatus status, Pageable pageable);

    Page<MemberDTO> searchMembers(String query, Pageable pageable);

    MemberDTO updateMember(Long id, MemberDTO dto);

    void updateMembershipStatus(Long id, MembershipStatus status);

    void assignCoach(Long memberId, Long coachId);

    void setMessagingEnabled(Long memberId, boolean enabled);

    void deleteMember(Long id);

    List<MeasurementDTO> getMeasurements(Long memberId);

    MeasurementDTO addMeasurement(Long memberId, MeasurementDTO dto);

    void deleteMeasurement(Long memberId, Long measurementId);
}
