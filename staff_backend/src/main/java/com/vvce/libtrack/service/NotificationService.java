package com.vvce.libtrack.service;

import com.vvce.libtrack.dto.NotificationDto;
import com.vvce.libtrack.entity.LibNotification;
import com.vvce.libtrack.exception.ResourceNotFoundException;
import com.vvce.libtrack.repository.NotificationRepository;
import com.vvce.libtrack.repository.StaffRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final StaffRepository staffRepository;

    /** Powers the Notifications screen. Accepts the authenticated username and
     *  resolves it to the staffId used to target notifications. */
    public List<NotificationDto> getAll(String username) {
        String staffId = resolveStaffId(username);
        return notificationRepository.findAllForStaff(staffId).stream().map(NotificationDto::from).toList();
    }

    @Transactional
    public void markRead(Long id) {
        LibNotification n = notificationRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("No notification with id: " + id));
        n.setIsRead(true);
        notificationRepository.save(n);
    }

    @Transactional
    public void markAllRead(String username) {
        String staffId = resolveStaffId(username);
        List<LibNotification> notifications = notificationRepository.findAllForStaff(staffId);
        notifications.forEach(n -> n.setIsRead(true));
        notificationRepository.saveAll(notifications);
    }

    private String resolveStaffId(String username) {
        return staffRepository.findByUsername(username)
                .map(com.vvce.libtrack.entity.Staff::getStaffId)
                .orElseThrow(() -> new ResourceNotFoundException("Staff not found: " + username));
    }
}
