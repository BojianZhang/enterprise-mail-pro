package com.enterprise.mail.service;

import com.enterprise.mail.config.MailServerConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.subethamail.smtp.helper.SimpleMessageListener;
import org.subethamail.smtp.server.SMTPServer;

import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;
import javax.mail.*;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

/**
 * SMTP Server Service for receiving and sending emails
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SMTPServerService implements SimpleMessageListener {
    
    private final MailServerConfig mailServerConfig;
    private final EmailService emailService;
    private final UserService userService;
    private SMTPServer smtpServer;
    
    @PostConstruct
    public void startServer() {
        if (!mailServerConfig.getSmtp().isEnabled()) {
            log.info("SMTP Server is disabled");
            return;
        }
        
        try {
            smtpServer = SMTPServer.port(mailServerConfig.getSmtp().getPort())
                    .maxConnections(mailServerConfig.getSmtp().getMaxConnections())
                    .requireAuth(mailServerConfig.getSmtp().isAuthRequired())
                    .simpleMessageListener(this)
                    .build();
            
            smtpServer.start();
            log.info("SMTP Server started on port {}", mailServerConfig.getSmtp().getPort());
        } catch (Exception e) {
            log.error("Failed to start SMTP server", e);
        }
    }
    
    @PreDestroy
    public void stopServer() {
        if (smtpServer != null && smtpServer.isRunning()) {
            smtpServer.stop();
            log.info("SMTP Server stopped");
        }
    }
    
    @Override
    public boolean accept(String from, String recipient) {
        log.debug("Accepting email from {} to {}", from, recipient);
        // Check if recipient domain is allowed
        String domain = recipient.substring(recipient.indexOf("@") + 1);
        return mailServerConfig.getDomain().getAllowedDomains().contains(domain);
    }
    
    @Override
    public void deliver(String from, String recipient, InputStream data) throws IOException {
        log.info("Delivering email from {} to {}", from, recipient);
        
        try {
            // Parse the email
            Properties props = new Properties();
            Session session = Session.getDefaultInstance(props);
            MimeMessage message = new MimeMessage(session, data);
            
            // Save email to database
            emailService.saveReceivedEmail(from, recipient, message);
            
            log.info("Email delivered successfully from {} to {}", from, recipient);
        } catch (MessagingException e) {
            log.error("Failed to process email from {} to {}", from, recipient, e);
            throw new IOException("Failed to process email", e);
        }
    }
    
    /**
     * Send email using SMTP
     */
    public void sendEmail(String from, String to, String subject, String body, boolean isHtml) throws MessagingException {
        Properties props = new Properties();
        props.put("mail.smtp.host", mailServerConfig.getMail().getHost());
        props.put("mail.smtp.port", mailServerConfig.getMail().getPort());
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        
        Session session = Session.getInstance(props, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(
                    mailServerConfig.getMail().getUsername(),
                    mailServerConfig.getMail().getPassword()
                );
            }
        });
        
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
     * Get raw email content
     */
    private String getRawContent(MimeMessage message) throws MessagingException, IOException {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        message.writeTo(baos);
        return baos.toString("UTF-8");
    }
}