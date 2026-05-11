package com.gymapp.service.impl;

import com.gymapp.dto.MemberDTO;
import com.gymapp.entity.Member;
import com.gymapp.entity.Role;
import com.gymapp.entity.enums.Gender;
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
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class MemberServiceImpl implements MemberService {

    private final MemberRepository memberRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final EntityMapper mapper;
    private final com.gymapp.repository.RefreshTokenRepository refreshTokenRepository;

    @Override
    public MemberDTO createMember(Long memberId, MemberDTO dto) {
        log.info("Updating member profile: {}", memberId);
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("Member not found with id: " + memberId));

        if (dto.getEmergencyContact() != null) member.setEmergencyContact(dto.getEmergencyContact());
        if (dto.getEmergencyPhone() != null)   member.setEmergencyPhone(dto.getEmergencyPhone());
        if (dto.getMedicalNotes() != null)      member.setMedicalNotes(dto.getMedicalNotes());
        if (dto.getJoinDate() != null)          member.setJoinDate(dto.getJoinDate());

        return mapper.toMemberDTO(memberRepository.save(member));
    }

    @Override
    public MemberDTO createMemberDirect(MemberDTO dto) {
        log.info("Creating member directly: {}", dto.getEmail());

        if (userRepository.existsByEmail(dto.getEmail())) {
            throw new IllegalStateException("Email already exists: " + dto.getEmail());
        }

        String rawPassword = (dto.getPassword() != null && !dto.getPassword().isBlank())
                ? dto.getPassword() : "Gym@123456";

        Member member = Member.builder()
                .firstName(dto.getFirstName())
                .lastName(dto.getLastName())
                .email(dto.getEmail())
                .password(passwordEncoder.encode(rawPassword))
                .phone(dto.getPhone())
                .address(dto.getAddress())
                .dateOfBirth(dto.getDateOfBirth())
                .gender(dto.getGender() != null && !dto.getGender().isBlank() ? Gender.valueOf(dto.getGender()) : null)
                .profileImageUrl(dto.getProfileImageUrl())
                .role(Role.ROLE_MEMBER)
                .enabled(true)
                .emergencyContact(dto.getEmergencyContact())
                .emergencyPhone(dto.getEmergencyPhone())
                .medicalNotes(dto.getMedicalNotes())
                .membershipStatus(MembershipStatus.ACTIVE)
                .joinDate(dto.getJoinDate() != null ? dto.getJoinDate() : LocalDate.now())
                .build();

        return mapper.toMemberDTO(memberRepository.save(member));
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
        return getMemberById(userId);
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
    @Transactional(readOnly = true)
    public Page<MemberDTO> searchMembers(String query, Pageable pageable) {
        return memberRepository.searchMembers(query, pageable).map(mapper::toMemberDTO);
    }

    @Override
    public MemberDTO updateMember(Long id, MemberDTO dto) {
        log.info("Updating member: {}", id);
        Member member = memberRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Member not found with id: " + id));

        // Basic user fields
        if (dto.getFirstName() != null) member.setFirstName(dto.getFirstName());
        if (dto.getLastName() != null)  member.setLastName(dto.getLastName());
        if (dto.getEmail() != null) {
            if (userRepository.existsByEmailAndIdNot(dto.getEmail(), member.getId())) {
                throw new IllegalStateException("Cet email est déjà utilisé");
            }
            member.setEmail(dto.getEmail());
        }
        if (dto.getPhone() != null)     member.setPhone(dto.getPhone());
        if (dto.getAddress() != null)   member.setAddress(dto.getAddress());
        if (dto.getDateOfBirth() != null) member.setDateOfBirth(dto.getDateOfBirth());
        if (dto.getGender() != null && !dto.getGender().isBlank()) member.setGender(Gender.valueOf(dto.getGender()));
        if (dto.getProfileImageUrl() != null) member.setProfileImageUrl(dto.getProfileImageUrl());

        // Member specific fields
        if (dto.getEmergencyContact() != null) member.setEmergencyContact(dto.getEmergencyContact());
        if (dto.getEmergencyPhone() != null)   member.setEmergencyPhone(dto.getEmergencyPhone());
        if (dto.getMedicalNotes() != null)      member.setMedicalNotes(dto.getMedicalNotes());
        if (dto.getMembershipStatus() != null)  member.setMembershipStatus(dto.getMembershipStatus());
        if (dto.getJoinDate() != null)          member.setJoinDate(dto.getJoinDate());

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
        Member member = memberRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Member not found with id: " + id));
        refreshTokenRepository.deleteByUser(member);
        memberRepository.delete(member);
    }
}
