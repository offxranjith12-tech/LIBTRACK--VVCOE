package com.vvce.libtrack.config;

import com.vvce.libtrack.entity.Staff;
import com.vvce.libtrack.repository.StaffRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Seeds the default staff login on startup using the application's actual
 * {@link PasswordEncoder} bean — never a hand-typed BCrypt string in
 * backup_data.sql. This is what previously broke: a hardcoded hash in backup_data.sql
 * did not actually correspond to "staff123", so every login failed with
 * "Invalid username or password" even though the DB connection and query
 * were both working correctly.
 *
 * Runs once per fresh database (guarded by a username existence check), so
 * it will never overwrite a password a staff member has since changed via
 * "Change Password".
 */
@Component
@RequiredArgsConstructor
public class DefaultStaffSeeder implements CommandLineRunner {

    private static final String DEFAULT_USERNAME = "anitha.r";
    private static final String DEFAULT_PASSWORD = "staff123";

    private final StaffRepository staffRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        if (staffRepository.findByUsername(DEFAULT_USERNAME).isPresent()) {
            return; // already seeded (or the account was created/changed since) — leave it alone
        }

        Staff staff = Staff.builder()
                .staffId("STF-2041")
                .name("Mrs. Anitha R.")
                .department("Computer Science & Engineering")
                .designation("Assistant Professor")
                .email("anitha.r@vvce.ac.in")
                .phone("+91 98765 43210")
                .username(DEFAULT_USERNAME)
                .password(passwordEncoder.encode(DEFAULT_PASSWORD))
                .photoUrl("")
                .build();

        staffRepository.save(staff);
    }
}
