package com.gymapp.service.impl;

import com.gymapp.dto.auth.AuthResponse;
import com.gymapp.dto.auth.LoginRequest;
import com.gymapp.dto.auth.RefreshTokenRequest;
import com.gymapp.dto.auth.RegisterRequest;
import com.gymapp.entity.Coach;
import com.gymapp.entity.Member;
import com.gymapp.entity.RefreshToken;
import com.gymapp.entity.Role;
import com.gymapp.entity.User;
import com.gymapp.entity.enums.AvailabilityStatus;
import com.gymapp.entity.enums.Gender;
import com.gymapp.entity.enums.MembershipStatus;
import com.gymapp.repository.CoachRepository;
import com.gymapp.repository.MemberRepository;
import com.gymapp.repository.RefreshTokenRepository;
import com.gymapp.repository.UserRepository;
import com.gymapp.security.CustomUserDetails;
import com.gymapp.security.JwtService;
import com.gymapp.service.AuthService;
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

        String targetRoleName = request.getRoleName() != null && !request.getRoleName().isBlank()
                ? request.getRoleName()
                : "ROLE_MEMBER";

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
                    .gender(request.getGender() != null && !request.getGender().isBlank() ? Gender.valueOf(request.getGender()) : null)
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
            String specialization = (request.getSpecialization() != null && !request.getSpecialization().isBlank())
                    ? request.getSpecialization()
                    : null;
            Coach coach = Coach.builder()
                    .firstName(request.getFirstName())
                    .lastName(request.getLastName())
                    .email(request.getEmail())
                    .password(passwordEncoder.encode(request.getPassword()))
                    .phone(request.getPhone())
                    .address(request.getAddress())
                    .dateOfBirth(request.getDateOfBirth() != null ? LocalDate.parse(request.getDateOfBirth()) : null)
                    .gender(request.getGender() != null && !request.getGender().isBlank() ? Gender.valueOf(request.getGender()) : null)
                    .role(Role.ROLE_COACH)
                    .enabled(true)
                    .specialization(specialization)
                    .hireDate(LocalDate.now())
                    .availabilityStatus(AvailabilityStatus.AVAILABLE)
                    .build();
            saved = coachRepository.save(coach);

        } else {
            saved = userRepository.save(User.builder()
                    .firstName(request.getFirstName())
                    .lastName(request.getLastName())
                    .email(request.getEmail())
                    .password(passwordEncoder.encode(request.getPassword()))
                    .phone(request.getPhone())
                    .role(userRole)
                    .enabled(true)
                    .build());
        }

        var jwtToken = jwtService.generateToken(new CustomUserDetails(saved));
        
        // Générer et sauvegarder le refresh token
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
                new UsernamePasswordAuthenticationToken(
                        request.getEmail(),
                        request.getPassword()));

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("User not found"));

        var jwtToken = jwtService.generateToken(new CustomUserDetails(user));

        // Générer et sauvegarder le refresh token
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
        // Chercher le refresh token en base
        RefreshToken refreshTokenEntity = refreshTokenRepository.findByToken(request.getRefreshToken())
                .orElseThrow(() -> new IllegalArgumentException("Refresh token invalide"));

        // Vérifier si le token est valide
        if (!refreshTokenEntity.isValid()) {
            throw new IllegalArgumentException("Refresh token expiré ou révoqué");
        }

        User user = refreshTokenEntity.getUser();
        
        // Rotation du token : révoquer l'ancien et créer un nouveau
        refreshTokenEntity.setIsRevoked(true);
        refreshTokenRepository.save(refreshTokenEntity);

        // Générer nouveaux tokens
        String newAccessToken = jwtService.generateToken(new CustomUserDetails(user));
        String newRefreshToken = jwtService.generateRefreshToken();
        
        // Sauvegarder le nouveau refresh token
        saveRefreshToken(user, newRefreshToken, 
                refreshTokenEntity.getDeviceInfo(), 
                refreshTokenEntity.getIpAddress());

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
            refreshTokenRepository.findByToken(refreshToken)
                    .ifPresent(token -> {
                        token.setIsRevoked(true);
                        refreshTokenRepository.save(token);
                        log.info("Refresh token révoqué pour l'utilisateur: {}", token.getUser().getEmail());
                    });
        }
    }

    @Override
    @Transactional
    public void revokeAllUserTokens(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Utilisateur non trouvé"));
        
        int revokedCount = refreshTokenRepository.revokeAllByUser(user);
        log.info("{} refresh tokens révoqués pour l'utilisateur: {}", revokedCount, user.getEmail());
    }

    /**
     * Sauvegarde un refresh token en base
     */
    private void saveRefreshToken(User user, String token, String deviceInfo, String ipAddress) {
        RefreshToken refreshToken = RefreshToken.builder()
                .token(token)
                .user(user)
                .expiresAt(LocalDateTime.now().plus(jwtService.getRefreshTokenExpiration(), java.time.temporal.ChronoUnit.MILLIS))
                .isRevoked(false)
                .deviceInfo(deviceInfo)
                .ipAddress(ipAddress)
                .build();
        
        refreshTokenRepository.save(refreshToken);
        
        // Nettoyer les tokens expirés (garder max 5 tokens par utilisateur)
        cleanupOldTokens(user);
    }

    /**
     * Nettoie les anciens tokens, garde seulement les 5 plus récents
     */
    private void cleanupOldTokens(User user) {
        List<RefreshToken> validTokens = refreshTokenRepository
                .findByUserAndIsRevokedFalseAndExpiresAtAfter(user, LocalDateTime.now());
        
        if (validTokens.size() > 5) {
            // Trier par date de création décroissante
            validTokens.sort((a, b) -> b.getCreatedAt().compareTo(a.getCreatedAt()));
            
            // Révoquer les plus anciens
            for (int i = 5; i < validTokens.size(); i++) {
                validTokens.get(i).setIsRevoked(true);
                refreshTokenRepository.save(validTokens.get(i));
            }
        }
    }
}
