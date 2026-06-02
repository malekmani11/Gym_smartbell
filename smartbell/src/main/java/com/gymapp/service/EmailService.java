package com.gymapp.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${app.email.from}")
    private String from;

    @Value("${app.email.gym-name}")
    private String gymName;

    @Async
    public void sendWelcomeEmail(String toEmail, String firstName) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(from != null ? from : "noreply@smartbell.com");
            helper.setTo(toEmail != null ? toEmail : "");
            helper.setSubject("Bienvenue chez " + gymName + " ! 🎉");
            helper.setText(buildWelcomeHtml(firstName != null ? firstName : ""), true);

            mailSender.send(message);
            log.info("Email de bienvenue envoyé à {}", toEmail);

        } catch (MessagingException e) {
            log.error("Échec de l'envoi de l'email de bienvenue à {} : {}", toEmail, e.getMessage());
        }
    }

    @Async
    public void sendPasswordResetEmail(String toEmail, String firstName, String token) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(from != null ? from : "noreply@smartbell.com");
            helper.setTo(toEmail != null ? toEmail : "");
            helper.setSubject("Réinitialisation de votre mot de passe — " + gymName);
            helper.setText(buildResetHtml(firstName != null ? firstName : "", token), true);

            mailSender.send(message);
            log.info("Email de réinitialisation envoyé à {}", toEmail);

        } catch (MessagingException e) {
            log.error("Échec de l'envoi de l'email de réinitialisation à {} : {}", toEmail, e.getMessage());
        }
    }

    private String buildResetHtml(String firstName, String token) {
        return """
            <html>
            <body style="font-family: Arial, sans-serif; background-color: #111111; color: #ffffff; padding: 40px;">
              <div style="max-width: 600px; margin: auto; background-color: #1e1e1e; border-radius: 12px; padding: 40px;">

                <div style="text-align: center; margin-bottom: 30px;">
                  <h1 style="color: #EF9F27; font-size: 28px; margin: 0;">💪 SmartBell Gym</h1>
                </div>

                <h2 style="color: #ffffff; font-size: 20px;">Bonjour %s,</h2>

                <p style="color: #cccccc; font-size: 15px; line-height: 1.7;">
                  Tu as demandé la réinitialisation de ton mot de passe.
                  Voici ton code de réinitialisation (valable <strong style="color: #EF9F27;">15 minutes</strong>) :
                </p>

                <div style="text-align: center; margin: 30px 0;">
                  <div style="display: inline-block; background-color: #2a2a2a; border: 2px solid #EF9F27;
                              border-radius: 10px; padding: 16px 32px;">
                    <span style="color: #EF9F27; font-size: 28px; font-weight: bold; letter-spacing: 4px;">%s</span>
                  </div>
                </div>

                <p style="color: #888888; font-size: 13px; line-height: 1.7;">
                  Si tu n'as pas demandé cette réinitialisation, ignore cet email. Ton mot de passe reste inchangé.
                </p>

                <hr style="border: 1px solid #2a2a2a; margin-top: 30px;" />
                <p style="color: #555555; font-size: 12px; text-align: center;">
                  © %s — Tous droits réservés
                </p>
              </div>
            </body>
            </html>
            """.formatted(firstName, token, gymName);
    }

    private String buildWelcomeHtml(String firstName) {
        return """
            <html>
            <body style="font-family: Arial, sans-serif; background-color: #111111; color: #ffffff; padding: 40px;">
              <div style="max-width: 600px; margin: auto; background-color: #1e1e1e; border-radius: 12px; padding: 40px;">

                <div style="text-align: center; margin-bottom: 30px;">
                  <h1 style="color: #EF9F27; font-size: 28px; margin: 0;">💪 SmartBell Gym</h1>
                </div>

                <h2 style="color: #ffffff; font-size: 22px;">Bienvenue, %s !</h2>

                <p style="color: #cccccc; font-size: 15px; line-height: 1.7;">
                  Ton compte a été créé avec succès. Tu fais maintenant partie de la communauté <strong style="color: #EF9F27;">%s</strong>.
                </p>

                <p style="color: #cccccc; font-size: 15px; line-height: 1.7;">
                  Avec l'application SmartBell, tu peux :
                </p>
                <ul style="color: #cccccc; font-size: 15px; line-height: 2;">
                  <li>🏋️ Générer ton programme sportif personnalisé par IA</li>
                  <li>📅 Réserver tes cours et séances</li>
                  <li>💳 Suivre ton abonnement et tes paiements</li>
                  <li>📊 Suivre ta progression et tes performances</li>
                </ul>

                <div style="text-align: center; margin-top: 35px;">
                  <p style="color: #888888; font-size: 13px;">
                    Si tu n'es pas à l'origine de cette inscription, ignore cet email.
                  </p>
                </div>

                <hr style="border: 1px solid #2a2a2a; margin-top: 30px;" />
                <p style="color: #555555; font-size: 12px; text-align: center;">
                  © %s — Tous droits réservés
                </p>
              </div>
            </body>
            </html>
            """.formatted(firstName, gymName, gymName);
    }
}
