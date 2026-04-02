package com.giastore.controller;

import com.giastore.dto.LoginRequest;
import com.giastore.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest req) {
        String token = authService.login(req.getUsername(), req.getPassword());
        return ResponseEntity.ok(Map.of("token", token, "username", req.getUsername()));
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody LoginRequest req) {
        authService.register(req.getUsername(), req.getPassword());
        return ResponseEntity.ok(Map.of("message", "User registered successfully"));
    }

    @PostMapping("/change-password")
    public ResponseEntity<?> changePassword(@RequestBody Map<String, String> req) {
        boolean ok = authService.changePassword(req.get("username"), req.get("oldPassword"), req.get("newPassword"));
        if (ok) return ResponseEntity.ok(Map.of("message", "Password changed"));
        return ResponseEntity.status(400).body(Map.of("error", "Invalid current password"));
    }

    @PostMapping("/change-username")
    public ResponseEntity<?> changeUsername(@RequestBody Map<String, String> req) {
        authService.changeUsername(req.get("oldUsername"), req.get("newUsername"));
        return ResponseEntity.ok(Map.of("message", "Username updated"));
    }
}
