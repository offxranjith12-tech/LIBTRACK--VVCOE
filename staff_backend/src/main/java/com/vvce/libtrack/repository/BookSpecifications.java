package com.vvce.libtrack.repository;

import com.vvce.libtrack.entity.Book;
import org.springframework.data.jpa.domain.Specification;

/** Builds the dynamic WHERE clause for /api/books/search — one predicate per
 *  filter chip shown in the Flutter Search Books screen (Category, Department,
 *  Author, Rack, Shelf, Availability) plus the free-text query box. */
public final class BookSpecifications {

    private BookSpecifications() {}

    public static Specification<Book> withFilters(String query, String category, String department,
                                                    String author, String rack, String shelf,
                                                    String regulation, String availability) {
        return (root, cq, cb) -> {
            var predicates = cb.conjunction();

            if (query != null && !query.isBlank()) {
                String like = "%" + query.toLowerCase() + "%";
                predicates = cb.and(predicates, cb.or(
                        cb.like(cb.lower(root.get("title")), like),
                        cb.like(cb.lower(root.get("author")), like),
                        cb.like(root.get("isbn"), like),
                        cb.like(cb.lower(root.get("department")), like),
                        cb.like(cb.lower(root.get("category")), like)
                ));
            }
            if (category != null && !category.isBlank()) {
                predicates = cb.and(predicates, cb.equal(root.get("category"), category));
            }
            if (department != null && !department.isBlank()) {
                predicates = cb.and(predicates, cb.equal(root.get("department"), department));
            }
            if (author != null && !author.isBlank()) {
                predicates = cb.and(predicates, cb.like(cb.lower(root.get("author")), "%" + author.toLowerCase() + "%"));
            }
            if (rack != null && !rack.isBlank()) {
                predicates = cb.and(predicates, cb.equal(root.get("rack"), rack));
            }
            if (shelf != null && !shelf.isBlank()) {
                predicates = cb.and(predicates, cb.equal(root.get("shelf"), shelf));
            }
            if (regulation != null && !regulation.isBlank()) {
                predicates = cb.and(predicates, cb.equal(root.get("regulation"), regulation));
            }
            if (availability != null && !availability.isBlank()) {
                if (availability.equalsIgnoreCase("available")) {
                    predicates = cb.and(predicates, cb.greaterThan(root.get("availableCopies"), 0));
                } else if (availability.equalsIgnoreCase("unavailable")) {
                    predicates = cb.and(predicates, cb.equal(root.get("availableCopies"), 0));
                }
            }
            return predicates;
        };
    }
}
