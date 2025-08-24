package com.enterprise.mail.controller;

import com.enterprise.mail.dto.ForgotPasswordRequest;
import com.enterprise.mail.dto.ResetPasswordRequest;
import com.enterprise.mail.service.PasswordResetService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * Password Reset Controller
 */
@Tag(name = "Password Reset", description = "密码重置接口")
@Slf4j
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class PasswordResetController {
    
    private final PasswordResetService passwordResetService;
    
    @Operation(summary = "发送密码重置邮件")
    @PostMapping("/forgot-password")
    public ResponseEntity<Map<String, String>> forgotPassword(@Valid @RequestBody ForgotPasswordRequest request) {
        log.info("Password reset requested for email: {}", request.getEmail());
        
        passwordResetService.sendPasswordResetEmail(request.getEmail());
        
        Map<String, String> response = new HashMap<>();
        response.put("message", "密码重置链接已发送到您的邮箱");
        response.put("status", "success");
        
        return ResponseEntity.ok(response);
    }
    
    @Operation(summary = "重置密码")
    @PostMapping("/reset-password")
    public ResponseEntity<Map<String, String>> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        log.info("Password reset for token: {}", request.getToken());
        
        passwordResetService.resetPassword(request.getToken(), request.getPassword());
        
        Map<String, String> response = new HashMap<>();
        response.put("message", "密码重置成功");
        response.put("status", "success");
        
        return ResponseEntity.ok(response);
    }
    
    @Operation(summary = "验证重置令牌")
    @GetMapping("/verify-reset-token")
    public ResponseEntity<Map<String, Boolean>> verifyResetToken(@RequestParam String token) {
        boolean valid = passwordResetService.verifyResetToken(token);
        
        Map<String, Boolean> response = new HashMap<>();
        response.put("valid", valid);
        
        return ResponseEntity.ok(response);
    }
}