package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.ApiResponse;
import com.vvce.libtrack.dto.LoginRequest;
import com.vvce.libtrack.dto.LoginResponse;
import com.vvce.libtrack.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    public ApiResponse<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        return ApiResponse.ok("Login successful", authService.login(request));
    }
}
