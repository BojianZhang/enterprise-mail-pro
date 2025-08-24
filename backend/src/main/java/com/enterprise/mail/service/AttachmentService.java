package com.enterprise.mail.service;

import com.enterprise.mail.dto.AttachmentDto;
import com.enterprise.mail.entity.Attachment;
import com.enterprise.mail.entity.Email;
import com.enterprise.mail.entity.User;
import com.enterprise.mail.exception.BusinessException;
import com.enterprise.mail.repository.AttachmentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.UUID;

/**
 * Service for managing email attachments
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class AttachmentService {
    
    private final AttachmentRepository attachmentRepository;
    
    @Value("${mail.attachments.storage-path:/var/mail/attachments}")
    private String storageBasePath;
    
    @Value("${mail.attachments.max-size:10485760}") // 10MB default
    private Long maxFileSize;
    
    /**
     * Save attachment for email
     */
    public Attachment saveAttachment(MultipartFile file, Email email) throws IOException {
        // Validate file size
        if (file.getSize() > maxFileSize) {
            throw new BusinessException("File size exceeds maximum allowed: " + maxFileSize + " bytes");
        }
        
        // Generate unique filename
        String originalFilename = file.getOriginalFilename();
        String fileExtension = getFileExtension(originalFilename);
        String uniqueFilename = UUID.randomUUID().toString() + fileExtension;
        
        // Create storage directory if not exists
        Path userStoragePath = Paths.get(storageBasePath, email.getUser().getId().toString());
        Files.createDirectories(userStoragePath);
        
        // Save file to disk
        Path filePath = userStoragePath.resolve(uniqueFilename);
        file.transferTo(filePath.toFile());
        
        // Calculate checksum
        String checksum = calculateChecksum(filePath.toFile());
        
        // Create attachment entity
        Attachment attachment = new Attachment();
        attachment.setFileName(uniqueFilename);
        attachment.setOriginalFileName(originalFilename);
        attachment.setContentType(file.getContentType());
        attachment.setFileSize(file.getSize());
        attachment.setStoragePath(filePath.toString());
        attachment.setChecksum(checksum);
        attachment.setEmail(email);
        attachment.setUploadDate(new Date());
        attachment.setIsInline(false);
        
        return attachmentRepository.save(attachment);
    }
    
    /**
     * Save multiple attachments
     */
    public List<Attachment> saveAttachments(List<MultipartFile> files, Email email) throws IOException {
        List<Attachment> attachments = new ArrayList<>();
        
        for (MultipartFile file : files) {
            if (!file.isEmpty()) {
                attachments.add(saveAttachment(file, email));
            }
        }
        
        return attachments;
    }
    
    /**
     * Get attachment by ID
     */
    public Attachment getAttachment(Long attachmentId) {
        return attachmentRepository.findById(attachmentId)
                .orElseThrow(() -> new BusinessException("Attachment not found: " + attachmentId));
    }
    
    /**
     * Get attachment file
     */
    public File getAttachmentFile(Long attachmentId) {
        Attachment attachment = getAttachment(attachmentId);
        File file = new File(attachment.getStoragePath());
        
        if (!file.exists()) {
            throw new BusinessException("Attachment file not found: " + attachment.getStoragePath());
        }
        
        return file;
    }
    
    /**
     * Delete attachment
     */
    public void deleteAttachment(Long attachmentId) {
        Attachment attachment = getAttachment(attachmentId);
        
        // Delete file from disk
        try {
            Files.deleteIfExists(Paths.get(attachment.getStoragePath()));
        } catch (IOException e) {
            log.error("Failed to delete attachment file: " + attachment.getStoragePath(), e);
        }
        
        // Delete from database
        attachmentRepository.delete(attachment);
    }
    
    /**
     * Convert attachment to DTO
     */
    public AttachmentDto toDto(Attachment attachment) {
        return AttachmentDto.builder()
                .id(attachment.getId())
                .fileName(attachment.getFileName())
                .originalFileName(attachment.getOriginalFileName())
                .contentType(attachment.getContentType())
                .fileSize(attachment.getFileSize())
                .storagePath(attachment.getStoragePath())
                .downloadUrl("/api/attachments/" + attachment.getId() + "/download")
                .uploadDate(attachment.getUploadDate())
                .emailId(attachment.getEmail().getId())
                .userId(attachment.getEmail().getUser().getId())
                .checksum(attachment.getChecksum())
                .isInline(attachment.getIsInline())
                .contentId(attachment.getContentId())
                .build();
    }
    
    // Helper methods
    
    private String getFileExtension(String filename) {
        if (filename == null || !filename.contains(".")) {
            return "";
        }
        return filename.substring(filename.lastIndexOf("."));
    }
    
    private String calculateChecksum(File file) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] fileBytes = Files.readAllBytes(file.toPath());
            byte[] digestBytes = md.digest(fileBytes);
            
            StringBuilder sb = new StringBuilder();
            for (byte b : digestBytes) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException | IOException e) {
            log.error("Failed to calculate checksum", e);
            return null;
        }
    }
}