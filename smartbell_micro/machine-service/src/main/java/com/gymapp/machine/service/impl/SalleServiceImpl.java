package com.gymapp.machine.service.impl;

import com.gymapp.machine.dto.SalleDTO;
import com.gymapp.machine.dto.SalleOccupancyDTO;
import com.gymapp.machine.entity.Salle;
import com.gymapp.machine.entity.enums.SalleStatus;
import com.gymapp.machine.repository.SalleRepository;
import com.gymapp.machine.service.SalleService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class SalleServiceImpl implements SalleService {

    private final SalleRepository salleRepository;

    @Override
    @Transactional(readOnly = true)
    public List<SalleDTO> getAll() {
        return salleRepository.findAll().stream().map(this::toDTO).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<SalleDTO> getByStatus(SalleStatus status) {
        return salleRepository.findByStatus(status).stream().map(this::toDTO).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public SalleDTO getById(Long id) {
        return toDTO(salleRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Salle not found with id: " + id)));
    }

    @Override
    public SalleDTO create(SalleDTO dto) {
        Salle salle = Salle.builder()
                .name(dto.getName())
                .capacity(dto.getCapacity())
                .currentOccupancy(dto.getCurrentOccupancy() != null ? dto.getCurrentOccupancy() : 0)
                .status(dto.getStatus() != null ? dto.getStatus() : SalleStatus.DISPONIBLE)
                .location(dto.getLocation())
                .description(dto.getDescription())
                .build();
        return toDTO(salleRepository.save(salle));
    }

    @Override
    public SalleDTO update(Long id, SalleDTO dto) {
        Salle salle = salleRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Salle not found with id: " + id));
        if (dto.getName() != null)             salle.setName(dto.getName());
        if (dto.getCapacity() != null)         salle.setCapacity(dto.getCapacity());
        if (dto.getCurrentOccupancy() != null) salle.setCurrentOccupancy(dto.getCurrentOccupancy());
        if (dto.getStatus() != null)           salle.setStatus(dto.getStatus());
        if (dto.getLocation() != null)         salle.setLocation(dto.getLocation());
        if (dto.getDescription() != null)      salle.setDescription(dto.getDescription());
        return toDTO(salleRepository.save(salle));
    }

    @Override
    @Transactional(readOnly = true)
    public SalleOccupancyDTO getOccupancy(Long salleId) {
        Salle salle = salleRepository.findById(salleId)
                .orElseThrow(() -> new EntityNotFoundException("Salle not found with id: " + salleId));

        double occupancyRate = salle.getCapacity() != null && salle.getCapacity() > 0
                ? Math.min(100.0, (double) salle.getCurrentOccupancy() / salle.getCapacity() * 100.0)
                : 0.0;

        return SalleOccupancyDTO.builder()
                .salleId(salleId)
                .salleName(salle.getName())
                .capacity(salle.getCapacity())
                .currentOccupancy(salle.getCurrentOccupancy())
                .occupancyRate(occupancyRate)
                .hasCourses(false)
                .totalCoursesToday(0)
                .status(salle.getStatus() != null ? salle.getStatus().name() : null)
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public List<SalleOccupancyDTO> getAllOccupancies() {
        return salleRepository.findAll().stream()
                .map(s -> getOccupancy(s.getId()))
                .collect(Collectors.toList());
    }

    @Override
    public void delete(Long id) {
        if (!salleRepository.existsById(id)) {
            throw new EntityNotFoundException("Salle not found with id: " + id);
        }
        salleRepository.deleteById(id);
    }

    private SalleDTO toDTO(Salle s) {
        double occupancyRate = s.getCapacity() != null && s.getCapacity() > 0
                ? Math.min(100.0, (double) s.getCurrentOccupancy() / s.getCapacity() * 100.0)
                : 0.0;

        return SalleDTO.builder()
                .id(s.getId())
                .name(s.getName())
                .capacity(s.getCapacity())
                .currentOccupancy(s.getCurrentOccupancy())
                .status(s.getStatus())
                .location(s.getLocation())
                .description(s.getDescription())
                .hasCourses(false)
                .occupancyRate(occupancyRate)
                .confirmedReservationsToday(0)
                .build();
    }
}
