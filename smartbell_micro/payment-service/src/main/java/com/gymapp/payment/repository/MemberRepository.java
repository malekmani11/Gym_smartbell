package com.gymapp.payment.repository;

import com.gymapp.payment.entity.User;
import com.gymapp.payment.entity.enums.Gender;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface MemberRepository extends JpaRepository<User, Long> {

    @Query("SELECT COUNT(u) FROM User u WHERE u.gender = :gender")
    long countByGender(@Param("gender") Gender gender);
}
