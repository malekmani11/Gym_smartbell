package com.gymapp.service.impl;

import com.gymapp.dto.SalleDTO;
import com.gymapp.dto.SalleOccupancyDTO;
import com.gymapp.entity.Course;
import com.gymapp.entity.Salle;
import com.gymapp.entity.enums.ReservationStatus;
import com.gymapp.entity.enums.SalleStatus;
import com.gymapp.repository.CourseRepository;
import com.gymapp.repository.CourseReservationRepository;
import com.gymapp.repository.SalleRepository;
import com.gymapp.service.SalleService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class SalleServiceImpl implements SalleService {

    private final SalleRepository salleRepository;
    private final CourseRepository courseRepository;
    private final CourseReservationRepository courseReservationRepository;

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

        LocalDate today = LocalDate.now();
        com.gymapp.entity.enums.DayOfWeek todayDow =
                com.gymapp.entity.enums.DayOfWeek.valueOf(today.getDayOfWeek().name());

        List<Course> coursesToday = courseRepository
                .findBySalleIdAndDayOfWeekAndActiveTrue(salleId, todayDow);

        boolean hasCourses = !coursesToday.isEmpty();
        int confirmed = 0;
        Double occupancyRate = null;

        if (hasCourses) {
            for (Course c : coursesToday) {
                Long cnt = courseReservationRepository
                        .countByCourseAndDateAndStatus(c.getId(), today, ReservationStatus.CONFIRMED);
                confirmed += (cnt != null ? cnt.intValue() : 0);
            }
            int totalCapacity = coursesToday.size() * salle.getCapacity();
            if (totalCapacity > 0) {
                double rate = (double) confirmed / totalCapacity * 100.0;
                occupancyRate = Math.min(Math.round(rate * 10.0) / 10.0, 100.0);
            }
        }

        return SalleOccupancyDTO.builder()
                .salleId(salleId)
                .salleName(salle.getName())
                .capacity(salle.getCapacity())
                .currentOccupancy(hasCourses ? confirmed : salle.getCurrentOccupancy())
                .occupancyRate(occupancyRate)
                .hasCourses(hasCourses)
                .totalCoursesToday(coursesToday.size())
                .status(salle.getStatus().name())
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
        LocalDate today = LocalDate.now();
        com.gymapp.entity.enums.DayOfWeek todayDow =
                com.gymapp.entity.enums.DayOfWeek.valueOf(today.getDayOfWeek().name());

        List<Course> coursesToday = courseRepository
                .findBySalleIdAndDayOfWeekAndActiveTrue(s.getId(), todayDow);

        boolean hasCourses = !coursesToday.isEmpty();
        int confirmedToday = 0;
        Double occupancyRate = null;

        if (hasCourses) {
            for (Course course : coursesToday) {
                Long count = courseReservationRepository
                        .countByCourseAndDateAndStatus(course.getId(), today, ReservationStatus.CONFIRMED);
                confirmedToday += (count != null ? count.intValue() : 0);
            }
            if (s.getCapacity() != null && s.getCapacity() > 0) {
                occupancyRate = Math.min(100.0, (double) confirmedToday / s.getCapacity() * 100.0);
            }
        }

        return SalleDTO.builder()
                .id(s.getId())
                .name(s.getName())
                .capacity(s.getCapacity())
                .currentOccupancy(hasCourses ? confirmedToday : s.getCurrentOccupancy())
                .status(s.getStatus())
                .location(s.getLocation())
                .description(s.getDescription())
                .hasCourses(hasCourses)
                .occupancyRate(occupancyRate)
                .confirmedReservationsToday(confirmedToday)
                .build();
    }
}
