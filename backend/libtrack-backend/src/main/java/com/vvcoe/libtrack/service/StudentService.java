package com.vvcoe.libtrack.service;

import com.vvcoe.libtrack.model.Student;
import com.vvcoe.libtrack.repository.StudentRepository;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class StudentService {

    private final StudentRepository studentRepository;
    private final FileStorageService fileStorageService;

    public StudentService(StudentRepository studentRepository, FileStorageService fileStorageService) {
        this.studentRepository = studentRepository;
        this.fileStorageService = fileStorageService;
    }

    public Student getById(Long id) {
        return studentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Student not found: " + id));
    }

    public Student update(Long id, String name, String email, String phone) {
        Student student = getById(id);
        if (name != null && !name.isBlank()) student.setName(name);
        if (email != null && !email.isBlank()) student.setEmail(email);
        if (phone != null && !phone.isBlank()) student.setPhone(phone);
        return studentRepository.save(student);
    }

    public String updatePhoto(Long id, MultipartFile file) {
        Student student = getById(id);
        String url = fileStorageService.store(file);
        student.setPhotoUrl(url);
        studentRepository.save(student);
        return url;
    }

    public void changePassword(Long id, String currentPassword, String newPassword) {
        Student student = getById(id);
        if (student.getPassword() == null || !student.getPassword().equals(currentPassword)) {
            throw new IllegalStateException("Current password is incorrect");
        }
        if (newPassword == null || newPassword.length() < 6) {
            throw new IllegalStateException("New password must be at least 6 characters");
        }
        student.setPassword(newPassword);
        studentRepository.save(student);
    }
}
