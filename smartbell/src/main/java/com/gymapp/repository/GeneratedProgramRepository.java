package com.gymapp.repository;

import com.gymapp.entity.GeneratedProgram;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface GeneratedProgramRepository extends JpaRepository<GeneratedProgram, Long> {

    List<GeneratedProgram> findByMemberIdOrderByGeneratedAtDesc(Long memberId);
}
