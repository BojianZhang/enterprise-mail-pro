package com.enterprise.mail.service;

import com.enterprise.mail.entity.User;
import com.enterprise.mail.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Password Reset Service
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class PasswordResetService {
    
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JavaMailSender mailSender;
    
    @Value("${spring.mail.username}")
    private String fromEmail;
    
    @Value("${server.port}")
    private String serverPort;
    
    // 使用线程安全的ConcurrentHashMap存储重置令牌（生产环境应该使用Redis或数据库）
    private final Map<String, ResetToken> resetTokens = new ConcurrentHashMap<>();
    
    /**
     * 发送密码重置邮件
     */
    public void sendPasswordResetEmail(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("用户不存在"));
        
        // 生成重置令牌
        String token = UUID.randomUUID().toString();
        
        // 保存令牌（实际应该存储在数据库中）
        ResetToken resetToken = new ResetToken();
        resetToken.setToken(token);
        resetToken.setUserId(user.getId());
        resetToken.setExpiryTime(LocalDateTime.now().plusHours(1));
        resetTokens.put(token, resetToken);
        
        // 构建重置链接
        String resetLink = "http://localhost:3000/reset-password?token=" + token;
        
        // 发送邮件
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(email);
            message.setSubject("密码重置 - 企业邮件系统");
            message.setText(buildEmailContent(user.getUsername(), resetLink));
            
            mailSender.send(message);
            log.info("Password reset email sent to: {}", email);
        } catch (Exception e) {
            log.error("Failed to send password reset email to: {}", email, e);
            // 在开发环境，即使邮件发送失败也继续
            log.info("Reset link (for development): {}", resetLink);
        }
    }
    
    /**
     * 重置密码
     */
    public void resetPassword(String token, String newPassword) {
        // 验证令牌
        ResetToken resetToken = resetTokens.get(token);
        if (resetToken == null) {
            throw new IllegalArgumentException("无效的重置令牌");
        }
        
        // 检查令牌是否过期
        if (resetToken.getExpiryTime().isBefore(LocalDateTime.now())) {
            resetTokens.remove(token);
            throw new IllegalArgumentException("重置令牌已过期");
        }
        
        // 更新密码
        User user = userRepository.findById(resetToken.getUserId())
                .orElseThrow(() -> new IllegalArgumentException("用户不存在"));
        
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
        
        // 删除使用过的令牌
        resetTokens.remove(token);
        
        log.info("Password reset successful for user: {}", user.getUsername());
    }
    
    /**
     * 验证重置令牌
     */
    public boolean verifyResetToken(String token) {
        ResetToken resetToken = resetTokens.get(token);
        if (resetToken == null) {
            return false;
        }
        
        // 检查是否过期
        if (resetToken.getExpiryTime().isBefore(LocalDateTime.now())) {
            resetTokens.remove(token);
            return false;
        }
        
        return true;
    }
    
    /**
     * 构建邮件内容
     */
    private String buildEmailContent(String username, String resetLink) {
        return String.format("""
            尊敬的 %s：
            
            您好！
            
            我们收到了您的密码重置请求。请点击以下链接重置您的密码：
            
            %s
            
            该链接将在1小时后失效。
            
            如果您没有请求重置密码，请忽略此邮件。
            
            此致
            企业邮件系统团队
            """, username, resetLink);
    }
    
    /**
     * 重置令牌内部类
     */
    private static class ResetToken {
        private String token;
        private Long userId;
        private LocalDateTime expiryTime;
        
        // Getters and Setters
        public String getToken() {
            return token;
        }
        
        public void setToken(String token) {
            this.token = token;
        }
        
        public Long getUserId() {
            return userId;
        }
        
        public void setUserId(Long userId) {
            this.userId = userId;
        }
        
        public LocalDateTime getExpiryTime() {
            return expiryTime;
        }
        
        public void setExpiryTime(LocalDateTime expiryTime) {
            this.expiryTime = expiryTime;
        }
    }
}