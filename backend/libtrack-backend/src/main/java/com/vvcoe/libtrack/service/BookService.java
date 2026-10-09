package com.vvcoe.libtrack.service;

import com.vvcoe.libtrack.model.Book;
import com.vvcoe.libtrack.repository.BookRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class BookService {

    private final BookRepository bookRepository;

    public BookService(BookRepository bookRepository) {
        this.bookRepository = bookRepository;
    }

    public List<Book> search(String query, String category, String department, String author,
                              String rack, String availability) {
        String q = (query == null) ? "" : query;
        List<Book> results = bookRepository.search(
                q,
                blankToNull(category),
                blankToNull(department),
                blankToNull(author),
                blankToNull(rack)
        );

        if (availability != null && !availability.isBlank()) {
            boolean wantAvailable = availability.equalsIgnoreCase("available");
            results = results.stream()
                    .filter(b -> wantAvailable ? b.getAvailableCopies() > 0 : b.getAvailableCopies() <= 0)
                    .toList();
        }
        return results;
    }

    public Book getById(Long id) {
        return bookRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Book not found: " + id));
    }

    public List<Book> getAll() {
        return bookRepository.findAll();
    }

    private String blankToNull(String value) {
        return (value == null || value.isBlank() || value.equalsIgnoreCase("All")) ? null : value;
    }
}
