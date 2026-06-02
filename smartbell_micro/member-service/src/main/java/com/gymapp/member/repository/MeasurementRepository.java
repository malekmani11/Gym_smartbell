package com.gymapp.member.repository;

import com.gymapp.member.entity.Measurement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MeasurementRepository extends JpaRepository<Measurement, Long> {
    List<Measurement> findByMemberIdOrderByDateAsc(Long memberId);
}
