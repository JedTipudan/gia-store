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
        return ResponseEntity.ok(authService.login(req.getUsername(), req.getPassword()));
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody Map<String, String> req) {
        authService.register(req.get("username"), req.get("password"),
                req.get("fullName"), req.get("phone"));
        return ResponseEntity.ok(Map.of("message", "Account created successfully"));
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

    @GetMapping("/profile/{username}")
    public ResponseEntity<?> getProfile(@PathVariable String username) {
        return ResponseEntity.ok(authService.getProfile(username));
    }

    @PutMapping("/profile/{username}")
    public ResponseEntity<?> updateProfile(@PathVariable String username,
                                            @RequestBody Map<String, String> req) {
        return ResponseEntity.ok(authService.updateProfile(username,
                req.get("fullName"), req.get("phone"), req.get("email")));
    }
}
