package com.gymapp.service;

import com.gymapp.dto.SalleDTO;
import com.gymapp.dto.SalleOccupancyDTO;
import com.gymapp.entity.enums.SalleStatus;

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
