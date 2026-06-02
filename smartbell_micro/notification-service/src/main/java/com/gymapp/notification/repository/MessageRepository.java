package com.gymapp.notification.repository;

import com.gymapp.notification.entity.Message;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MessageRepository extends JpaRepository<Message, Long> {

    @Query("SELECT m FROM Message m WHERE (m.sender.id = :userId1 AND m.receiver.id = :userId2) " +
            "OR (m.sender.id = :userId2 AND m.receiver.id = :userId1) ORDER BY m.sentAt ASC")
    List<Message> findConversation(@Param("userId1") Long userId1, @Param("userId2") Long userId2);

    Page<Message> findByReceiverIdAndIsReadFalse(Long receiverId, Pageable pageable);

    @Query("SELECT DISTINCT m.sender.id FROM Message m WHERE m.receiver.id = :userId " +
            "UNION SELECT DISTINCT m.receiver.id FROM Message m WHERE m.sender.id = :userId")
    List<Long> findConversationPartnerIds(@Param("userId") Long userId);

    Long countByReceiverIdAndIsReadFalse(Long receiverId);
}
