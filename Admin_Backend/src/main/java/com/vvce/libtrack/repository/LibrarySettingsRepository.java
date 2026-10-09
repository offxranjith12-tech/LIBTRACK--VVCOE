package com.vvce.libtrack.repository;

import com.vvce.libtrack.entity.LibrarySettings;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LibrarySettingsRepository extends JpaRepository<LibrarySettings, Long> {
}
