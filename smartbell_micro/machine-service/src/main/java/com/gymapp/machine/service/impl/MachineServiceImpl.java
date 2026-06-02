package com.gymapp.machine.service.impl;

import com.gymapp.machine.dto.MachineDTO;
import com.gymapp.machine.entity.Machine;
import com.gymapp.machine.entity.enums.MachineStatus;
import com.gymapp.machine.repository.MachineRepository;
import com.gymapp.machine.service.MachineService;
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
public class MachineServiceImpl implements MachineService {

    private final MachineRepository machineRepository;

    @Override
    @Transactional(readOnly = true)
    public List<MachineDTO> getAll() {
        return machineRepository.findAll().stream().map(this::toDTO).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<MachineDTO> getByStatus(MachineStatus status) {
        return machineRepository.findByStatus(status).stream().map(this::toDTO).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public MachineDTO getById(Long id) {
        return toDTO(machineRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Machine not found with id: " + id)));
    }

    @Override
    public MachineDTO create(MachineDTO dto) {
        Machine machine = Machine.builder()
                .name(dto.getName())
                .description(dto.getDescription())
                .location(dto.getLocation())
                .status(dto.getStatus() != null ? dto.getStatus() : MachineStatus.AVAILABLE)
                .imageUrl(dto.getImageUrl())
                .tutorialUrl(dto.getTutorialUrl())
                .build();
        return toDTO(machineRepository.save(machine));
    }

    @Override
    public MachineDTO update(Long id, MachineDTO dto) {
        Machine machine = machineRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Machine not found with id: " + id));
        if (dto.getName() != null)        machine.setName(dto.getName());
        if (dto.getDescription() != null) machine.setDescription(dto.getDescription());
        if (dto.getLocation() != null)    machine.setLocation(dto.getLocation());
        if (dto.getStatus() != null)      machine.setStatus(dto.getStatus());
        if (dto.getImageUrl() != null)    machine.setImageUrl(dto.getImageUrl());
        if (dto.getTutorialUrl() != null) machine.setTutorialUrl(dto.getTutorialUrl());
        return toDTO(machineRepository.save(machine));
    }

    @Override
    public void delete(Long id) {
        if (!machineRepository.existsById(id)) {
            throw new EntityNotFoundException("Machine not found with id: " + id);
        }
        machineRepository.deleteById(id);
    }

    @Override
    @Transactional(readOnly = true)
    public String getQrCodeData(Long id) {
        Machine machine = machineRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Machine not found with id: " + id));
        if (machine.getQrCode() != null) {
            return machine.getQrCode().getQrData();
        }
        return "MACHINE-" + id + "-" + machine.getName().replaceAll("\\s+", "_").toUpperCase();
    }

    private MachineDTO toDTO(Machine m) {
        return MachineDTO.builder()
                .id(m.getId())
                .name(m.getName())
                .description(m.getDescription())
                .location(m.getLocation())
                .status(m.getStatus())
                .imageUrl(m.getImageUrl())
                .tutorialUrl(m.getTutorialUrl())
                .qrCodeData(m.getQrCode() != null ? m.getQrCode().getQrData() : null)
                .build();
    }
}
