package com.enterprise.mail.service;

import com.enterprise.mail.dto.AttachmentDto;
import com.enterprise.mail.entity.Attachment;
import com.enterprise.mail.entity.Email;
import com.enterprise.mail.entity.EmailAlias;
import com.enterprise.mail.entity.EmailFolder;
import com.enterprise.mail.entity.User;
import com.enterprise.mail.exception.BusinessException;
import com.enterprise.mail.repository.EmailRepository;
import com.enterprise.mail.repository.EmailAliasRepository;
import com.enterprise.mail.repository.EmailFolderRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import jakarta.mail.*;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Date;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Email Service for managing emails
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class EmailService {
    
    private final EmailRepository emailRepository;
    private final EmailAliasRepository aliasRepository;
    private final EmailFolderRepository folderRepository;
    private final UserService userService;
    private final MailServerService mailServerService;
    private final AttachmentService attachmentService;
    
    /**
     * Save received email
     */
    public Email saveReceivedEmail(String from, String to, MimeMessage message) throws MessagingException, IOException {
        // Find the recipient alias
        EmailAlias alias = aliasRepository.findByAliasAddress(to)
                .orElseThrow(() -> new IllegalArgumentException("Recipient alias not found: " + to));
        
        User user = alias.getUser();
        
        // Find inbox folder
        EmailFolder inbox = folderRepository.findByUserIdAndType(user.getId(), EmailFolder.FolderType.INBOX)
                .orElseThrow(() -> new IllegalStateException("Inbox folder not found for user"));
        
        // Create email entity
        Email email = new Email();
        email.setMessageId(generateMessageId());
        email.setFromAddress(from);
        email.setFromName(getFromName(message.getFrom()));
        email.setToAddresses(to);
        email.setSubject(message.getSubject());
        email.setContentText(getTextContent(message));
        email.setContentHtml(getHtmlContent(message));
        email.setRawContent(getRawContent(message));
        email.setStatus(Email.EmailStatus.UNREAD);
        email.setType(Email.EmailType.RECEIVED);
        email.setSentDate(message.getSentDate() != null ? message.getSentDate() : new Date());
        email.setReceivedDate(new Date());
        email.setUser(user);
        email.setAlias(alias);
        email.setFolder(inbox);
        email.setSizeBytes((long) message.getSize());
        email.setHasAttachments(hasAttachments(message));
        
        // Process headers
        processHeaders(email, message);
        
        // Save email
        email = emailRepository.save(email);
        
        // Update folder counts
        updateFolderCounts(inbox);
        
        // Update user storage
        updateUserStorage(user, email.getSizeBytes());
        
        log.info("Saved received email: {} from {} to {}", email.getMessageId(), from, to);
        
        return email;
    }
    
    /**
     * Save sent email
     */
    public Email saveSentEmail(String from, String to, MimeMessage message) throws MessagingException, IOException {
        // Find the sender alias
        EmailAlias alias = aliasRepository.findByAliasAddress(from)
                .orElseThrow(() -> new IllegalArgumentException("Sender alias not found: " + from));
        
        User user = alias.getUser();
        
        // Find sent folder
        EmailFolder sentFolder = folderRepository.findByUserIdAndType(user.getId(), EmailFolder.FolderType.SENT)
                .orElseThrow(() -> new IllegalStateException("Sent folder not found for user"));
        
        // Create email entity
        Email email = new Email();
        email.setMessageId(generateMessageId());
        email.setFromAddress(from);
        email.setFromName(user.getFirstName() + " " + user.getLastName());
        email.setToAddresses(to);
        email.setSubject(message.getSubject());
        email.setContentText(getTextContent(message));
        email.setContentHtml(getHtmlContent(message));
        email.setRawContent(getRawContent(message));
        email.setStatus(Email.EmailStatus.READ);
        email.setType(Email.EmailType.SENT);
        email.setSentDate(new Date());
        email.setUser(user);
        email.setAlias(alias);
        email.setFolder(sentFolder);
        email.setSizeBytes((long) message.getSize());
        email.setHasAttachments(hasAttachments(message));
        
        // Save email
        email = emailRepository.save(email);
        
        // Update folder counts
        updateFolderCounts(sentFolder);
        
        // Update user storage
        updateUserStorage(user, email.getSizeBytes());
        
        log.info("Saved sent email: {} from {} to {}", email.getMessageId(), from, to);
        
        return email;
    }
    
    /**
     * Get emails by user
     */
    public Page<Email> getEmailsByUser(Long userId, Pageable pageable) {
        return emailRepository.findByUserId(userId, pageable);
    }
    
    /**
     * Get emails by folder
     */
    public Page<Email> getEmailsByFolder(Long userId, Long folderId, Pageable pageable) {
        return emailRepository.findByUserIdAndFolderId(userId, folderId, pageable);
    }
    
    /**
     * Search emails
     */
    public Page<Email> searchEmails(Long userId, String searchTerm, Pageable pageable) {
        return emailRepository.searchEmails(userId, searchTerm, pageable);
    }
    
    /**
     * Mark email as read
     */
    public void markAsRead(Long emailId) {
        Email email = emailRepository.findById(emailId)
                .orElseThrow(() -> new IllegalArgumentException("Email not found"));
        
        if (email.getStatus() == Email.EmailStatus.UNREAD) {
            email.setStatus(Email.EmailStatus.READ);
            emailRepository.save(email);
            
            // Update folder unread count
            EmailFolder folder = email.getFolder();
            if (folder != null) {
                folder.setUnreadCount(Math.max(0, folder.getUnreadCount() - 1));
                folderRepository.save(folder);
            }
        }
    }
    
    /**
     * Delete email
     */
    public void deleteEmail(Long emailId) {
        Email email = emailRepository.findById(emailId)
                .orElseThrow(() -> new IllegalArgumentException("Email not found"));
        
        // Move to trash folder
        EmailFolder trash = folderRepository.findByUserIdAndType(email.getUser().getId(), EmailFolder.FolderType.TRASH)
                .orElseThrow(() -> new IllegalStateException("Trash folder not found"));
        
        EmailFolder oldFolder = email.getFolder();
        email.setFolder(trash);
        email.setStatus(Email.EmailStatus.DELETED);
        emailRepository.save(email);
        
        // Update folder counts
        updateFolderCounts(oldFolder);
        updateFolderCounts(trash);
    }
    
    /**
     * Star/unstar email
     */
    public void toggleStar(Long emailId) {
        Email email = emailRepository.findById(emailId)
                .orElseThrow(() -> new IllegalArgumentException("Email not found"));
        
        email.setIsStarred(!email.getIsStarred());
        emailRepository.save(email);
    }
    
    /**
     * Move email to folder
     */
    public void moveToFolder(Long emailId, Long folderId) {
        Email email = emailRepository.findById(emailId)
                .orElseThrow(() -> new IllegalArgumentException("Email not found"));
        
        EmailFolder newFolder = folderRepository.findById(folderId)
                .orElseThrow(() -> new IllegalArgumentException("Folder not found"));
        
        EmailFolder oldFolder = email.getFolder();
        email.setFolder(newFolder);
        emailRepository.save(email);
        
        // Update folder counts
        updateFolderCounts(oldFolder);
        updateFolderCounts(newFolder);
    }
    
    // Helper methods
    
    private String generateMessageId() {
        return UUID.randomUUID().toString() + "@enterprise.mail";
    }
    
    private String getFromName(Address[] addresses) {
        if (addresses != null && addresses.length > 0) {
            Address addr = addresses[0];
            if (addr instanceof InternetAddress) {
                InternetAddress internetAddr = (InternetAddress) addr;
                return internetAddr.getPersonal() != null ? internetAddr.getPersonal() : internetAddr.getAddress();
            } else {
                return addr.toString();
            }
        }
        return "";
    }
    
    private String getTextContent(MimeMessage message) throws MessagingException, IOException {
        Object content = message.getContent();
        if (content instanceof String) {
            return (String) content;
        } else if (content instanceof Multipart) {
            return extractTextFromMultipart((Multipart) content, false);
        }
        return "";
    }
    
    private String getHtmlContent(MimeMessage message) throws MessagingException, IOException {
        Object content = message.getContent();
        if (content instanceof String && message.getContentType().contains("text/html")) {
            return (String) content;
        } else if (content instanceof Multipart) {
            return extractTextFromMultipart((Multipart) content, true);
        }
        return "";
    }
    
    private String extractTextFromMultipart(Multipart multipart, boolean preferHtml) throws MessagingException, IOException {
        StringBuilder result = new StringBuilder();
        int count = multipart.getCount();
        for (int i = 0; i < count; i++) {
            BodyPart bodyPart = multipart.getBodyPart(i);
            String disposition = bodyPart.getDisposition();
            
            if (disposition == null) { // Not an attachment
                Object content = bodyPart.getContent();
                if (content instanceof String) {
                    if ((preferHtml && bodyPart.isMimeType("text/html")) ||
                        (!preferHtml && bodyPart.isMimeType("text/plain"))) {
                        result.append(content);
                    }
                } else if (content instanceof Multipart) {
                    result.append(extractTextFromMultipart((Multipart) content, preferHtml));
                }
            }
        }
        return result.toString();
    }
    
    private String getRawContent(MimeMessage message) throws MessagingException, IOException {
        // Convert message to raw string safely
        try (ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
            message.writeTo(baos);
            return baos.toString("UTF-8");
        }
    }
    
    private boolean hasAttachments(MimeMessage message) throws MessagingException {
        try {
            Object content = message.getContent();
            if (content instanceof Multipart) {
                Multipart multipart = (Multipart) content;
                for (int i = 0; i < multipart.getCount(); i++) {
                    BodyPart bodyPart = multipart.getBodyPart(i);
                    String disposition = bodyPart.getDisposition();
                    if (disposition != null && 
                        (disposition.equalsIgnoreCase(Part.ATTACHMENT) || 
                         disposition.equalsIgnoreCase(Part.INLINE))) {
                        return true;
                    }
                }
            }
        } catch (IOException e) {
            log.error("Error checking attachments", e);
        }
        return false;
    }
    
    private void processHeaders(Email email, MimeMessage message) throws MessagingException {
        // Process email headers
        String messageId = message.getMessageID();
        if (messageId != null) {
            email.setMessageId(messageId);
        }
        
        String[] inReplyTo = message.getHeader("In-Reply-To");
        if (inReplyTo != null && inReplyTo.length > 0) {
            email.setInReplyTo(inReplyTo[0]);
        }
        
        String[] references = message.getHeader("References");
        if (references != null && references.length > 0) {
            email.setReferences(references[0]);
        }
    }
    
    private void updateFolderCounts(EmailFolder folder) {
        if (folder == null) return;
        
        Long unreadCount = emailRepository.countUnreadEmailsInFolder(folder.getId());
        folder.setUnreadCount(unreadCount.intValue());
        Long totalCount = emailRepository.countByFolderId(folder.getId());
        folder.setTotalCount(totalCount.intValue());
        folderRepository.save(folder);
    }
    
    private void updateUserStorage(User user, Long sizeBytes) {
        user.setStorageUsed(user.getStorageUsed() + sizeBytes);
        userService.save(user);
    }
    
    // Additional methods needed by EmailController
    
    public Optional<Email> getEmailById(Long id) {
        return emailRepository.findById(id);
    }
    
    public Page<Email> getEmailsByStatus(Long userId, Email.EmailStatus status, Pageable pageable) {
        return emailRepository.findByUserIdAndStatus(userId, status, pageable);
    }
    
    @Transactional
    public void markAsUnread(Long emailId) {
        emailRepository.findById(emailId).ifPresent(email -> {
            email.setStatus(Email.EmailStatus.UNREAD);
            email.setReadDate(null);
            emailRepository.save(email);
            updateFolderCounts(email.getFolder());
        });
    }
    
    @Transactional
    public void markAsImportant(Long emailId) {
        emailRepository.findById(emailId).ifPresent(email -> {
            email.setIsImportant(!email.getIsImportant());
            emailRepository.save(email);
        });
    }
    
    @Transactional
    public Email sendEmail(Email email, List<MultipartFile> attachments) throws MessagingException {
        // Save email to sent folder
        EmailFolder sentFolder = folderRepository.findByUserIdAndType(
            email.getUser().getId(), 
            EmailFolder.FolderType.SENT
        ).orElseThrow(() -> new BusinessException("Sent folder not found"));
        
        email.setFolder(sentFolder);
        email.setMessageId(generateMessageId());
        email.setSentDate(new Date());
        email.setStatus(Email.EmailStatus.SENT);
        email.setType(Email.EmailType.SENT);
        
        // Save email first
        Email savedEmail = emailRepository.save(email);
        
        // Process attachments if any
        if (attachments != null && !attachments.isEmpty()) {
            savedEmail.setHasAttachments(true);
            // Save attachments to storage
            try {
                attachmentService.saveAttachments(attachments, savedEmail);
                emailRepository.save(savedEmail); // Update with attachment flag
            } catch (IOException e) {
                log.error("Failed to save attachments", e);
                // Continue without attachments - don't fail the entire email
            }
        }
        
        updateFolderCounts(sentFolder);
        
        // Send actual email via mail server
        try {
            mailServerService.sendEmail(
                email.getFromAddress(),
                email.getToAddresses(),
                email.getSubject(),
                email.getContentText(),
                email.getContentHtml() != null
            );
        } catch (Exception e) {
            log.error("Failed to send email via mail server", e);
            throw new MessagingException("Failed to send email", e);
        }
        
        return savedEmail;
    }
    
    @Transactional
    public Email saveDraft(Email draft) {
        EmailFolder draftsFolder = folderRepository.findByUserIdAndType(
            draft.getUser().getId(),
            EmailFolder.FolderType.DRAFTS
        ).orElseThrow(() -> new BusinessException("Drafts folder not found"));
        
        draft.setFolder(draftsFolder);
        draft.setMessageId(generateMessageId());
        draft.setStatus(Email.EmailStatus.DRAFT);
        draft.setType(Email.EmailType.DRAFT);
        
        Email savedDraft = emailRepository.save(draft);
        updateFolderCounts(draftsFolder);
        
        return savedDraft;
    }
    
    public AttachmentDto saveAttachment(MultipartFile file, Long userId) throws IOException {
        // Get user to associate with attachment
        User user = userService.findById(userId)
                .orElseThrow(() -> new BusinessException("User not found"));
        
        // Create temporary email for attachment association
        Email tempEmail = new Email();
        tempEmail.setUser(user);
        
        // Save attachment using AttachmentService
        Attachment attachment = attachmentService.saveAttachment(file, tempEmail);
        
        // Convert to DTO
        return attachmentService.toDto(attachment);
    }
}