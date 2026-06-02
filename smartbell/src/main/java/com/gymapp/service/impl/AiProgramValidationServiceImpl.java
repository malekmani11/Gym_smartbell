package com.gymapp.service.impl;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gymapp.dto.SavedAiProgramDto;
import com.gymapp.dto.SeanceAiDto;
import com.gymapp.dto.ValidateProgramRequest;
import com.gymapp.entity.SavedAiProgram;
import com.gymapp.entity.enums.AiProgramStatus;
import com.gymapp.repository.SavedAiProgramRepository;
import com.gymapp.service.AiProgramValidationService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AiProgramValidationServiceImpl implements AiProgramValidationService {

    private final SavedAiProgramRepository savedAiProgramRepository;
    private final ObjectMapper objectMapper;

    @Override
    @Transactional(readOnly = true)
    public List<SavedAiProgramDto> getProgramsByCoach(Long coachId, AiProgramStatus status) {
        List<SavedAiProgram> programs = (status != null)
                ? savedAiProgramRepository.findByCoachIdAndStatus(coachId, status)
                : savedAiProgramRepository.findByCoachId(coachId);
        return programs.stream().map(this::toDto).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<SavedAiProgramDto> getProgramsByMember(Long memberId) {
        return savedAiProgramRepository.findByMemberId(memberId)
                .stream().map(this::toDto).collect(Collectors.toList());
    }

    @Override
    @Transactional
    public SavedAiProgramDto validateProgram(Long programId, Long coachId, ValidateProgramRequest request) {
        SavedAiProgram program = savedAiProgramRepository.findById(programId)
                .orElseThrow(() -> new EntityNotFoundException("Programme introuvable : " + programId));

        if (!program.getCoachId().equals(coachId)) {
            throw new IllegalStateException("Ce programme n'appartient pas à ce coach");
        }
        if (request.getStatus() == AiProgramStatus.PENDING) {
            throw new IllegalArgumentException("Le statut doit être APPROVED ou REJECTED");
        }

        program.setStatus(request.getStatus());
        program.setCoachComment(request.getCoachComment());
        program.setValidatedAt(LocalDateTime.now());
        savedAiProgramRepository.save(program);

        log.info("Programme {} {} par le coach {}", programId, request.getStatus(), coachId);
        return toDto(program);
    }

    private SavedAiProgramDto toDto(SavedAiProgram p) {
        List<SeanceAiDto> seances = Collections.emptyList();
        try {
            if (p.getProgramJson() != null) {
                seances = objectMapper.readValue(p.getProgramJson(), new TypeReference<>() {});
            }
        } catch (Exception e) {
            log.warn("Impossible de désérialiser les séances du programme {}", p.getId());
        }

        return SavedAiProgramDto.builder()
                .id(p.getId())
                .memberId(p.getMember().getId())
                .memberFirstName(p.getMember().getFirstName())
                .memberLastName(p.getMember().getLastName())
                .coachId(p.getCoachId())
                .status(p.getStatus())
                .seances(seances)
                .noteCoach(p.getNoteCoach())
                .typeProgramme(p.getTypeProgramme())
                .intensite(p.getIntensite() != null ? p.getIntensite() : 0)
                .split(p.getSplit())
                .imc(p.getImc() != null ? p.getImc() : 0.0)
                .imcCategorie(p.getImcCategorie())
                .coachComment(p.getCoachComment())
                .createdAt(p.getCreatedAt())
                .validatedAt(p.getValidatedAt())
                .build();
    }
}
