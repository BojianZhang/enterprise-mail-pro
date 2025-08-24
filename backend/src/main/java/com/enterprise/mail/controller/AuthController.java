package com.enterprise.mail.controller;

import com.enterprise.mail.dto.LoginRequest;
import com.enterprise.mail.dto.LoginResponse;
import com.enterprise.mail.dto.RegisterRequest;
import com.enterprise.mail.dto.UserDto;
import com.enterprise.mail.entity.User;
import com.enterprise.mail.security.JwtTokenUtil;
import com.enterprise.mail.service.UserService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

/**
 * Authentication Controller
 */
@Slf4j
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {
    
    private final AuthenticationManager authenticationManager;
    private final UserService userService;
    private final JwtTokenUtil jwtTokenUtil;
    
    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest request, HttpServletRequest httpRequest) {
        log.info("Login attempt for user: {}", request.getUsername());
        
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.getUsername(), request.getPassword())
            );
            
            UserDetails userDetails = (UserDetails) authentication.getPrincipal();
            String token = jwtTokenUtil.generateToken(userDetails);
            String refreshToken = jwtTokenUtil.generateRefreshToken(userDetails);
            
            // Update last login
            User user = userService.findByUsername(userDetails.getUsername()).orElseThrow();
            userService.updateLastLogin(user.getId(), getClientIp(httpRequest));
            
            LoginResponse response = new LoginResponse();
            response.setToken(token);
            response.setRefreshToken(refreshToken);
            response.setUsername(user.getUsername());
            response.setEmail(user.getEmail());
            response.setRole(user.getRole().name());
            response.setFirstName(user.getFirstName());
            response.setLastName(user.getLastName());
            
            log.info("User {} logged in successfully", request.getUsername());
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("Login failed for user: {}", request.getUsername(), e);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
    }
    
    @PostMapping("/register")
    public ResponseEntity<UserDto> register(@Valid @RequestBody RegisterRequest request) {
        log.info("Registration attempt for username: {}", request.getUsername());
        
        try {
            User user = userService.registerUser(
                    request.getUsername(),
                    request.getEmail(),
                    request.getPassword(),
                    request.getFirstName(),
                    request.getLastName()
            );
            
            UserDto userDto = new UserDto();
            userDto.setId(user.getId());
            userDto.setUsername(user.getUsername());
            userDto.setEmail(user.getEmail());
            userDto.setFirstName(user.getFirstName());
            userDto.setLastName(user.getLastName());
            userDto.setRole(user.getRole().name());
            userDto.setStatus(user.getStatus().name());
            
            log.info("User {} registered successfully", request.getUsername());
            
            return ResponseEntity.status(HttpStatus.CREATED).body(userDto);
            
        } catch (IllegalArgumentException e) {
            log.error("Registration failed: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }
    
    @PostMapping("/refresh")
    public ResponseEntity<LoginResponse> refreshToken(@RequestHeader("Authorization") String refreshToken) {
        try {
            if (refreshToken != null && refreshToken.startsWith("Bearer ")) {
                refreshToken = refreshToken.substring(7);
            }
            
            if (jwtTokenUtil.validateToken(refreshToken)) {
                String username = jwtTokenUtil.extractUsername(refreshToken);
                UserDetails userDetails = userService.loadUserByUsername(username);
                
                String newToken = jwtTokenUtil.generateToken(userDetails);
                String newRefreshToken = jwtTokenUtil.generateRefreshToken(userDetails);
                
                User user = userService.findByUsername(username).orElseThrow();
                
                LoginResponse response = new LoginResponse();
                response.setToken(newToken);
                response.setRefreshToken(newRefreshToken);
                response.setUsername(user.getUsername());
                response.setEmail(user.getEmail());
                response.setRole(user.getRole().name());
                response.setFirstName(user.getFirstName());
                response.setLastName(user.getLastName());
                
                return ResponseEntity.ok(response);
            }
        } catch (Exception e) {
            log.error("Token refresh failed", e);
        }
        
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
    }
    
    @PostMapping("/logout")
    public ResponseEntity<Void> logout(@RequestHeader("Authorization") String token) {
        // In a real application, you might want to blacklist the token
        log.info("User logged out");
        return ResponseEntity.ok().build();
    }
    
    @GetMapping("/validate")
    public ResponseEntity<Boolean> validateToken(@RequestHeader("Authorization") String token) {
        if (token != null && token.startsWith("Bearer ")) {
            token = token.substring(7);
            return ResponseEntity.ok(jwtTokenUtil.validateToken(token));
        }
        return ResponseEntity.ok(false);
    }
    
    private String getClientIp(HttpServletRequest request) {
        String xfHeader = request.getHeader("X-Forwarded-For");
        if (xfHeader == null) {
            return request.getRemoteAddr();
        }
        return xfHeader.split(",")[0];
    }
}