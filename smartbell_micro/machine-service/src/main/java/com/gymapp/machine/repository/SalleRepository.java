package com.gymapp.machine.repository;

import com.gymapp.machine.entity.Salle;
import com.gymapp.machine.entity.enums.SalleStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SalleRepository extends JpaRepository<Salle, Long> {

    List<Salle> findByStatus(SalleStatus status);
}
