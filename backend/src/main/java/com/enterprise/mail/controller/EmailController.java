package com.enterprise.mail.controller;

import com.enterprise.mail.dto.*;
import com.enterprise.mail.entity.Email;
import com.enterprise.mail.entity.User;
import com.enterprise.mail.exception.BusinessException;
import com.enterprise.mail.service.EmailService;
import com.enterprise.mail.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Email Controller with complete implementation
 */
@Slf4j
@Tag(name = "Email Management", description = "邮件管理接口")
@RestController
@RequestMapping("/emails")
@RequiredArgsConstructor
public class EmailController {
    
    private final EmailService emailService;
    private final UserService userService;
    
    @Operation(summary = "获取邮件列表")
    @GetMapping
    public ResponseEntity<Page<EmailDto>> getEmails(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(required = false) String folder,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String search,
            Pageable pageable) {
        
        User user = userService.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> BusinessException.userNotFound(0L));
        
        Page<Email> emails;
        
        if (search != null && !search.isEmpty()) {
            emails = emailService.searchEmails(user.getId(), search, pageable);
        } else if (folder != null && !folder.isEmpty()) {
            Long folderId = Long.parseLong(folder);
            emails = emailService.getEmailsByFolder(user.getId(), folderId, pageable);
        } else if (status != null && !status.isEmpty()) {
            Email.EmailStatus emailStatus = Email.EmailStatus.valueOf(status.toUpperCase());
            emails = emailService.getEmailsByStatus(user.getId(), emailStatus, pageable);
        } else {
            emails = emailService.getEmailsByUser(user.getId(), pageable);
        }
        
