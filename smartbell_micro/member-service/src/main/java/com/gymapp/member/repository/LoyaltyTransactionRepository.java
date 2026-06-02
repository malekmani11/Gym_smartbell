package com.gymapp.member.repository;

import com.gymapp.member.entity.LoyaltyTransaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface LoyaltyTransactionRepository extends JpaRepository<LoyaltyTransaction, Long> {

    Page<LoyaltyTransaction> findByMemberIdOrderByCreatedAtDesc(Long memberId, Pageable pageable);

    @Query("SELECT COALESCE(SUM(CASE WHEN t.type = 'EARN' OR t.type = 'ADMIN_ADJUST' THEN t.points ELSE 0 END), 0) FROM LoyaltyTransaction t WHERE t.member.id = :memberId")
    Integer sumEarnedPoints(@Param("memberId") Long memberId);

    @Query("SELECT COALESCE(SUM(CASE WHEN t.type = 'REDEEM' OR t.type = 'EXPIRE' THEN t.points ELSE 0 END), 0) FROM LoyaltyTransaction t WHERE t.member.id = :memberId")
    Integer sumRedeemedPoints(@Param("memberId") Long memberId);
}
