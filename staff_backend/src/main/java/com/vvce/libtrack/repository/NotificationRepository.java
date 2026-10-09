package com.vvce.libtrack.repository;

import com.vvce.libtrack.entity.LibNotification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface NotificationRepository extends JpaRepository<LibNotification, Long> {

    @Query("SELECT n FROM LibNotification n WHERE n.staffId = :staffId OR n.staffId IS NULL ORDER BY n.time DESC")
    List<LibNotification> findAllForStaff(@Param("staffId") String staffId);
}
