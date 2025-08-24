package com.enterprise.mail.repository;

import com.enterprise.mail.entity.Email;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Date;
import java.util.List;
import java.util.Optional;

@Repository
public interface EmailRepository extends JpaRepository<Email, Long> {
    
    Optional<Email> findByMessageId(String messageId);
    
    Page<Email> findByUserId(Long userId, Pageable pageable);
    
    Page<Email> findByUserIdAndFolderId(Long userId, Long folderId, Pageable pageable);
    
    Page<Email> findByAliasId(Long aliasId, Pageable pageable);
    
    @Query("SELECT e FROM Email e WHERE e.user.id = :userId AND e.status = :status")
    Page<Email> findByUserIdAndStatus(@Param("userId") Long userId, @Param("status") Email.EmailStatus status, Pageable pageable);
    
    @Query("SELECT e FROM Email e WHERE e.user.id = :userId AND e.isStarred = true")
    Page<Email> findStarredEmails(@Param("userId") Long userId, Pageable pageable);
    
    @Query("SELECT e FROM Email e WHERE e.user.id = :userId AND e.isImportant = true")
    Page<Email> findImportantEmails(@Param("userId") Long userId, Pageable pageable);
    
    @Query("SELECT e FROM Email e WHERE e.user.id = :userId AND (e.subject LIKE %:searchTerm% OR e.contentText LIKE %:searchTerm% OR e.fromAddress LIKE %:searchTerm%)")
    Page<Email> searchEmails(@Param("userId") Long userId, @Param("searchTerm") String searchTerm, Pageable pageable);
    
    @Query("SELECT e FROM Email e WHERE e.user.id = :userId AND e.sentDate BETWEEN :startDate AND :endDate")
    List<Email> findEmailsByDateRange(@Param("userId") Long userId, @Param("startDate") Date startDate, @Param("endDate") Date endDate);
    
    @Query("SELECT COUNT(e) FROM Email e WHERE e.user.id = :userId AND e.status = 'UNREAD'")
    Long countUnreadEmails(@Param("userId") Long userId);
    
    @Query("SELECT COUNT(e) FROM Email e WHERE e.folder.id = :folderId AND e.status = 'UNREAD'")
    Long countUnreadEmailsInFolder(@Param("folderId") Long folderId);
    
    @Query("SELECT SUM(e.sizeBytes) FROM Email e WHERE e.user.id = :userId")
    Long calculateTotalStorageUsed(@Param("userId") Long userId);
}