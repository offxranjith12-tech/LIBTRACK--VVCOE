package com.vvce.libtrack.service;

import com.vvce.libtrack.dto.ReservationDto;
import com.vvce.libtrack.dto.StudentDto;
import com.vvce.libtrack.dto.TransactionDto;
import com.vvce.libtrack.entity.BorrowTransaction;
import com.vvce.libtrack.entity.Student;
import com.vvce.libtrack.exception.ResourceNotFoundException;
import com.vvce.libtrack.repository.BorrowTransactionRepository;
import com.vvce.libtrack.repository.ReservationRepository;
import com.vvce.libtrack.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class StudentService {

    private final StudentRepository studentRepository;
    private final BorrowTransactionRepository transactionRepository;
    private final ReservationRepository reservationRepository;

    /** Powers the student search box on the Issue Book screen. */
    public List<StudentDto> search(String query) {
        return studentRepository.search(query == null ? "" : query).stream().map(StudentDto::from).toList();
    }

    public StudentDto getByRegNo(String regNo) {
        return StudentDto.from(findByRegNo(regNo));
    }

    /** Powers the Student Information screen: profile + borrowed books + reservation history. */
    public StudentDto.StudentDetails getDetails(String regNo) {
        Student student = findByRegNo(regNo);

        List<TransactionDto> borrowed = transactionRepository.findActiveByStudent(regNo)
                .stream().map(TransactionDto::from).toList();

        List<ReservationDto> history = reservationRepository.findByStudent(regNo)
                .stream().map(ReservationDto::from).toList();

        return new StudentDto.StudentDetails(StudentDto.from(student), borrowed, history);
    }

    Student findByRegNo(String regNo) {
        return studentRepository.findByRegNo(regNo)
                .orElseThrow(() -> new ResourceNotFoundException("No student with regNo: " + regNo));
    }
}
