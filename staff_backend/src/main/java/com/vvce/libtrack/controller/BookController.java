package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.BookDto;
import com.vvce.libtrack.service.BookService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Backs the Search Books and Book Details screens. */
@RestController
@RequestMapping("/api/books")
@RequiredArgsConstructor
public class BookController {

    private final BookService bookService;

    @GetMapping("/search")
    public List<BookDto> search(
            @RequestParam(required = false) String query,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String department,
            @RequestParam(required = false) String author,
            @RequestParam(required = false) String rack,
            @RequestParam(required = false) String shelf,
            @RequestParam(required = false) String regulation,
            @RequestParam(required = false) String availability
    ) {
        return bookService.search(query, category, department, author, rack, shelf, regulation, availability);
    }

    @GetMapping("/{id}")
    public BookDto getById(@PathVariable String id) {
        return bookService.getById(id);
    }

    @GetMapping("/isbn/{isbn}")
    public BookDto getByIsbn(@PathVariable String isbn) {
        return bookService.getByIsbn(isbn);
    }
}
