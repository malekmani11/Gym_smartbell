package com.gymapp.machine.service;

import com.gymapp.machine.dto.MachineDTO;
import com.gymapp.machine.entity.enums.MachineStatus;

import java.util.List;

public interface MachineService {

    List<MachineDTO> getAll();

    List<MachineDTO> getByStatus(MachineStatus status);

    MachineDTO getById(Long id);

    MachineDTO create(MachineDTO dto);

    MachineDTO update(Long id, MachineDTO dto);

    void delete(Long id);

    String getQrCodeData(Long id);
}
