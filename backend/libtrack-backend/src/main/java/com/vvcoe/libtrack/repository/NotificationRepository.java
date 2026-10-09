package com.vvcoe.libtrack.repository;

import com.vvcoe.libtrack.model.Notification;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface NotificationRepository extends JpaRepository<Notification, Long> {
    List<Notification> findByStudentIdOrderByTimestampDesc(Long studentId);
    long countByStudentIdAndIsReadFalse(Long studentId);
}
