package com.vvcoe.libtrack.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

@Service
public class FileStorageService {

    @Value("${app.upload.dir}")
    private String uploadDir;

    /**
     * Saves the uploaded file under the configured upload directory and
     * returns a public URL path (e.g. "/uploads/abc123.jpg") that the
     * frontend can use directly as the student's photoUrl.
     */
    public String store(MultipartFile file) {
        try {
            Path dir = Paths.get(uploadDir).toAbsolutePath().normalize();
            Files.createDirectories(dir);

            String original = file.getOriginalFilename() == null ? "photo.jpg" : file.getOriginalFilename();
            String extension = original.contains(".") ? original.substring(original.lastIndexOf('.')) : ".jpg";
            String filename = UUID.randomUUID() + extension;

            Path target = dir.resolve(filename);
            Files.copy(file.getInputStream(), target);

            return "/uploads/" + filename;
        } catch (IOException e) {
            throw new RuntimeException("Failed to store uploaded file: " + e.getMessage(), e);
        }
    }
}
