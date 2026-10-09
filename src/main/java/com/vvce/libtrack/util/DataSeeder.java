package com.vvce.libtrack.util;

import com.vvce.libtrack.entity.Admin;
import com.vvce.libtrack.entity.LibrarySettings;
import com.vvce.libtrack.repository.AdminRepository;
import com.vvce.libtrack.repository.LibrarySettingsRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataSeeder implements CommandLineRunner {

    private final AdminRepository adminRepository;
    private final LibrarySettingsRepository librarySettingsRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${libtrack.default-admin.id:VVCE-LIB-ADM-001}")
    private String defaultAdminId;

    @Value("${libtrack.default-admin.password:ChangeMe@123}")
    private String defaultAdminPassword;

    @Override
    public void run(String... args) {
        if (adminRepository.findByAdminId(defaultAdminId).isEmpty()) {
            Admin admin = Admin.builder()
                    .adminId(defaultAdminId)
                    .name("Ranjith Kumar")
                    .email("ranjith.admin@vvce.edu.in")
                    .phone("+91 98765 43210")
                    .password(passwordEncoder.encode(defaultAdminPassword))
                    .role("ADMIN")
                    .build();
            adminRepository.save(admin);
            log.warn("=========================================================");
            log.warn(" Seeded default admin account:");
            log.warn("   adminId : {}", defaultAdminId);
            log.warn("   password: {}", defaultAdminPassword);
            log.warn(" CHANGE THIS PASSWORD before going to production.");
            log.warn("=========================================================");
        }

        if (librarySettingsRepository.findById(1L).isEmpty()) {
            librarySettingsRepository.save(LibrarySettings.builder().id(1L).build());
            log.info("Seeded default library settings (hours 08:30-18:00, Mon-Sat).");
        }
    }
}
