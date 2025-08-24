package com.enterprise.mail.service;

import com.enterprise.mail.config.MailServerConfig;
import com.icegreen.greenmail.util.GreenMail;
import com.icegreen.greenmail.util.ServerSetup;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import jakarta.mail.*;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.Properties;

/**
 * Mail Server Service using GreenMail for embedded mail server
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MailServerService {
    
    private final MailServerConfig mailServerConfig;
    private final EmailService emailService;
    private GreenMail greenMail;
    
    @PostConstruct
    public void startServer() {
        if (!mailServerConfig.getSmtp().isEnabled()) {
            log.info("Mail Server is disabled");
            return;
        }
        
        try {
            // Configure server setups for different protocols
            ServerSetup smtp = new ServerSetup(
                mailServerConfig.getSmtp().getPort(), 
                "0.0.0.0", 
                ServerSetup.PROTOCOL_SMTP
            );
            
            ServerSetup smtps = new ServerSetup(
                mailServerConfig.getSmtp().getSslPort(), 
                "0.0.0.0", 
                ServerSetup.PROTOCOL_SMTPS
            );
            
            ServerSetup imap = new ServerSetup(
                mailServerConfig.getImap().getPort(), 
                "0.0.0.0", 
                ServerSetup.PROTOCOL_IMAP
            );
            
            ServerSetup imaps = new ServerSetup(
                mailServerConfig.getImap().getSslPort(), 
                "0.0.0.0", 
                ServerSetup.PROTOCOL_IMAPS
            );
            
            ServerSetup pop3 = new ServerSetup(
                mailServerConfig.getPop3().getPort(), 
                "0.0.0.0", 
                ServerSetup.PROTOCOL_POP3
            );
            
            ServerSetup pop3s = new ServerSetup(
                mailServerConfig.getPop3().getSslPort(), 
                "0.0.0.0", 
                ServerSetup.PROTOCOL_POP3S
            );
            
            // Create and start GreenMail server
            greenMail = new GreenMail(new ServerSetup[]{smtp, smtps, imap, imaps, pop3, pop3s});
            greenMail.start();
            
            log.info("Mail Server started successfully");
            log.info("SMTP: {}, SMTPS: {}", smtp.getPort(), smtps.getPort());
            log.info("IMAP: {}, IMAPS: {}", imap.getPort(), imaps.getPort());
            log.info("POP3: {}, POP3S: {}", pop3.getPort(), pop3s.getPort());
            
        } catch (Exception e) {
            log.error("Failed to start Mail Server", e);
        }
    }
    
    @PreDestroy
    public void stopServer() {
        if (greenMail != null) {
            greenMail.stop();
            log.info("Mail Server stopped");
        }
    }
    
    /**
     * Send email using SMTP
     */
    public void sendEmail(String from, String to, String subject, String body, boolean isHtml) throws MessagingException {
        Properties props = new Properties();
        props.put("mail.smtp.host", "localhost");
        props.put("mail.smtp.port", mailServerConfig.getSmtp().getPort());
        props.put("mail.smtp.auth", "false");
        props.put("mail.smtp.starttls.enable", "false");
        
        Session session = Session.getInstance(props);
        
        MimeMessage message = new MimeMessage(session);
        message.setFrom(new InternetAddress(from));
        message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to));
        message.setSubject(subject);
        
        if (isHtml) {
            message.setContent(body, "text/html; charset=UTF-8");
        } else {
            message.setText(body);
        }
        
        Transport.send(message);
        
        // Save sent email
        emailService.saveSentEmail(from, to, message);
        
        log.info("Email sent successfully from {} to {}", from, to);
    }
    
    /**
     * Receive emails from the server
     */
    public MimeMessage[] receiveEmails(String username, String password) {
        if (greenMail != null) {
            return greenMail.getReceivedMessages();
        }
        return new MimeMessage[0];
    }
    
    /**
     * Create a user account on the mail server
     */
    public void createUser(String email, String password) {
        if (greenMail != null) {
            greenMail.setUser(email, password);
            log.info("Created mail user: {}", email);
        }
    }
    
    /**
     * Check if the mail server is running
     */
    public boolean isRunning() {
        return greenMail != null;
    }
}