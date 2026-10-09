package com.vvce.libtrack.service;

import com.vvce.libtrack.config.JwtUtil;
import com.vvce.libtrack.dto.LoginRequest;
import com.vvce.libtrack.dto.LoginResponse;
import com.vvce.libtrack.entity.Admin;
import com.vvce.libtrack.entity.Staff;
import com.vvce.libtrack.entity.Student;
import com.vvce.libtrack.exception.InvalidCredentialsException;
import com.vvce.libtrack.repository.AdminRepository;
import com.vvce.libtrack.repository.StaffRepository;
import com.vvce.libtrack.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final AdminRepository adminRepository;
    private final StaffRepository staffRepository;
    private final StudentRepository studentRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    /**
     * Single login endpoint for every role in LibTrack:
     *   - Admin logs in with their Admin ID
     *   - Every Librarian / Staff member logs in with their own staffId
     *   - Students log in with their register number
     * Each role's password is checked against its own hashed record — no
     * personal Gmail accounts are ever involved, only the college-issued ID.
     */
    public LoginResponse login(LoginRequest request) {
        String id = request.getAdminId().trim();

        var admin = adminRepository.findByAdminId(id);
        if (admin.isPresent()) {
            return loginAsAdmin(admin.get(), request.getPassword());
        }

        var staff = staffRepository.findByStaffId(id);
        if (staff.isPresent()) {
            return loginAsStaff(staff.get(), request.getPassword());
        }

        var student = studentRepository.findByRegisterNumber(id);
        if (student.isPresent()) {
            return loginAsStudent(student.get(), request.getPassword());
        }

        throw new InvalidCredentialsException("Invalid ID or password");
    }

    private LoginResponse loginAsAdmin(Admin admin, String rawPassword) {
        if (!passwordEncoder.matches(rawPassword, admin.getPassword())) {
            throw new InvalidCredentialsException("Invalid ID or password");
        }
        String token = jwtUtil.generateToken(admin.getAdminId(), admin.getRole());
        return LoginResponse.builder()
                .token(token)
                .adminId(admin.getAdminId())
                .name(admin.getName())
                .role(admin.getRole())
                .userType("ADMIN")
                .expiresInMs(jwtUtil.getExpirationMs())
                .build();
    }

    private LoginResponse loginAsStaff(Staff staff, String rawPassword) {
        if (staff.getPassword() == null || !passwordEncoder.matches(rawPassword, staff.getPassword())) {
            throw new InvalidCredentialsException("Invalid ID or password");
        }
        if ("BLOCKED".equalsIgnoreCase(staff.getStatus())) {
            throw new InvalidCredentialsException("This account has been blocked by the library admin");
        }
        String role = staff.getRole() == null ? "STAFF" : staff.getRole();
        String token = jwtUtil.generateToken(staff.getStaffId(), role);
        return LoginResponse.builder()
                .token(token)
                .adminId(staff.getStaffId())
                .name(staff.getName())
                .role(role)
                .userType(role)
                .expiresInMs(jwtUtil.getExpirationMs())
                .build();
    }

    private LoginResponse loginAsStudent(Student student, String rawPassword) {
        if (student.getPassword() == null || !passwordEncoder.matches(rawPassword, student.getPassword())) {
            throw new InvalidCredentialsException("Invalid ID or password");
        }
        if ("BLOCKED".equalsIgnoreCase(student.getStatus())) {
            throw new InvalidCredentialsException("This account has been blocked by the library admin");
        }
        String token = jwtUtil.generateToken(student.getRegisterNumber(), "STUDENT");
        return LoginResponse.builder()
                .token(token)
                .adminId(student.getRegisterNumber())
                .name(student.getName())
                .role("STUDENT")
                .userType("STUDENT")
                .expiresInMs(jwtUtil.getExpirationMs())
                .build();
    }
}
