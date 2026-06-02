package com.gymapp.member.service;

import com.gymapp.member.dto.auth.AuthResponse;
import com.gymapp.member.dto.auth.LoginRequest;
import com.gymapp.member.dto.auth.RefreshTokenRequest;
import com.gymapp.member.dto.auth.RegisterRequest;

public interface AuthService {
    AuthResponse register(RegisterRequest request);

    AuthResponse login(LoginRequest request);

    AuthResponse refreshToken(RefreshTokenRequest request);

    void logout(String refreshToken);

    void revokeAllUserTokens(Long userId);
}
