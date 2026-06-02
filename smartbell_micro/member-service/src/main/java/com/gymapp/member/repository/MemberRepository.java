package com.gymapp.member.repository;

import com.gymapp.member.entity.Member;
import com.gymapp.member.entity.enums.Gender;
import com.gymapp.member.entity.enums.MembershipStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface MemberRepository extends JpaRepository<Member, Long> {

    @EntityGraph(attributePaths = {"subscriptions", "subscriptions.plan"})
    Page<Member> findByMembershipStatus(MembershipStatus status, Pageable pageable);

    @Override
    @EntityGraph(attributePaths = {"subscriptions", "subscriptions.plan"})
    Page<Member> findAll(Pageable pageable);

    @Query("SELECT m FROM Member m WHERE " +
           "LOWER(m.firstName) LIKE LOWER(CONCAT('%', :q, '%')) OR " +
           "LOWER(m.lastName)  LIKE LOWER(CONCAT('%', :q, '%')) OR " +
           "LOWER(m.email)     LIKE LOWER(CONCAT('%', :q, '%'))")
    @EntityGraph(attributePaths = {"subscriptions", "subscriptions.plan"})
    Page<Member> searchMembers(@Param("q") String query, Pageable pageable);

    long countByGender(Gender gender);
}
