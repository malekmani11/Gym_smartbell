package com.gymapp.repository;

import com.gymapp.entity.Salle;
import com.gymapp.entity.enums.SalleStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SalleRepository extends JpaRepository<Salle, Long> {

    List<Salle> findByStatus(SalleStatus status);
}
