package com.enterprise.mail.service;

import com.enterprise.mail.entity.Email;
import com.enterprise.mail.entity.EmailAlias;
import com.enterprise.mail.entity.EmailFolder;
import com.enterprise.mail.entity.User;
import com.enterprise.mail.repository.EmailRepository;
import com.enterprise.mail.repository.EmailAliasRepository;
import com.enterprise.mail.repository.EmailFolderRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.mail.Address;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;
import java.io.IOException;
import java.util.Date;
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
            InternetAddress addr = (InternetAddress) addresses[0];
            return addr.getPersonal() != null ? addr.getPersonal() : addr.getAddress();
        }
        return "";
    }
    
    private String getTextContent(MimeMessage message) throws MessagingException, IOException {
        // Simplified implementation - should handle multipart messages
        Object content = message.getContent();
        if (content instanceof String) {
            return (String) content;
        }
        return "";
    }
    
    private String getHtmlContent(MimeMessage message) throws MessagingException, IOException {
        // Simplified implementation - should handle multipart messages
        return "";
    }
    
    private String getRawContent(MimeMessage message) throws MessagingException, IOException {
        // Convert message to raw string
        return message.toString();
    }
    
    private boolean hasAttachments(MimeMessage message) throws MessagingException {
        // Check if message has attachments
        return false; // Simplified
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
        folder.setTotalCount((int) emailRepository.count());
        folderRepository.save(folder);
    }
    
    private void updateUserStorage(User user, Long sizeBytes) {
        user.setStorageUsed(user.getStorageUsed() + sizeBytes);
        userService.save(user);
    }
}