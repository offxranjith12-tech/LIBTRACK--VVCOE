package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.ApiResponse;
import com.vvce.libtrack.dto.CreateStaffRequest;
import com.vvce.libtrack.entity.Staff;
import com.vvce.libtrack.exception.BadRequestException;
import com.vvce.libtrack.exception.ResourceNotFoundException;
import com.vvce.libtrack.repository.StaffRepository;
import com.vvce.libtrack.util.CollegeEmailValidator;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;

@RestController
@RequestMapping("/api/v1/staff")
@RequiredArgsConstructor
public class StaffController {

    private static final Set<String> VALID_ROLES = Set.of("STAFF", "LIBRARIAN");

    private final StaffRepository staffRepository;
    private final PasswordEncoder passwordEncoder;

    @GetMapping
    public ApiResponse<List<Staff>> getAll(@RequestParam(required = false) String q) {
        List<Staff> all = staffRepository.findAll();
        if (q != null && !q.isBlank()) {
            String lower = q.toLowerCase();
            all = all.stream()
                    .filter(s -> s.getName().toLowerCase().contains(lower) || s.getStaffId().toLowerCase().contains(lower))
                    .toList();
        }
        return ApiResponse.ok(all);
    }

    @GetMapping("/{id}")
    public ApiResponse<Staff> getById(@PathVariable Long id) {
        return ApiResponse.ok(staffRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Staff not found: " + id)));
    }

    /**
     * Admin "Add Staff / Librarian" flow. The email MUST be the college's own
     * Gmail domain (e.g. ranjith@vvcoe.org) — personal email addresses are
     * rejected. Any number of LIBRARIAN accounts can be created here, each
     * with their own staffId + password, so every librarian on the desk gets
     * their own login.
     */
    @PostMapping
    public ApiResponse<Staff> create(@Valid @RequestBody CreateStaffRequest request) {
        CollegeEmailValidator.validate(request.getEmail());

        String role = normalizeRole(request.getRole());

        if (staffRepository.findByStaffId(request.getStaffId()).isPresent()) {
            throw new BadRequestException("A staff member with ID " + request.getStaffId() + " already exists");
        }
        if (staffRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new BadRequestException("A staff member with this email already exists");
        }

        Staff staff = Staff.builder()
                .staffId(request.getStaffId())
                .name(request.getName())
                .department(request.getDepartment())
                .designation(request.getDesignation())
                .email(request.getEmail().trim().toLowerCase())
                .phone(request.getPhone())
                .password(passwordEncoder.encode(request.getPassword()))
                .role(role)
                .borrowLimit(request.getBorrowLimit() == null ? 5 : request.getBorrowLimit())
                .borrowedBooksCount(0)
                .status("ACTIVE")
                .joinedOn(LocalDateTime.now())
                .build();

        return ApiResponse.ok((role.equals("LIBRARIAN") ? "Librarian" : "Staff") + " added", staffRepository.save(staff));
    }

    @PutMapping("/{id}")
    public ApiResponse<Staff> update(@PathVariable Long id, @RequestBody CreateStaffRequest request) {
        Staff existing = staffRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Staff not found: " + id));

        if (request.getEmail() != null && !request.getEmail().isBlank()) {
            CollegeEmailValidator.validate(request.getEmail());
            existing.setEmail(request.getEmail().trim().toLowerCase());
        }
        if (request.getName() != null) existing.setName(request.getName());
        if (request.getDepartment() != null) existing.setDepartment(request.getDepartment());
        if (request.getDesignation() != null) existing.setDesignation(request.getDesignation());
        if (request.getPhone() != null) existing.setPhone(request.getPhone());
        if (request.getBorrowLimit() != null) existing.setBorrowLimit(request.getBorrowLimit());
        if (request.getRole() != null && !request.getRole().isBlank()) existing.setRole(normalizeRole(request.getRole()));
        if (request.getPassword() != null && !request.getPassword().isBlank()) {
            existing.setPassword(passwordEncoder.encode(request.getPassword()));
        }

        return ApiResponse.ok("Staff updated", staffRepository.save(existing));
    }

    @PatchMapping("/{id}/toggle-block")
    public ApiResponse<Staff> toggleBlock(@PathVariable Long id) {
        Staff staff = staffRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Staff not found: " + id));
        staff.setStatus("ACTIVE".equals(staff.getStatus()) ? "BLOCKED" : "ACTIVE");
        return ApiResponse.ok(staffRepository.save(staff));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        staffRepository.deleteById(id);
        return ApiResponse.ok("Staff deleted", null);
    }

    private String normalizeRole(String role) {
        if (role == null || role.isBlank()) return "STAFF";
        String upper = role.trim().toUpperCase();
        if (!VALID_ROLES.contains(upper)) {
            throw new BadRequestException("Role must be one of " + VALID_ROLES);
        }
        return upper;
    }
}
