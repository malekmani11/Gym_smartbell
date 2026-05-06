package com.gymapp.repository;

import com.gymapp.entity.Member;
import com.gymapp.entity.enums.MembershipStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface MemberRepository extends JpaRepository<Member, Long> {

    @EntityGraph(attributePaths = {"subscriptions", "subscriptions.plan"})
    Page<Member> findByMembershipStatus(MembershipStatus status, Pageable pageable);

    @Override
    @EntityGraph(attributePaths = {"subscriptions", "subscriptions.plan"})
    Page<Member> findAll(Pageable pageable);

    long countByGender(com.gymapp.entity.enums.Gender gender);
}
