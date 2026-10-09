package com.vvcoe.libtrack.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Lob;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;

@Entity
@Table(name = "books")
public class Book {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    @Column(nullable = false)
    private String title;

    @NotBlank
    @Column(nullable = false)
    private String author;

    @Column(unique = true)
    private String isbn;

    /** e.g. "Computer Science", "Mathematics", "Regulation" */
    @Column(nullable = false)
    private String category;

    /** e.g. "CSE", "ECE", "Common" */
    @Column(nullable = false)
    private String department;

    private String publisher;

    private String edition;

    private String rackNumber;

    private String shelfNumber;

    @Column(nullable = false)
    private Integer totalCopies = 0;

    @Column(nullable = false)
    private Integer availableCopies = 0;

    @Lob
    private String description;

    private String coverColorHex = "B71C1C";

    public Book() {
    }

    public Book(String title, String author, String isbn, String category, String department,
                String publisher, String edition, String rackNumber, String shelfNumber,
                Integer totalCopies, Integer availableCopies, String description, String coverColorHex) {
        this.title = title;
        this.author = author;
        this.isbn = isbn;
        this.category = category;
        this.department = department;
        this.publisher = publisher;
        this.edition = edition;
        this.rackNumber = rackNumber;
        this.shelfNumber = shelfNumber;
        this.totalCopies = totalCopies;
        this.availableCopies = availableCopies;
        this.description = description;
        this.coverColorHex = coverColorHex;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getAuthor() {
        return author;
    }

    public void setAuthor(String author) {
        this.author = author;
    }

    public String getIsbn() {
        return isbn;
    }

    public void setIsbn(String isbn) {
        this.isbn = isbn;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getDepartment() {
        return department;
    }

    public void setDepartment(String department) {
        this.department = department;
    }

    public String getPublisher() {
        return publisher;
    }

    public void setPublisher(String publisher) {
        this.publisher = publisher;
    }

    public String getEdition() {
        return edition;
    }

    public void setEdition(String edition) {
        this.edition = edition;
    }

    public String getRackNumber() {
        return rackNumber;
    }

    public void setRackNumber(String rackNumber) {
        this.rackNumber = rackNumber;
    }

    public String getShelfNumber() {
        return shelfNumber;
    }

    public void setShelfNumber(String shelfNumber) {
        this.shelfNumber = shelfNumber;
    }

    public Integer getTotalCopies() {
        return totalCopies;
    }

    public void setTotalCopies(Integer totalCopies) {
        this.totalCopies = totalCopies;
    }

    public Integer getAvailableCopies() {
        return availableCopies;
    }

    public void setAvailableCopies(Integer availableCopies) {
        this.availableCopies = availableCopies;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getCoverColorHex() {
        return coverColorHex;
    }

    public void setCoverColorHex(String coverColorHex) {
        this.coverColorHex = coverColorHex;
    }
}
