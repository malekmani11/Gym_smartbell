package com.gymapp.member.service.impl;

import com.gymapp.member.dto.MeasurementDTO;
import com.gymapp.member.dto.MemberDTO;
import com.gymapp.member.entity.Measurement;
import com.gymapp.member.entity.Member;
import com.gymapp.member.entity.Role;
import com.gymapp.member.entity.enums.Gender;
import com.gymapp.member.entity.enums.MembershipStatus;
import com.gymapp.member.mapper.EntityMapper;
import com.gymapp.member.repository.MeasurementRepository;
import com.gymapp.member.repository.MemberRepository;
import com.gymapp.member.repository.RefreshTokenRepository;
import com.gymapp.member.repository.UserRepository;
import com.gymapp.member.service.MemberService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class MemberServiceImpl implements MemberService {

    private final MemberRepository memberRepository;
    private final MeasurementRepository measurementRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final EntityMapper mapper;
    private final RefreshTokenRepository refreshTokenRepository;

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
    public void assignCoach(Long memberId, Long coachId) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("Member not found with id: " + memberId));
        member.setAssignedCoachId(coachId);
        memberRepository.save(member);
    }

    @Override
    public void setMessagingEnabled(Long memberId, boolean enabled) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("Member not found with id: " + memberId));
        member.setMessagingEnabled(enabled);
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

    @Override
    public List<MeasurementDTO> getMeasurements(Long memberId) {
        return measurementRepository.findByMemberIdOrderByDateAsc(memberId)
                .stream()
                .map(this::toMeasurementDTO)
                .collect(Collectors.toList());
    }

    @Override
    public MeasurementDTO addMeasurement(Long memberId, MeasurementDTO dto) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("Member not found: " + memberId));
        Measurement m = Measurement.builder()
                .member(member)
                .date(dto.getDate() != null ? dto.getDate() : java.time.LocalDate.now())
                .weight(dto.getWeight())
                .height(dto.getHeight())
                .notes(dto.getNotes())
                .build();
        return toMeasurementDTO(measurementRepository.save(m));
    }

    @Override
    public void deleteMeasurement(Long memberId, Long measurementId) {
        Measurement m = measurementRepository.findById(measurementId)
                .orElseThrow(() -> new EntityNotFoundException("Measurement not found: " + measurementId));
        if (!m.getMember().getId().equals(memberId)) {
            throw new EntityNotFoundException("Measurement not found for this member");
        }
        measurementRepository.delete(m);
    }

    private MeasurementDTO toMeasurementDTO(Measurement m) {
        return MeasurementDTO.builder()
                .id(m.getId())
                .memberId(m.getMember().getId())
                .date(m.getDate())
                .weight(m.getWeight())
                .height(m.getHeight())
                .notes(m.getNotes())
                .build();
    }
}
