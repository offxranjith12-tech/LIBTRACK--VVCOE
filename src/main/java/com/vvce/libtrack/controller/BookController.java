package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.ApiResponse;
import com.vvce.libtrack.dto.BookDto;
import com.vvce.libtrack.dto.BulkImportResponse;
import com.vvce.libtrack.entity.Book;
import com.vvce.libtrack.service.BookService;
import com.vvce.libtrack.service.BulkImportService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

@RestController
@RequestMapping("/api/v1/books")
@RequiredArgsConstructor
public class BookController {

    private final BookService bookService;
    private final BulkImportService bulkImportService;

    /**
     * Powers the search bar. Example:
     * GET /api/v1/books/search?q=algorithms&department=CSE&page=0&size=20
     */
    @GetMapping("/search")
    public ApiResponse<Page<Book>> search(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String department,
            @RequestParam(required = false) String regulation,
            @RequestParam(defaultValue = "false") boolean onlyAvailable,
            @RequestParam(defaultValue = "false") boolean onlyIssued,
            @RequestParam(defaultValue = "false") boolean onlyLowStock,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        Pageable pageable = PageRequest.of(page, Math.min(size, 100), Sort.by("title").ascending());
        return ApiResponse.ok(bookService.search(q, category, department, regulation, onlyAvailable, onlyIssued, onlyLowStock, pageable));
    }

    @GetMapping("/{id}")
    public ApiResponse<Book> getById(@PathVariable Long id) {
        return ApiResponse.ok(bookService.getById(id));
    }

    @PostMapping
    public ApiResponse<Book> create(@Valid @RequestBody BookDto dto) {
        return ApiResponse.ok("Book added", bookService.create(dto));
    }

    @PutMapping("/{id}")
    public ApiResponse<Book> update(@PathVariable Long id, @Valid @RequestBody BookDto dto) {
        return ApiResponse.ok("Book updated", bookService.update(id, dto));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        bookService.delete(id);
        return ApiResponse.ok("Book deleted", null);
    }

    /**
     * Uploads/replaces a book's cover image — powers the "Book Cover" picker
     * on the Add/Edit Book screen.
     */
    @PostMapping(value = "/{id}/cover", consumes = "multipart/form-data")
    public ApiResponse<Book> uploadCover(@PathVariable Long id, @RequestParam("file") MultipartFile file) throws IOException {
        return ApiResponse.ok("Cover updated", bookService.uploadCover(id, file));
    }

    /**
     * Upload a .csv or .xlsx file with columns:
     * title, author, publisher, isbn, edition, category, department,
     * rackNumber, shelfNumber, regulation, totalCopies, description
     *
     * Handles 9,000-10,000+ rows in one call via chunked batch inserts.
     */
    @PostMapping(value = "/bulk-import", consumes = "multipart/form-data")
    public ApiResponse<BulkImportResponse> bulkImport(@RequestParam("file") MultipartFile file) throws IOException {
        if (file.isEmpty()) {
            return ApiResponse.error("Uploaded file is empty");
        }
        BulkImportResponse result = bulkImportService.importFile(file);
        return ApiResponse.ok(
                "Imported " + result.getImportedCount() + " of " + result.getTotalRows() + " rows",
                result
        );
    }
}
