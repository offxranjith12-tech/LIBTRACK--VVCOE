package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.ApiResponse;
import com.vvce.libtrack.dto.CreateStudentRequest;
import com.vvce.libtrack.entity.Student;
import com.vvce.libtrack.exception.BadRequestException;
import com.vvce.libtrack.exception.ResourceNotFoundException;
import com.vvce.libtrack.repository.StudentRepository;
import com.vvce.libtrack.util.CollegeEmailValidator;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/v1/students")
@RequiredArgsConstructor
public class StudentController {

    private final StudentRepository studentRepository;
    private final PasswordEncoder passwordEncoder;

    @GetMapping
    public ApiResponse<List<Student>> getAll(@RequestParam(required = false) String q) {
        List<Student> all = studentRepository.findAll();
        if (q != null && !q.isBlank()) {
            String lower = q.toLowerCase();
            all = all.stream()
                    .filter(s -> s.getName().toLowerCase().contains(lower) || s.getRegisterNumber().toLowerCase().contains(lower))
                    .toList();
        }
        return ApiResponse.ok(all);
    }

    @GetMapping("/{id}")
    public ApiResponse<Student> getById(@PathVariable Long id) {
        return ApiResponse.ok(studentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Student not found: " + id)));
    }

    /**
     * Admin "Add Student" flow. The email MUST be the college's own Gmail
     * domain (e.g. r23cs065@vvcoe.org) — personal Gmail/Yahoo/etc. addresses
     * are rejected. The password is BCrypt-hashed before it is stored, and
     * the student can then log in with registerNumber + password.
     */
    @PostMapping
    public ApiResponse<Student> create(@Valid @RequestBody CreateStudentRequest request) {
        CollegeEmailValidator.validate(request.getEmail());

        if (studentRepository.findByRegisterNumber(request.getRegisterNumber()).isPresent()) {
            throw new BadRequestException("A student with register number " + request.getRegisterNumber() + " already exists");
        }
        if (studentRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new BadRequestException("A student with this email already exists");
        }

        Student student = Student.builder()
                .registerNumber(request.getRegisterNumber())
                .name(request.getName())
                .department(request.getDepartment())
                .semester(request.getSemester())
                .email(request.getEmail().trim().toLowerCase())
                .phone(request.getPhone())
                .password(passwordEncoder.encode(request.getPassword()))
                .borrowLimit(request.getBorrowLimit() == null ? 3 : request.getBorrowLimit())
                .borrowedBooksCount(0)
                .status("ACTIVE")
                .joinedOn(LocalDateTime.now())
                .build();

        return ApiResponse.ok("Student added", studentRepository.save(student));
    }

    @PutMapping("/{id}")
    public ApiResponse<Student> update(@PathVariable Long id, @RequestBody CreateStudentRequest request) {
        Student existing = studentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Student not found: " + id));

        if (request.getEmail() != null && !request.getEmail().isBlank()) {
            CollegeEmailValidator.validate(request.getEmail());
            existing.setEmail(request.getEmail().trim().toLowerCase());
        }
        if (request.getName() != null) existing.setName(request.getName());
        if (request.getDepartment() != null) existing.setDepartment(request.getDepartment());
        if (request.getSemester() != null) existing.setSemester(request.getSemester());
        if (request.getPhone() != null) existing.setPhone(request.getPhone());
        if (request.getBorrowLimit() != null) existing.setBorrowLimit(request.getBorrowLimit());
        if (request.getPassword() != null && !request.getPassword().isBlank()) {
            existing.setPassword(passwordEncoder.encode(request.getPassword()));
        }

        return ApiResponse.ok("Student updated", studentRepository.save(existing));
    }

    @PatchMapping("/{id}/toggle-block")
    public ApiResponse<Student> toggleBlock(@PathVariable Long id) {
        Student student = studentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Student not found: " + id));
        student.setStatus("ACTIVE".equals(student.getStatus()) ? "BLOCKED" : "ACTIVE");
        return ApiResponse.ok(studentRepository.save(student));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        studentRepository.deleteById(id);
        return ApiResponse.ok("Student deleted", null);
    }
}
