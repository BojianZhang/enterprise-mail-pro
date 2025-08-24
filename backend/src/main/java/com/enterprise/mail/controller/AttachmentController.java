package com.enterprise.mail.controller;

import com.enterprise.mail.dto.AttachmentDto;
import com.enterprise.mail.entity.Attachment;
import com.enterprise.mail.service.AttachmentService;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.io.File;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

/**
 * REST controller for attachment operations
 */
@RestController
@RequestMapping("/api/attachments")
@RequiredArgsConstructor
public class AttachmentController {
    
    private final AttachmentService attachmentService;
    
    /**
     * Download attachment
     */
    @GetMapping("/{id}/download")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Resource> downloadAttachment(@PathVariable Long id) {
        Attachment attachment = attachmentService.getAttachment(id);
        File file = attachmentService.getAttachmentFile(id);
        
        Resource resource = new FileSystemResource(file);
        
        String encodedFilename = URLEncoder.encode(attachment.getOriginalFileName(), StandardCharsets.UTF_8)
                .replaceAll("\\+", "%20");
        
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(attachment.getContentType()))
                .header(HttpHeaders.CONTENT_DISPOSITION, 
                        "attachment; filename=\"" + attachment.getOriginalFileName() + 
                        "\"; filename*=UTF-8''" + encodedFilename)
                .contentLength(file.length())
                .body(resource);
    }
    
    /**
     * View attachment inline
     */
    @GetMapping("/{id}/view")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Resource> viewAttachment(@PathVariable Long id) {
        Attachment attachment = attachmentService.getAttachment(id);
        File file = attachmentService.getAttachmentFile(id);
        
        Resource resource = new FileSystemResource(file);
        
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(attachment.getContentType()))
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline")
                .contentLength(file.length())
                .body(resource);
    }
    
    /**
     * Get attachment info
     */
    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<AttachmentDto> getAttachmentInfo(@PathVariable Long id) {
        Attachment attachment = attachmentService.getAttachment(id);
        return ResponseEntity.ok(attachmentService.toDto(attachment));
    }
    
    /**
     * Delete attachment
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> deleteAttachment(@PathVariable Long id) {
        attachmentService.deleteAttachment(id);
        return ResponseEntity.noContent().build();
    }
}