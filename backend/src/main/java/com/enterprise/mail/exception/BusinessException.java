package com.enterprise.mail.exception;

import org.springframework.http.HttpStatus;

/**
 * Custom business exception for application-specific errors
 */
public class BusinessException extends RuntimeException {
    
    private final HttpStatus status;
    private final String error;
    
    public BusinessException(String message) {
        super(message);
        this.status = HttpStatus.BAD_REQUEST;
        this.error = "Business Error";
    }
    
    public BusinessException(String message, HttpStatus status) {
        super(message);
        this.status = status;
        this.error = status.getReasonPhrase();
    }
    
    public BusinessException(String message, HttpStatus status, String error) {
        super(message);
        this.status = status;
        this.error = error;
    }
    
    public BusinessException(String message, Throwable cause) {
        super(message, cause);
        this.status = HttpStatus.BAD_REQUEST;
        this.error = "Business Error";
    }
    
    public BusinessException(String message, HttpStatus status, Throwable cause) {
        super(message, cause);
        this.status = status;
        this.error = status.getReasonPhrase();
    }
    
    public HttpStatus getStatus() {
        return status;
    }
    
    public String getError() {
        return error;
    }
    
    // Common business exceptions
    public static BusinessException userNotFound(Long userId) {
        return new BusinessException(
            String.format("User with ID %d not found", userId),
            HttpStatus.NOT_FOUND,
            "User Not Found"
        );
    }
    
    public static BusinessException emailNotFound(Long emailId) {
        return new BusinessException(
            String.format("Email with ID %d not found", emailId),
            HttpStatus.NOT_FOUND,
            "Email Not Found"
        );
    }
    
    public static BusinessException duplicateEmail(String email) {
        return new BusinessException(
            String.format("Email address '%s' is already registered", email),
            HttpStatus.CONFLICT,
            "Duplicate Email"
        );
    }
    
    public static BusinessException invalidCredentials() {
        return new BusinessException(
            "Invalid username or password",
            HttpStatus.UNAUTHORIZED,
            "Authentication Failed"
        );
    }
    
    public static BusinessException accountLocked(String username) {
        return new BusinessException(
            String.format("Account '%s' is locked due to too many failed login attempts", username),
            HttpStatus.FORBIDDEN,
            "Account Locked"
        );
    }
    
    public static BusinessException insufficientStorage(Long userId) {
        return new BusinessException(
            String.format("User %d has insufficient storage space", userId),
            HttpStatus.INSUFFICIENT_STORAGE,
            "Storage Limit Exceeded"
        );
    }
    
    public static BusinessException invalidOperation(String message) {
        return new BusinessException(
            message,
            HttpStatus.BAD_REQUEST,
            "Invalid Operation"
        );
    }
    
    public static BusinessException serverError(String message) {
        return new BusinessException(
            message,
            HttpStatus.INTERNAL_SERVER_ERROR,
            "Server Error"
        );
    }
}