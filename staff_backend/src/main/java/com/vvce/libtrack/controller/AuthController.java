package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.AuthDtos;
import com.vvce.libtrack.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

/** Backs the (implicit) Login screen that should sit in front of the Staff
 *  Module now that the backend requires a JWT — see the Flutter README notes
 *  on adding /login as GoRouter's initial route with an auth redirect guard. */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    public AuthDtos.LoginResponse login(@Valid @RequestBody AuthDtos.LoginRequest request) {
        return authService.login(request);
    }

    /** Powers "Change Password" on the Profile screen. */
    @PutMapping("/change-password")
    public void changePassword(Authentication auth, @Valid @RequestBody AuthDtos.ChangePasswordRequest request) {
        authService.changePassword(auth.getName(), request);
    }
}
