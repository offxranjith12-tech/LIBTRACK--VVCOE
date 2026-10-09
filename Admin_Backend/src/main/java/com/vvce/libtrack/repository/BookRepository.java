package com.vvce.libtrack.repository;

import com.vvce.libtrack.entity.Book;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface BookRepository extends JpaRepository<Book, Long> {

    /**
     * Powers the search bar. Matches partial, case-insensitive text against
     * title, author, or ISBN, with optional category/department filters.
     * Passing null for a filter parameter skips it (see the OR/NULL trick below).
     */
    @Query("""
        SELECT b FROM Book b
        WHERE (:q IS NULL OR :q = '' OR
               LOWER(b.title) LIKE LOWER(CONCAT('%', :q, '%')) OR
               LOWER(b.author) LIKE LOWER(CONCAT('%', :q, '%')) OR
               b.isbn LIKE CONCAT('%', :q, '%') OR
               LOWER(b.regulation) LIKE LOWER(CONCAT('%', :q, '%')))
          AND (:category IS NULL OR b.category = :category)
          AND (:department IS NULL OR b.department = :department)
          AND (:regulation IS NULL OR b.regulation = :regulation)
          AND (:onlyAvailable = FALSE OR b.availableCopies > 0)
          AND (:onlyIssued = FALSE OR b.availableCopies < b.totalCopies)
          AND (:onlyLowStock = FALSE OR (b.availableCopies > 0 AND b.availableCopies <= 2))
        """)
    Page<Book> search(
            @Param("q") String query,
            @Param("category") String category,
            @Param("department") String department,
            @Param("regulation") String regulation,
            @Param("onlyAvailable") boolean onlyAvailable,
            @Param("onlyIssued") boolean onlyIssued,
            @Param("onlyLowStock") boolean onlyLowStock,
            Pageable pageable
    );

    boolean existsByIsbn(String isbn);

    long countByAvailableCopiesGreaterThan(int copies);
}
