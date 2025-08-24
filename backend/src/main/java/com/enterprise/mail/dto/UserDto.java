package com.enterprise.mail.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class UserDto {
    private Long id;
    private String username;
    private String email;
    private String firstName;
    private String lastName;
    private String phoneNumber;
    private String avatar;
    private String role;
    private String status;
    private Boolean emailVerified;
    private Long storageQuota;
    private Long storageUsed;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}