package com.enterprise.mail.service;

import com.enterprise.mail.entity.EmailFolder;
import com.enterprise.mail.entity.User;
import com.enterprise.mail.repository.EmailFolderRepository;
import com.enterprise.mail.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;
import java.util.Optional;

/**
 * User Service
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class UserService implements UserDetailsService {
    
    private final UserRepository userRepository;
    private final EmailFolderRepository folderRepository;
    private final PasswordEncoder passwordEncoder;
    
    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        return userRepository.findByUsernameOrEmail(username, username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));
    }
    
    /**
     * Register new user
     */
    public User registerUser(String username, String email, String password, String firstName, String lastName) {
        // Check if user already exists
        if (userRepository.existsByUsername(username)) {
            throw new IllegalArgumentException("Username already exists");
        }
        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("Email already exists");
        }
        
        // Create new user
        User user = new User();
        user.setUsername(username);
        user.setEmail(email);
        user.setPassword(passwordEncoder.encode(password));
        user.setFirstName(firstName);
        user.setLastName(lastName);
        user.setRole(User.UserRole.USER);
        user.setStatus(User.UserStatus.ACTIVE);
        user.setEmailVerified(false);
        
        // Save user
        user = userRepository.save(user);
        
        // Create default folders for user
        createDefaultFolders(user);
        
        log.info("New user registered: {}", username);
        
        return user;
    }
    
    /**
     * Create default folders for user
     */
    private void createDefaultFolders(User user) {
        List<EmailFolder.FolderType> defaultFolders = List.of(
                EmailFolder.FolderType.INBOX,
                EmailFolder.FolderType.SENT,
                EmailFolder.FolderType.DRAFTS,
                EmailFolder.FolderType.TRASH,
                EmailFolder.FolderType.SPAM,
                EmailFolder.FolderType.ARCHIVE
        );
        
        int sortOrder = 0;
        for (EmailFolder.FolderType type : defaultFolders) {
            EmailFolder folder = new EmailFolder();
            folder.setName(capitalize(type.name()));
            folder.setType(type);
            folder.setIsSystem(true);
            folder.setSortOrder(sortOrder++);
            folder.setUser(user);
            folder.setUnreadCount(0);
            folder.setTotalCount(0);
            
            // Set icons
            switch (type) {
                case INBOX -> folder.setIcon("inbox");
                case SENT -> folder.setIcon("send");
                case DRAFTS -> folder.setIcon("drafts");
                case TRASH -> folder.setIcon("delete");
                case SPAM -> folder.setIcon("report");
                case ARCHIVE -> folder.setIcon("archive");
            }
            
            folderRepository.save(folder);
        }
    }
    
    /**
     * Update user profile
     */
    public User updateProfile(Long userId, String firstName, String lastName, String phoneNumber) {
        User user = findById(userId);
        user.setFirstName(firstName);
        user.setLastName(lastName);
        user.setPhoneNumber(phoneNumber);
        return userRepository.save(user);
    }
    
    /**
     * Change user password
     */
    public void changePassword(Long userId, String oldPassword, String newPassword) {
        User user = findById(userId);
        
        if (!passwordEncoder.matches(oldPassword, user.getPassword())) {
            throw new IllegalArgumentException("Invalid old password");
        }
        
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
        
        log.info("Password changed for user: {}", user.getUsername());
    }
    
    /**
     * Update last login
     */
    public void updateLastLogin(Long userId, String ipAddress) {
        User user = findById(userId);
        user.setLastLoginAt(new Date());
        user.setLastLoginIp(ipAddress);
        userRepository.save(user);
    }
    
    /**
     * Find user by ID
     */
    public User findById(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
    }
    
    /**
     * Find user by username
     */
    public Optional<User> findByUsername(String username) {
        return userRepository.findByUsername(username);
    }
    
    /**
     * Find user by email
     */
    public Optional<User> findByEmail(String email) {
        return userRepository.findByEmail(email);
    }
    
    /**
     * Save user
     */
    public User save(User user) {
        return userRepository.save(user);
    }
    
    /**
     * Get all users
     */
    public List<User> getAllUsers() {
        return userRepository.findAll();
    }
    
    /**
     * Delete user
     */
    public void deleteUser(Long userId) {
        User user = findById(userId);
        user.setIsDeleted(true);
        user.setStatus(User.UserStatus.INACTIVE);
        userRepository.save(user);
    }
    
    /**
     * Enable/disable user
     */
    public void setUserStatus(Long userId, User.UserStatus status) {
        User user = findById(userId);
        user.setStatus(status);
        userRepository.save(user);
    }
    
    /**
     * Verify email
     */
    public void verifyEmail(Long userId) {
        User user = findById(userId);
        user.setEmailVerified(true);
        userRepository.save(user);
    }
    
    /**
     * Helper method to capitalize string
     */
    private String capitalize(String str) {
        if (str == null || str.isEmpty()) {
            return str;
        }
        return str.substring(0, 1).toUpperCase() + str.substring(1).toLowerCase();
    }
}