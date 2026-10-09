package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.*;
import com.vvce.libtrack.entity.Admin;
import com.vvce.libtrack.entity.Staff;
import com.vvce.libtrack.entity.Student;
import com.vvce.libtrack.exception.BadRequestException;
import com.vvce.libtrack.exception.ResourceNotFoundException;
import com.vvce.libtrack.repository.AdminRepository;
import com.vvce.libtrack.repository.StaffRepository;
import com.vvce.libtrack.repository.StudentRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

/**
 * "My Profile" — works for whoever is logged in (Admin, Staff, Librarian, or
 * Student), resolved from the JWT rather than a path parameter. This is what
 * powers the Profile screen's Edit Profile / Change Password actions for
 * real, against the actual logged-in account.
 */
@RestController
@RequestMapping("/api/v1/me")
@RequiredArgsConstructor
public class MeController {

    private final AdminRepository adminRepository;
    private final StaffRepository staffRepository;
    private final StudentRepository studentRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${libtrack.uploads.dir:./uploads}")
    private String uploadsDir;

    private static final Set<String> ALLOWED_IMAGE_EXT = Set.of("jpg", "jpeg", "png", "webp");
    private static final long MAX_AVATAR_BYTES = 5L * 1024 * 1024; // 5MB

    @GetMapping
    public ApiResponse<MeProfileResponse> me(Authentication auth) {
        return ApiResponse.ok(resolveProfile(auth));
    }

    @PutMapping
    public ApiResponse<MeProfileResponse> update(Authentication auth, @RequestBody UpdateProfileRequest request) {
        String loginId = auth.getName();
        String role = primaryRole(auth);

        switch (role) {
            case "ADMIN" -> {
                Admin admin = adminRepository.findByAdminId(loginId)
                        .orElseThrow(() -> new ResourceNotFoundException("Admin not found"));
                // Email is the account's permanent college identity and is intentionally
                // immutable from "Edit Profile" — never read from the request body here,
                // even if a client sends one. Only Name/Phone can change.
                if (request.getName() != null) admin.setName(request.getName());
                if (request.getPhone() != null) admin.setPhone(request.getPhone());
                adminRepository.save(admin);
            }
            case "STAFF", "LIBRARIAN" -> {
                Staff staff = staffRepository.findByStaffId(loginId)
                        .orElseThrow(() -> new ResourceNotFoundException("Staff not found"));
                if (request.getName() != null) staff.setName(request.getName());
                if (request.getPhone() != null) staff.setPhone(request.getPhone());
                staffRepository.save(staff);
            }
            case "STUDENT" -> {
                Student student = studentRepository.findByRegisterNumber(loginId)
                        .orElseThrow(() -> new ResourceNotFoundException("Student not found"));
                if (request.getName() != null) student.setName(request.getName());
                if (request.getPhone() != null) student.setPhone(request.getPhone());
                studentRepository.save(student);
            }
            default -> throw new BadRequestException("Unknown role");
        }

        return ApiResponse.ok("Profile updated", resolveProfile(auth));
    }

    @PostMapping("/change-password")
    public ApiResponse<Void> changePassword(Authentication auth, @Valid @RequestBody ChangePasswordRequest request) {
        String loginId = auth.getName();
        String role = primaryRole(auth);

        switch (role) {
            case "ADMIN" -> {
                Admin admin = adminRepository.findByAdminId(loginId)
                        .orElseThrow(() -> new ResourceNotFoundException("Admin not found"));
                verifyAndSet(admin.getPassword(), request, admin::setPassword);
                adminRepository.save(admin);
            }
            case "STAFF", "LIBRARIAN" -> {
                Staff staff = staffRepository.findByStaffId(loginId)
                        .orElseThrow(() -> new ResourceNotFoundException("Staff not found"));
                verifyAndSet(staff.getPassword(), request, staff::setPassword);
                staffRepository.save(staff);
            }
            case "STUDENT" -> {
                Student student = studentRepository.findByRegisterNumber(loginId)
                        .orElseThrow(() -> new ResourceNotFoundException("Student not found"));
                verifyAndSet(student.getPassword(), request, student::setPassword);
                studentRepository.save(student);
            }
            default -> throw new BadRequestException("Unknown role");
        }

        return ApiResponse.ok("Password changed successfully", null);
    }

