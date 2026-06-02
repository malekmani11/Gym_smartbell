package com.gymapp.member.service.impl;

import com.gymapp.member.dto.auth.AuthResponse;
import com.gymapp.member.dto.auth.LoginRequest;
import com.gymapp.member.dto.auth.RefreshTokenRequest;
import com.gymapp.member.dto.auth.RegisterRequest;
import com.gymapp.member.entity.Coach;
import com.gymapp.member.entity.Member;
import com.gymapp.member.entity.RefreshToken;
import com.gymapp.member.entity.Role;
import com.gymapp.member.entity.User;
import com.gymapp.member.entity.enums.Gender;
import com.gymapp.member.entity.enums.MembershipStatus;
import com.gymapp.member.repository.CoachRepository;
import com.gymapp.member.repository.MemberRepository;
import com.gymapp.member.repository.RefreshTokenRepository;
import com.gymapp.member.repository.UserRepository;
import com.gymapp.member.security.CustomUserDetails;
import com.gymapp.member.security.JwtService;
import com.gymapp.member.service.AuthService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final MemberRepository memberRepository;
    private final CoachRepository coachRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;

    @Override
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalStateException("Cet email est déjà utilisé");
        }

        String targetRoleName = (request.getRoleName() != null && !request.getRoleName().isBlank())
                ? request.getRoleName() : "ROLE_MEMBER";

        Role userRole = Role.valueOf(targetRoleName);
        User saved;

        if (userRole == Role.ROLE_MEMBER) {
            Member member = Member.builder()
                    .firstName(request.getFirstName())
                    .lastName(request.getLastName())
                    .email(request.getEmail())
                    .password(passwordEncoder.encode(request.getPassword()))
                    .phone(request.getPhone())
                    .address(request.getAddress())
                    .dateOfBirth(request.getDateOfBirth() != null ? LocalDate.parse(request.getDateOfBirth()) : null)
                    .gender(request.getGender() != null && !request.getGender().isBlank()
                            ? Gender.valueOf(request.getGender()) : null)
                    .role(Role.ROLE_MEMBER)
                    .enabled(true)
                    .emergencyContact(request.getEmergencyContact())
                    .emergencyPhone(request.getEmergencyPhone())
                    .medicalNotes(request.getMedicalNotes())
                    .membershipStatus(MembershipStatus.ACTIVE)
                    .joinDate(LocalDate.now())
                    .build();
            saved = memberRepository.save(member);

        } else if (userRole == Role.ROLE_COACH) {
            // Crée users (discriminator=COACH) + coaches en une seule transaction JPA
            // DB partagée → coach-service lit directement ces mêmes tables
            Coach coach = Coach.builder()
                    .firstName(request.getFirstName())
                    .lastName(request.getLastName())
                    .email(request.getEmail())
                    .password(passwordEncoder.encode(request.getPassword()))
                    .phone(request.getPhone())
                    .address(request.getAddress())
                    .dateOfBirth(request.getDateOfBirth() != null ? LocalDate.parse(request.getDateOfBirth()) : null)
                    .gender(request.getGender() != null && !request.getGender().isBlank()
                            ? Gender.valueOf(request.getGender()) : null)
                    .role(Role.ROLE_COACH)
                    .enabled(true)
                    .specialization(request.getSpecialization())
                    .availabilityStatus("AVAILABLE")
                    .build();
            saved = coachRepository.save(coach);

        } else {
            // ROLE_ADMIN — simple User
            saved = userRepository.save(User.builder()
                    .firstName(request.getFirstName())
                    .lastName(request.getLastName())
                    .email(request.getEmail())
                    .password(passwordEncoder.encode(request.getPassword()))
                    .phone(request.getPhone())
                    .address(request.getAddress())
                    .role(userRole)
                    .enabled(true)
                    .build());
        }

        String jwtToken    = jwtService.generateToken(new CustomUserDetails(saved));
        String refreshToken = jwtService.generateRefreshToken();
        saveRefreshToken(saved, refreshToken, null, null);

        return AuthResponse.builder()
                .token(jwtToken)
                .refreshToken(refreshToken)
                .id(saved.getId())
                .email(saved.getEmail())
                .firstName(saved.getFirstName())
                .lastName(saved.getLastName())
                .role(targetRoleName)
                .expiresIn(jwtService.getJwtExpiration() / 1000)
                .build();
    }

    @Override
    public AuthResponse login(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword()));

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("User not found"));

        String jwtToken    = jwtService.generateToken(new CustomUserDetails(user));
        String refreshToken = jwtService.generateRefreshToken();
        saveRefreshToken(user, refreshToken, null, null);

        return AuthResponse.builder()
                .token(jwtToken)
                .refreshToken(refreshToken)
                .id(user.getId())
                .email(user.getEmail())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .role(user.getRole().name())
                .expiresIn(jwtService.getJwtExpiration() / 1000)
                .build();
    }

    @Override
    @Transactional
    public AuthResponse refreshToken(RefreshTokenRequest request) {
        RefreshToken refreshTokenEntity = refreshTokenRepository.findByToken(request.getRefreshToken())
                .orElseThrow(() -> new IllegalArgumentException("Refresh token invalide"));

        if (!refreshTokenEntity.isValid()) {
            throw new IllegalArgumentException("Refresh token expiré ou révoqué");
        }

        User user = refreshTokenEntity.getUser();
        refreshTokenEntity.setIsRevoked(true);
        refreshTokenRepository.save(refreshTokenEntity);

        String newAccessToken  = jwtService.generateToken(new CustomUserDetails(user));
        String newRefreshToken = jwtService.generateRefreshToken();
        saveRefreshToken(user, newRefreshToken,
                refreshTokenEntity.getDeviceInfo(), refreshTokenEntity.getIpAddress());

        log.info("Token rafraîchi pour l'utilisateur: {}", user.getEmail());

        return AuthResponse.builder()
                .token(newAccessToken)
                .refreshToken(newRefreshToken)
                .id(user.getId())
                .email(user.getEmail())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .role(user.getRole().name())
                .expiresIn(jwtService.getJwtExpiration() / 1000)
                .build();
    }

    @Override
    @Transactional
    public void logout(String refreshToken) {
        if (refreshToken != null && !refreshToken.isBlank()) {
            refreshTokenRepository.findByToken(refreshToken).ifPresent(token -> {
                token.setIsRevoked(true);
                refreshTokenRepository.save(token);
                log.info("Refresh token révoqué pour: {}", token.getUser().getEmail());
            });
        }
    }

    @Override
    @Transactional
    public void revokeAllUserTokens(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Utilisateur non trouvé"));
        int count = refreshTokenRepository.revokeAllByUser(user);
        log.info("{} refresh tokens révoqués pour: {}", count, user.getEmail());
    }

    private void saveRefreshToken(User user, String token, String deviceInfo, String ipAddress) {
        RefreshToken rt = RefreshToken.builder()
                .token(token)
                .user(user)
                .expiresAt(LocalDateTime.now().plus(
                        jwtService.getRefreshTokenExpiration(),
                        java.time.temporal.ChronoUnit.MILLIS))
                .isRevoked(false)
                .deviceInfo(deviceInfo)
                .ipAddress(ipAddress)
                .build();
        refreshTokenRepository.save(rt);
        cleanupOldTokens(user);
    }

    private void cleanupOldTokens(User user) {
        List<RefreshToken> valid = refreshTokenRepository
                .findByUserAndIsRevokedFalseAndExpiresAtAfter(user, LocalDateTime.now());
        if (valid.size() > 5) {
            valid.sort((a, b) -> b.getCreatedAt().compareTo(a.getCreatedAt()));
            for (int i = 5; i < valid.size(); i++) {
                valid.get(i).setIsRevoked(true);
                refreshTokenRepository.save(valid.get(i));
            }
        }
    }
}
