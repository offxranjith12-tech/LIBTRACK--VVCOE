package com.vvcoe.libtrack.controller;

import com.vvcoe.libtrack.model.Student;
import com.vvcoe.libtrack.service.StudentService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/students")
public class StudentController {

    private final StudentService studentService;

    public StudentController(StudentService studentService) {
        this.studentService = studentService;
    }

    @GetMapping("/{id}")
    public ResponseEntity<Student> getStudent(@PathVariable Long id) {
        return ResponseEntity.ok(studentService.getById(id));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Student> updateStudent(@PathVariable Long id, @RequestBody Map<String, String> body) {
        Student updated = studentService.update(id, body.get("name"), body.get("email"), body.get("phone"));
        return ResponseEntity.ok(updated);
    }

    @PostMapping("/{id}/profile-image")
    public ResponseEntity<Map<String, String>> uploadPhoto(@PathVariable Long id,
                                                             @RequestParam("file") MultipartFile file) {
        String url = studentService.updatePhoto(id, file);
        Map<String, String> response = new HashMap<>();
        response.put("photoUrl", url);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}/password")
    public ResponseEntity<Map<String, String>> changePassword(@PathVariable Long id, @RequestBody Map<String, String> body) {
        studentService.changePassword(id, body.get("currentPassword"), body.get("newPassword"));
        Map<String, String> response = new HashMap<>();
        response.put("message", "Password updated successfully");
        return ResponseEntity.ok(response);
    }
}