        Page<EmailDto> emailDtos = emails.map(this::convertToDto);
        return ResponseEntity.ok(emailDtos);
    }
    
    @Operation(summary = "获取邮件详情")
    @GetMapping("/{id}")
    public ResponseEntity<EmailDto> getEmail(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id) {
        
        User user = userService.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> BusinessException.userNotFound(0L));
        
        Email email = emailService.getEmailById(id)
                .orElseThrow(() -> BusinessException.emailNotFound(id));
        
        // 验证用户权限
        if (!email.getUser().getId().equals(user.getId())) {
            throw new BusinessException("Access denied", HttpStatus.FORBIDDEN);
        }
        
        // 标记为已读
        if (email.getStatus() == Email.EmailStatus.UNREAD) {
            emailService.markAsRead(id);
        }
        
        return ResponseEntity.ok(convertToDto(email));
    }
    
    @Operation(summary = "发送邮件")
    @PostMapping("/send")
    public ResponseEntity<EmailDto> sendEmail(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody SendEmailRequest request) {
        
        User user = userService.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> BusinessException.userNotFound(0L));
        
        Email email = new Email();
        email.setUser(user);
        email.setFromAddress(user.getEmail());
        email.setFromName(user.getUsername());
        email.setToAddresses(request.getTo());
        email.setCcAddresses(request.getCc());
        email.setBccAddresses(request.getBcc());
        email.setSubject(request.getSubject());
        email.setContentText(request.getContent());
        email.setContentHtml(request.getHtmlContent());
        email.setStatus(Email.EmailStatus.SENT);
        email.setDirection(Email.Direction.OUTBOUND);
        
        try {
            Email sentEmail = emailService.sendEmail(email, request.getAttachments());
            log.info("Email sent successfully by user: {}", user.getUsername());
            return ResponseEntity.status(HttpStatus.CREATED).body(convertToDto(sentEmail));
        } catch (Exception e) {
            log.error("Failed to send email", e);
            throw new BusinessException("Failed to send email: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    
    @Operation(summary = "保存草稿")
    @PostMapping("/draft")
    public ResponseEntity<EmailDto> saveDraft(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody SendEmailRequest request) {
        
        User user = userService.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> BusinessException.userNotFound(0L));
        
        Email draft = new Email();
        draft.setUser(user);
        draft.setFromAddress(user.getEmail());
        draft.setFromName(user.getUsername());
        draft.setToAddresses(request.getTo());
        draft.setCcAddresses(request.getCc());
        draft.setBccAddresses(request.getBcc());
        draft.setSubject(request.getSubject());
        draft.setContentText(request.getContent());
        draft.setContentHtml(request.getHtmlContent());
        draft.setStatus(Email.EmailStatus.DRAFT);
        draft.setDirection(Email.Direction.OUTBOUND);
        
        Email savedDraft = emailService.saveDraft(draft);
        log.info("Draft saved for user: {}", user.getUsername());
        return ResponseEntity.ok(convertToDto(savedDraft));
    }
    
    @Operation(summary = "删除邮件")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteEmail(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id) {
        
        User user = userService.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> BusinessException.userNotFound(0L));
        
        Email email = emailService.getEmailById(id)
                .orElseThrow(() -> BusinessException.emailNotFound(id));
        
        // 验证用户权限
        if (!email.getUser().getId().equals(user.getId())) {
            throw new BusinessException("Access denied", HttpStatus.FORBIDDEN);
        }
        
        emailService.deleteEmail(id);
        log.info("Email {} deleted by user: {}", id, user.getUsername());
        return ResponseEntity.noContent().build();
    }
    
    @Operation(summary = "批量删除邮件")
    @DeleteMapping("/batch")
    public ResponseEntity<Void> deleteEmails(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody List<Long> ids) {
        
        User user = userService.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> BusinessException.userNotFound(0L));
        
        for (Long id : ids) {
            try {
                Email email = emailService.getEmailById(id)
                        .orElseThrow(() -> BusinessException.emailNotFound(id));
                
                // 验证用户权限
                if (email.getUser().getId().equals(user.getId())) {
                    emailService.deleteEmail(id);
                }
            } catch (Exception e) {
                log.error("Failed to delete email {}: {}", id, e.getMessage());
            }
        }
        
        log.info("Batch delete {} emails by user: {}", ids.size(), user.getUsername());
        return ResponseEntity.noContent().build();
    }
    
    @Operation(summary = "标记已读")
    @PutMapping("/{id}/read")
    public ResponseEntity<Void> markAsRead(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id) {
        
        User user = userService.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> BusinessException.userNotFound(0L));
        
        Email email = emailService.getEmailById(id)
                .orElseThrow(() -> BusinessException.emailNotFound(id));
        
        // 验证用户权限
        if (!email.getUser().getId().equals(user.getId())) {
            throw new BusinessException("Access denied", HttpStatus.FORBIDDEN);
        }
        
        emailService.markAsRead(id);
        log.info("Email {} marked as read by user: {}", id, user.getUsername());
        return ResponseEntity.ok().build();
    }
    
    @Operation(summary = "标记未读")
    @PutMapping("/{id}/unread")
    public ResponseEntity<Void> markAsUnread(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id) {
        
        User user = userService.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> BusinessException.userNotFound(0L));
        
        Email email = emailService.getEmailById(id)
                .orElseThrow(() -> BusinessException.emailNotFound(id));
        
        // 验证用户权限
        if (!email.getUser().getId().equals(user.getId())) {
            throw new BusinessException("Access denied", HttpStatus.FORBIDDEN);
        }
        
        emailService.markAsUnread(id);
        log.info("Email {} marked as unread by user: {}", id, user.getUsername());
        return ResponseEntity.ok().build();
    }
    
    @Operation(summary = "标记重要")
    @PutMapping("/{id}/important")
    public ResponseEntity<Void> markAsImportant(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id) {
        
        User user = userService.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> BusinessException.userNotFound(0L));
        
        Email email = emailService.getEmailById(id)
                .orElseThrow(() -> BusinessException.emailNotFound(id));
        
        // 验证用户权限
        if (!email.getUser().getId().equals(user.getId())) {
            throw new BusinessException("Access denied", HttpStatus.FORBIDDEN);
        }
        
        emailService.markAsImportant(id);
        log.info("Email {} marked as important by user: {}", id, user.getUsername());
        return ResponseEntity.ok().build();
    }
    
    @Operation(summary = "星标邮件")
    @PutMapping("/{id}/star")
    public ResponseEntity<Void> starEmail(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id) {
        
        User user = userService.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> BusinessException.userNotFound(0L));
        
        Email email = emailService.getEmailById(id)
                .orElseThrow(() -> BusinessException.emailNotFound(id));
        
        // 验证用户权限
        if (!email.getUser().getId().equals(user.getId())) {
            throw new BusinessException("Access denied", HttpStatus.FORBIDDEN);
        }
        
        emailService.starEmail(id);
        log.info("Email {} starred by user: {}", id, user.getUsername());
        return ResponseEntity.ok().build();
    }
    
    @Operation(summary = "移动邮件到文件夹")
    @PutMapping("/{id}/move")
    public ResponseEntity<Void> moveEmail(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id,
            @RequestParam Long folderId) {
        
        User user = userService.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> BusinessException.userNotFound(0L));
        
        Email email = emailService.getEmailById(id)
                .orElseThrow(() -> BusinessException.emailNotFound(id));
        
        // 验证用户权限
        if (!email.getUser().getId().equals(user.getId())) {
            throw new BusinessException("Access denied", HttpStatus.FORBIDDEN);
        }
        
        emailService.moveToFolder(id, folderId);
        log.info("Email {} moved to folder {} by user: {}", id, folderId, user.getUsername());
        return ResponseEntity.ok().build();
    }
    
    @Operation(summary = "上传附件")
    @PostMapping("/attachments")
    public ResponseEntity<AttachmentDto> uploadAttachment(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam("file") MultipartFile file) {
        
        User user = userService.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> BusinessException.userNotFound(0L));
        
        if (file.isEmpty()) {
            throw new BusinessException("File is empty", HttpStatus.BAD_REQUEST);
        }
        
        if (file.getSize() > 25 * 1024 * 1024) {
            throw new BusinessException("File size exceeds 25MB limit", HttpStatus.PAYLOAD_TOO_LARGE);
        }
        
        try {
            AttachmentDto attachment = emailService.saveAttachment(file, user.getId());
            log.info("Attachment uploaded by user: {}", user.getUsername());
            return ResponseEntity.ok(attachment);
        } catch (Exception e) {
            log.error("Failed to upload attachment", e);
            throw new BusinessException("Failed to upload attachment: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    
    // Helper method to convert Email entity to DTO
    private EmailDto convertToDto(Email email) {
        EmailDto dto = new EmailDto();
        dto.setId(email.getId());
        dto.setMessageId(email.getMessageId());
        dto.setFromAddress(email.getFromAddress());
        dto.setFromName(email.getFromName());
        dto.setToAddresses(email.getToAddresses());
        dto.setCcAddresses(email.getCcAddresses());
        dto.setBccAddresses(email.getBccAddresses());
        dto.setSubject(email.getSubject());
        dto.setContentText(email.getContentText());
        dto.setContentHtml(email.getContentHtml());
        dto.setStatus(email.getStatus().name());
        dto.setDirection(email.getDirection().name());
        dto.setSentDate(email.getSentDate());
        dto.setReceivedDate(email.getReceivedDate());
        dto.setIsRead(email.getStatus() != Email.EmailStatus.UNREAD);
        dto.setIsStarred(email.getIsStarred());
        dto.setIsImportant(email.getIsImportant());
        dto.setHasAttachments(email.getHasAttachments());
        dto.setSizeBytes(email.getSizeBytes());
        dto.setCreatedAt(email.getCreatedAt());
        dto.setUpdatedAt(email.getUpdatedAt());
        return dto;
    }
}