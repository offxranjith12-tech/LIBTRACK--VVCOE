package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.StudentDto;
import com.vvce.libtrack.service.StudentService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Backs the student search step on Issue Book, and the Student Information screen. */
@RestController
@RequestMapping("/api/students")
@RequiredArgsConstructor
public class StudentController {

    private final StudentService studentService;

    @GetMapping("/search")
    public List<StudentDto> search(@RequestParam(required = false) String query) {
        return studentService.search(query);
    }

    @GetMapping("/{regNo}")
    public StudentDto getByRegNo(@PathVariable String regNo) {
        return studentService.getByRegNo(regNo);
    }

    @GetMapping("/{regNo}/details")
    public StudentDto.StudentDetails getDetails(@PathVariable String regNo) {
        return studentService.getDetails(regNo);
    }
}
