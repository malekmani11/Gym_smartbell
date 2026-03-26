package com.gymapp.service.impl;

import com.gymapp.dto.MemberDTO;
import com.gymapp.entity.Member;
import com.gymapp.entity.User;
import com.gymapp.entity.enums.MembershipStatus;
import com.gymapp.mapper.EntityMapper;
import com.gymapp.repository.MemberRepository;
import com.gymapp.repository.UserRepository;
import com.gymapp.service.MemberService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class MemberServiceImpl implements MemberService {

    private final MemberRepository memberRepository;
    private final UserRepository userRepository;
    private final EntityMapper mapper;

    @Override
    public MemberDTO createMember(Long userId, MemberDTO dto) {
        log.info("Creating member profile for user: {}", userId);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User not found with id: " + userId));

        if (memberRepository.existsByUserId(userId)) {
            throw new IllegalStateException("Member profile already exists for user: " + userId);
        }

        Member member = Member.builder()
                .user(user)
                .emergencyContact(dto.getEmergencyContact())
                .emergencyPhone(dto.getEmergencyPhone())
                .medicalNotes(dto.getMedicalNotes())
                .membershipStatus(MembershipStatus.ACTIVE)
                .joinDate(dto.getJoinDate())
                .build();

        Member saved = memberRepository.save(member);
        log.info("Member profile created: {}", saved.getId());
        return mapper.toMemberDTO(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public MemberDTO getMemberById(Long id) {
        Member member = memberRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Member not found with id: " + id));
        return mapper.toMemberDTO(member);
    }

    @Override
    @Transactional(readOnly = true)
    public MemberDTO getMemberByUserId(Long userId) {
        Member member = memberRepository.findByUserId(userId)
                .orElseThrow(() -> new EntityNotFoundException("Member not found for user: " + userId));
        return mapper.toMemberDTO(member);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<MemberDTO> getAllMembers(Pageable pageable) {
        return memberRepository.findAll(pageable).map(mapper::toMemberDTO);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<MemberDTO> getMembersByStatus(MembershipStatus status, Pageable pageable) {
        return memberRepository.findByMembershipStatus(status, pageable).map(mapper::toMemberDTO);
    }

    @Override
    public MemberDTO updateMember(Long id, MemberDTO dto) {
        log.info("Updating member: {}", id);
        Member member = memberRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Member not found with id: " + id));

        if (dto.getEmergencyContact() != null)
            member.setEmergencyContact(dto.getEmergencyContact());
        if (dto.getEmergencyPhone() != null)
            member.setEmergencyPhone(dto.getEmergencyPhone());
        if (dto.getMedicalNotes() != null)
            member.setMedicalNotes(dto.getMedicalNotes());

        return mapper.toMemberDTO(memberRepository.save(member));
    }

    @Override
    public void updateMembershipStatus(Long id, MembershipStatus status) {
        log.info("Updating membership status for member {} to {}", id, status);
        Member member = memberRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Member not found with id: " + id));
        member.setMembershipStatus(status);
        memberRepository.save(member);
    }

    @Override
    public void deleteMember(Long id) {
        log.warn("Deleting member: {}", id);
        if (!memberRepository.existsById(id)) {
            throw new EntityNotFoundException("Member not found with id: " + id);
        }
        memberRepository.deleteById(id);
    }
}
