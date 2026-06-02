package com.gymapp.member.repository;

import com.gymapp.member.entity.CheckIn;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CheckInRepository extends JpaRepository<CheckIn, Long> {
    List<CheckIn> findByMemberIdOrderByCheckInTimeDesc(Long memberId);
}
