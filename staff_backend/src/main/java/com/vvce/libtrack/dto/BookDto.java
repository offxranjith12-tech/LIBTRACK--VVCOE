package com.vvce.libtrack.dto;

import com.vvce.libtrack.entity.Book;

public record BookDto(
        String id,
        String title,
        String author,
        String publisher,
        String isbn,
        String category,
        String department,
        String rack,
        String shelf,
        String regulation,
        Integer totalCopies,
        Integer availableCopies,
        String description,
        String coverUrl,
        String status // AVAILABLE | LOW_STOCK | ISSUED
) {
    public static BookDto from(Book b) {
        String status;
        if (b.getAvailableCopies() == null || b.getAvailableCopies() == 0) {
            status = "ISSUED";
        } else if (b.getAvailableCopies() <= 1) {
            status = "LOW_STOCK";
        } else {
            status = "AVAILABLE";
        }
        return new BookDto(b.getBookId(), b.getTitle(), b.getAuthor(), b.getPublisher(), b.getIsbn(),
                b.getCategory(), b.getDepartment(), b.getRack(), b.getShelf(), b.getRegulation(), b.getTotalCopies(),
                b.getAvailableCopies(), b.getDescription(), b.getCoverUrl(), status);
    }
}
