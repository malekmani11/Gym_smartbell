package com.gymapp.machine.service;

import com.gymapp.machine.dto.SalleDTO;
import com.gymapp.machine.dto.SalleOccupancyDTO;
import com.gymapp.machine.entity.enums.SalleStatus;

import java.util.List;

public interface SalleService {

    List<SalleDTO> getAll();

    List<SalleDTO> getByStatus(SalleStatus status);

    SalleDTO getById(Long id);

    SalleDTO create(SalleDTO dto);

    SalleDTO update(Long id, SalleDTO dto);

    void delete(Long id);

    SalleOccupancyDTO getOccupancy(Long salleId);

    List<SalleOccupancyDTO> getAllOccupancies();
}
