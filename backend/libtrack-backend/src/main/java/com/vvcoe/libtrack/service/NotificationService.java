package com.vvcoe.libtrack.service;

import com.vvcoe.libtrack.model.Notification;
import com.vvcoe.libtrack.repository.NotificationRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;

    public NotificationService(NotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    public List<Notification> getForStudent(Long studentId) {
        return notificationRepository.findByStudentIdOrderByTimestampDesc(studentId);
    }

    public Notification markRead(Long notificationId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new ResourceNotFoundException("Notification not found: " + notificationId));
        notification.setIsRead(true);
        return notificationRepository.save(notification);
    }
}
