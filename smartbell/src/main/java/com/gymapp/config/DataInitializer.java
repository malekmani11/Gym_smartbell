package com.gymapp.config;

import com.gymapp.entity.Role;
import com.gymapp.entity.User;
import com.gymapp.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataInitializer implements ApplicationRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    private static final String ADMIN_EMAIL    = "admin@gmail.com";
    private static final String ADMIN_PASSWORD = "mouka123";

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        userRepository.findByEmail(ADMIN_EMAIL).ifPresentOrElse(
            user -> {
                if (!isAlreadyBcrypt(user.getPassword())) {
                    user.setPassword(passwordEncoder.encode(ADMIN_PASSWORD));
                    userRepository.save(user);
                    log.info("Admin password re-encoded to BCrypt: {}", ADMIN_EMAIL);
                }
            },
            () -> {
                User admin = User.builder()
                        .firstName("Admin")
                        .lastName("SmartBell")
                        .email(ADMIN_EMAIL)
                        .password(passwordEncoder.encode(ADMIN_PASSWORD))
                        .role(Role.ROLE_ADMIN)
                        .enabled(true)
                        .build();
                userRepository.save(admin);
                log.info("Admin account created: {}", ADMIN_EMAIL);
            }
        );
    }

    private boolean isAlreadyBcrypt(String password) {
        return password != null &&
               (password.startsWith("$2a$") || password.startsWith("$2b$") || password.startsWith("$2y$"));
    }
}
