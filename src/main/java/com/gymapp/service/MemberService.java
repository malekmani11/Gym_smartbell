package com.gymapp.service;

import com.gymapp.dto.MemberDTO;
import com.gymapp.entity.enums.MembershipStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface MemberService {

    MemberDTO createMember(Long userId, MemberDTO dto);

    MemberDTO getMemberById(Long id);

    MemberDTO getMemberByUserId(Long userId);

    Page<MemberDTO> getAllMembers(Pageable pageable);

    Page<MemberDTO> getMembersByStatus(MembershipStatus status, Pageable pageable);

    MemberDTO updateMember(Long id, MemberDTO dto);

    void updateMembershipStatus(Long id, MembershipStatus status);

    void deleteMember(Long id);
}
