package com.vvce.libtrack.service;

import com.vvce.libtrack.dto.BookDto;
import com.vvce.libtrack.entity.Book;
import com.vvce.libtrack.exception.BadRequestException;
import com.vvce.libtrack.exception.ResourceNotFoundException;
import com.vvce.libtrack.repository.BookRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class BookService {

    private final BookRepository bookRepository;

    @Value("${libtrack.uploads.dir:./uploads}")
    private String uploadsDir;

    private static final Set<String> ALLOWED_IMAGE_EXT = Set.of("jpg", "jpeg", "png", "webp");
    private static final long MAX_COVER_BYTES = 5L * 1024 * 1024; // 5MB

    /**
     * Backs the search bar. Called with page/size so the UI can page through
     * results even when the catalogue has 10,000+ rows — the query itself
     * uses the indexes defined on Book (title, author, isbn, category, department).
     */
    public Page<Book> search(String query, String category, String department, String regulation, boolean onlyAvailable, Pageable pageable) {
        return search(query, category, department, regulation, onlyAvailable, false, false, pageable);
    }

    public Page<Book> search(String query, String category, String department, String regulation,
                              boolean onlyAvailable, boolean onlyIssued, boolean onlyLowStock, Pageable pageable) {
        return bookRepository.search(
                blankToNull(query),
                blankToNull(category),
                blankToNull(department),
                blankToNull(regulation),
                onlyAvailable,
                onlyIssued,
                onlyLowStock,
                pageable
        );
    }

    public Book getById(Long id) {
        return bookRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Book not found: " + id));
    }

    @Transactional
    public Book create(BookDto dto) {
        Book book = Book.builder()
                .title(dto.getTitle())
                .author(dto.getAuthor())
                .publisher(dto.getPublisher())
                .isbn(dto.getIsbn())
                .edition(dto.getEdition())
                .category(dto.getCategory())
                .department(dto.getDepartment())
                .rackNumber(dto.getRackNumber())
                .shelfNumber(dto.getShelfNumber())
                .regulation(dto.getRegulation())
                .totalCopies(dto.getTotalCopies() == null ? 1 : dto.getTotalCopies())
                .availableCopies(dto.getTotalCopies() == null ? 1 : dto.getTotalCopies())
                .description(dto.getDescription())
                .coverUrl(dto.getCoverUrl())
                .qrCode("QR-" + UUID.randomUUID().toString().substring(0, 12).toUpperCase())
                .createdAt(LocalDateTime.now())
                .build();
        return bookRepository.save(book);
    }

    @Transactional
    public Book update(Long id, BookDto dto) {
        Book book = getById(id);
        int delta = (dto.getTotalCopies() == null ? book.getTotalCopies() : dto.getTotalCopies()) - book.getTotalCopies();

        book.setTitle(dto.getTitle());
        book.setAuthor(dto.getAuthor());
        book.setPublisher(dto.getPublisher());
        book.setIsbn(dto.getIsbn());
        book.setEdition(dto.getEdition());
        book.setCategory(dto.getCategory());
        book.setDepartment(dto.getDepartment());
        book.setRackNumber(dto.getRackNumber());
        book.setShelfNumber(dto.getShelfNumber());
        book.setRegulation(dto.getRegulation());
        if (dto.getTotalCopies() != null) {
            book.setTotalCopies(dto.getTotalCopies());
            book.setAvailableCopies(Math.max(0, Math.min(dto.getTotalCopies(), book.getAvailableCopies() + delta)));
        }
        book.setDescription(dto.getDescription());
        if (dto.getCoverUrl() != null) book.setCoverUrl(dto.getCoverUrl());

        return bookRepository.save(book);
    }

    @Transactional
    public void delete(Long id) {
        if (!bookRepository.existsById(id)) {
            throw new ResourceNotFoundException("Book not found: " + id);
        }
        bookRepository.deleteById(id);
    }

    @Transactional
    public void adjustAvailability(Long bookId, int delta) {
        Book book = getById(bookId);
        int updated = Math.max(0, Math.min(book.getTotalCopies(), book.getAvailableCopies() + delta));
        book.setAvailableCopies(updated);
        bookRepository.save(book);
    }

    /**
     * Uploads/replaces a book's cover image. Stored on disk under
     * `libtrack.uploads.dir` (default `./uploads`) and served back statically
     * at `/uploads/covers/...` (see WebConfig) — same pattern as the
     * `/me/avatar` upload.
     */
    @Transactional
    public Book uploadCover(Long id, MultipartFile file) throws IOException {
        Book book = getById(id);

        if (file.isEmpty()) {
            throw new BadRequestException("Uploaded file is empty");
        }
        if (file.getSize() > MAX_COVER_BYTES) {
            throw new BadRequestException("Cover image must be smaller than 5MB");
        }

        String originalName = Objects.requireNonNullElse(file.getOriginalFilename(), "cover");
        String ext = originalName.contains(".") ? originalName.substring(originalName.lastIndexOf('.') + 1).toLowerCase() : "jpg";
        if (!ALLOWED_IMAGE_EXT.contains(ext)) {
            throw new BadRequestException("Only JPG, PNG, or WEBP images are allowed");
        }

        String fileName = "book-" + id + "-" + UUID.randomUUID().toString().substring(0, 8) + "." + ext;
        Path coversDir = Paths.get(uploadsDir, "covers").toAbsolutePath().normalize();
        Files.createDirectories(coversDir);
        Path target = coversDir.resolve(fileName).normalize();
        if (!target.startsWith(coversDir)) {
            throw new BadRequestException("Invalid file name");
        }
        Files.copy(file.getInputStream(), target, StandardCopyOption.REPLACE_EXISTING);

        book.setCoverUrl("/uploads/covers/" + fileName);
        return bookRepository.save(book);
    }

    public long totalBookCount() {
        return bookRepository.count();
    }

    public long availableBookCount() {
        return bookRepository.countByAvailableCopiesGreaterThan(0);
    }

    private String blankToNull(String value) {
        return (value == null || value.isBlank()) ? null : value.trim();
    }
}
