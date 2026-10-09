package com.vvce.libtrack.service;

import com.vvce.libtrack.dto.BookDto;
import com.vvce.libtrack.entity.Book;
import com.vvce.libtrack.exception.ResourceNotFoundException;
import com.vvce.libtrack.repository.BookRepository;
import com.vvce.libtrack.repository.BookSpecifications;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class BookService {

    private final BookRepository bookRepository;

    /** Backs the Search Books screen: free-text query + the filter chips. */
    public List<BookDto> search(String query, String category, String department, String author,
                                 String rack, String shelf, String regulation, String availability) {
        return bookRepository.findAll(
                BookSpecifications.withFilters(query, category, department, author, rack, shelf, regulation, availability)
        ).stream().map(BookDto::from).toList();
    }

    public BookDto getById(String bookId) {
        return BookDto.from(findById(bookId));
    }

    public BookDto getByIsbn(String isbn) {
        Book book = bookRepository.findByIsbn(isbn)
                .orElseThrow(() -> new ResourceNotFoundException("No book with ISBN: " + isbn));
        return BookDto.from(book);
    }

    Book findById(String bookId) {
        return bookRepository.findById(bookId)
                .orElseThrow(() -> new ResourceNotFoundException("No book with id: " + bookId));
    }
}
