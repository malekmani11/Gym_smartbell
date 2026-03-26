package com.gymapp.repository;

import com.gymapp.entity.Member;
import com.gymapp.entity.enums.MembershipStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface MemberRepository extends JpaRepository<Member, Long> {

    Optional<Member> findByUserId(Long userId);

    Page<Member> findByMembershipStatus(MembershipStatus status, Pageable pageable);

    Boolean existsByUserId(Long userId);
}
