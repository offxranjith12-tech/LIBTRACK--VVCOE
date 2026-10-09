package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.BookDto;
import com.vvce.libtrack.dto.StudentDto;
import com.vvce.libtrack.service.QrService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/** Backs the QR Scanner screen (both scan branches) and QR image display on
 *  Book Details / Issue receipt. */
@RestController
@RequestMapping("/api/qr")
@RequiredArgsConstructor
public class QrController {

    private final QrService qrService;

    @GetMapping("/lookup/book/{code}")
    public BookDto lookupBook(@PathVariable String code) {
        return qrService.lookupBook(code);
    }

    @GetMapping("/lookup/student/{code}")
    public StudentDto lookupStudent(@PathVariable String code) {
        return qrService.lookupStudent(code);
    }

    /** Returns a PNG QR code image for the given content (e.g. a book ISBN). */
    @GetMapping(value = "/generate", produces = MediaType.IMAGE_PNG_VALUE)
    public ResponseEntity<byte[]> generate(@RequestParam String content,
                                            @RequestParam(defaultValue = "300") int size) {
        return ResponseEntity.ok(qrService.generateQrPng(content, size));
    }
}
