package com.gymapp.member.repository;

import com.gymapp.member.entity.Coach;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CoachRepository extends JpaRepository<Coach, Long> {

    boolean existsByEmail(String email);
}