    /**
     * Uploads/replaces the logged-in user's profile picture. The file is
     * stored on disk (under `libtrack.uploads.dir`, default `./uploads`) and
     * served back statically at `/uploads/avatars/...` (see WebConfig) —
     * the returned `avatarUrl` is a relative path the app resolves against
     * the backend's own host.
     */
    @PostMapping(value = "/avatar", consumes = "multipart/form-data")
    public ApiResponse<MeProfileResponse> uploadAvatar(Authentication auth, @RequestParam("file") MultipartFile file) throws IOException {
        if (file.isEmpty()) {
            throw new BadRequestException("Uploaded file is empty");
        }
        if (file.getSize() > MAX_AVATAR_BYTES) {
            throw new BadRequestException("Image must be smaller than 5MB");
        }

        String originalName = Objects.requireNonNullElse(file.getOriginalFilename(), "avatar");
        String ext = originalName.contains(".") ? originalName.substring(originalName.lastIndexOf('.') + 1).toLowerCase() : "jpg";
        if (!ALLOWED_IMAGE_EXT.contains(ext)) {
            throw new BadRequestException("Only JPG, PNG, or WEBP images are allowed");
        }

        String loginId = auth.getName();
        String role = primaryRole(auth);
        String safeLoginId = loginId.replaceAll("[^a-zA-Z0-9_-]", "_");
        String fileName = role.toLowerCase() + "-" + safeLoginId + "-" + UUID.randomUUID().toString().substring(0, 8) + "." + ext;

        Path avatarsDir = Paths.get(uploadsDir, "avatars").toAbsolutePath().normalize();
        Files.createDirectories(avatarsDir);
        Path target = avatarsDir.resolve(fileName).normalize();
        if (!target.startsWith(avatarsDir)) {
            throw new BadRequestException("Invalid file name");
        }
        Files.copy(file.getInputStream(), target, StandardCopyOption.REPLACE_EXISTING);

        String avatarUrl = "/uploads/avatars/" + fileName;

        switch (role) {
            case "ADMIN" -> {
                Admin admin = adminRepository.findByAdminId(loginId)
                        .orElseThrow(() -> new ResourceNotFoundException("Admin not found"));
                admin.setAvatarUrl(avatarUrl);
                adminRepository.save(admin);
            }
            case "STAFF", "LIBRARIAN" -> {
                Staff staff = staffRepository.findByStaffId(loginId)
                        .orElseThrow(() -> new ResourceNotFoundException("Staff not found"));
                staff.setAvatarUrl(avatarUrl);
                staffRepository.save(staff);
            }
            case "STUDENT" -> {
                Student student = studentRepository.findByRegisterNumber(loginId)
                        .orElseThrow(() -> new ResourceNotFoundException("Student not found"));
                student.setAvatarUrl(avatarUrl);
                studentRepository.save(student);
            }
            default -> throw new BadRequestException("Unknown role");
        }

        return ApiResponse.ok("Profile picture updated", resolveProfile(auth));
    }

    private void verifyAndSet(String currentHash, ChangePasswordRequest request, java.util.function.Consumer<String> setter) {
        if (currentHash == null || !passwordEncoder.matches(request.getCurrentPassword(), currentHash)) {
            throw new BadRequestException("Current password is incorrect");
        }
        setter.accept(passwordEncoder.encode(request.getNewPassword()));
    }

    private MeProfileResponse resolveProfile(Authentication auth) {
        String loginId = auth.getName();
        String role = primaryRole(auth);

        return switch (role) {
            case "ADMIN" -> {
                Admin admin = adminRepository.findByAdminId(loginId)
                        .orElseThrow(() -> new ResourceNotFoundException("Admin not found"));
                yield MeProfileResponse.builder()
                        .id(admin.getId().toString())
                        .loginId(admin.getAdminId())
                        .name(admin.getName())
                        .email(admin.getEmail())
                        .phone(admin.getPhone())
                        .role("ADMIN")
                        .avatarUrl(admin.getAvatarUrl())
                        .build();
            }
            case "STAFF", "LIBRARIAN" -> {
                Staff staff = staffRepository.findByStaffId(loginId)
                        .orElseThrow(() -> new ResourceNotFoundException("Staff not found"));
                yield MeProfileResponse.builder()
                        .id(staff.getId().toString())
                        .loginId(staff.getStaffId())
                        .name(staff.getName())
                        .email(staff.getEmail())
                        .phone(staff.getPhone())
                        .role(staff.getRole())
                        .department(staff.getDepartment())
                        .designationOrSemester(staff.getDesignation())
                        .avatarUrl(staff.getAvatarUrl())
                        .build();
            }
            case "STUDENT" -> {
                Student student = studentRepository.findByRegisterNumber(loginId)
                        .orElseThrow(() -> new ResourceNotFoundException("Student not found"));
                yield MeProfileResponse.builder()
                        .id(student.getId().toString())
                        .loginId(student.getRegisterNumber())
                        .name(student.getName())
                        .email(student.getEmail())
                        .phone(student.getPhone())
                        .role("STUDENT")
                        .department(student.getDepartment())
                        .designationOrSemester("Semester " + student.getSemester())
                        .avatarUrl(student.getAvatarUrl())
                        .build();
            }
            default -> throw new BadRequestException("Unknown role");
        };
    }

    private String primaryRole(Authentication auth) {
        return auth.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .findFirst()
                .map(a -> a.replace("ROLE_", ""))
                .orElseThrow(() -> new BadRequestException("No role on token"));
    }
}
