package com.vvce.libtrack.service;

import com.vvce.libtrack.dto.AuthDtos;
import com.vvce.libtrack.dto.StaffDto;
import com.vvce.libtrack.entity.Staff;
import com.vvce.libtrack.exception.BadRequestException;
import com.vvce.libtrack.exception.ResourceNotFoundException;
import com.vvce.libtrack.repository.StaffRepository;
import com.vvce.libtrack.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final AuthenticationManager authenticationManager;
    private final StaffRepository staffRepository;
    private final JwtUtil jwtUtil;
    private final PasswordEncoder passwordEncoder;

    public AuthDtos.LoginResponse login(AuthDtos.LoginRequest request) {
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.username(), request.password()));
        } catch (BadCredentialsException e) {
            throw new BadRequestException("Invalid username or password");
        }

        Staff staff = staffRepository.findByUsername(request.username())
                .orElseThrow(() -> new ResourceNotFoundException("Staff not found"));

        String token = jwtUtil.generateToken(staff.getUsername(), staff.getStaffId());
        return new AuthDtos.LoginResponse(token, StaffDto.from(staff));
    }

    public void changePassword(String username, AuthDtos.ChangePasswordRequest request) {
        Staff staff = staffRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("Staff not found"));

        if (!passwordEncoder.matches(request.currentPassword(), staff.getPassword())) {
            throw new BadRequestException("Current password is incorrect");
        }
        staff.setPassword(passwordEncoder.encode(request.newPassword()));
        staffRepository.save(staff);
    }
}
