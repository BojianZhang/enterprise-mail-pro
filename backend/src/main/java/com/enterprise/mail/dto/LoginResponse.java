package com.enterprise.mail.dto;

import lombok.Data;

@Data
public class LoginResponse {
    private String token;
    private String refreshToken;
    private String username;
    private String email;
    private String firstName;
    private String lastName;
    private String role;
}