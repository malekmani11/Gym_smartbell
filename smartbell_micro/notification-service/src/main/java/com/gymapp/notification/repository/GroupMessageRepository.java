package com.gymapp.notification.repository;

import com.gymapp.notification.entity.GroupMessage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface GroupMessageRepository extends JpaRepository<GroupMessage, Long> {
    List<GroupMessage> findAllByOrderBySentAtAsc();
}
