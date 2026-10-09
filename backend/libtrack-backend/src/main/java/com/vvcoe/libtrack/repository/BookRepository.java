package com.vvcoe.libtrack.repository;

import com.vvcoe.libtrack.model.Book;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface BookRepository extends JpaRepository<Book, Long> {

    @Query("SELECT b FROM Book b WHERE " +
            "(:query IS NULL OR :query = '' OR " +
            "  LOWER(b.title) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "  LOWER(b.author) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "  b.isbn LIKE CONCAT('%', :query, '%')) " +
            "AND (:category IS NULL OR b.category = :category) " +
            "AND (:department IS NULL OR b.department = :department) " +
            "AND (:author IS NULL OR b.author = :author) " +
            "AND (:rack IS NULL OR b.rackNumber = :rack)")
    List<Book> search(
            @Param("query") String query,
            @Param("category") String category,
            @Param("department") String department,
            @Param("author") String author,
            @Param("rack") String rack
    );
}
