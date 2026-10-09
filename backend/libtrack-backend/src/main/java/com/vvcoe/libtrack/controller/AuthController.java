package com.vvcoe.libtrack.controller;

import com.vvcoe.libtrack.model.Student;
import com.vvcoe.libtrack.repository.StudentRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Deliberately simple, demo-grade authentication for an academic project:
 * it checks the register number + password against the database and hands
 * back a random opaque token (not a verified JWT). This matches the
 * Flutter ApiService.login() contract. Harden this (real JWT + password
 * hashing) before using it anywhere beyond a college assignment/demo.
 */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final StudentRepository studentRepository;

    public AuthController(StudentRepository studentRepository) {
        this.studentRepository = studentRepository;
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> body) {
        String registerNumber = body.get("registerNumber");
        String password = body.get("password");

        Optional<Student> match = studentRepository.findByRegisterNumber(registerNumber);
        if (match.isEmpty() || !match.get().getPassword().equals(password)) {
            Map<String, String> error = new HashMap<>();
            error.put("message", "Invalid register number or password");
            return ResponseEntity.status(401).body(error);
        }

        Map<String, Object> response = new HashMap<>();
        response.put("token", "libtrack-" + UUID.randomUUID());
        response.put("student", match.get());
        return ResponseEntity.ok(response);
    }
}
