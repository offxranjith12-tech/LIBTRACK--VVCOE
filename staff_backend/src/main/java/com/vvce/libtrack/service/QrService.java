package com.vvce.libtrack.service;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.vvce.libtrack.dto.BookDto;
import com.vvce.libtrack.dto.StudentDto;
import com.vvce.libtrack.exception.ResourceNotFoundException;
import com.vvce.libtrack.repository.BookRepository;
import com.vvce.libtrack.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;

@Service
@RequiredArgsConstructor
public class QrService {

    private final BookRepository bookRepository;
    private final StudentRepository studentRepository;

    /** Powers the "Book QR Code" branch of the QR Scanner screen — the scanned
     *  payload is expected to encode the book's ISBN. */
    public BookDto lookupBook(String code) {
        var book = bookRepository.findByIsbn(code)
                .or(() -> bookRepository.findById(code))
                .orElseThrow(() -> new ResourceNotFoundException("No book found for scanned code: " + code));
        return BookDto.from(book);
    }

    /** Powers the "Student ID QR Code" branch of the QR Scanner screen — the
     *  scanned payload is expected to encode the student's register number. */
    public StudentDto lookupStudent(String code) {
        var student = studentRepository.findByRegNo(code)
                .orElseThrow(() -> new ResourceNotFoundException("No student found for scanned code: " + code));
        return StudentDto.from(student);
    }

    /** Generates a PNG QR code (e.g. for the Book Details / Issue receipt screens). */
    public byte[] generateQrPng(String content, int size) {
        try {
            QRCodeWriter writer = new QRCodeWriter();
            BitMatrix matrix = writer.encode(content, BarcodeFormat.QR_CODE, size, size);
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            MatrixToImageWriter.writeToStream(matrix, "PNG", out);
            return out.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate QR code", e);
        }
    }
}
