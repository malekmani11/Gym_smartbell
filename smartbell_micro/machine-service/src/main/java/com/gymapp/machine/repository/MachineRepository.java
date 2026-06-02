package com.gymapp.machine.repository;

import com.gymapp.machine.entity.Machine;
import com.gymapp.machine.entity.enums.MachineStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MachineRepository extends JpaRepository<Machine, Long> {

    List<Machine> findByStatus(MachineStatus status);

    Page<Machine> findByLocation(String location, Pageable pageable);

    long countByStatus(MachineStatus status);
}
