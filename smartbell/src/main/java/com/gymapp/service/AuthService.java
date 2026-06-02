package com.gymapp.service;

import com.gymapp.dto.auth.AuthResponse;
import com.gymapp.dto.auth.ForgotPasswordRequest;
import com.gymapp.dto.auth.LoginRequest;
import com.gymapp.dto.auth.RefreshTokenRequest;
import com.gymapp.dto.auth.RegisterRequest;
import com.gymapp.dto.auth.ResetPasswordRequest;

public interface AuthService {
    AuthResponse register(RegisterRequest request);

    AuthResponse login(LoginRequest request);

    AuthResponse refreshToken(RefreshTokenRequest request);

    void logout(String refreshToken);

    void revokeAllUserTokens(Long userId);

    void forgotPassword(ForgotPasswordRequest request);

    void resetPassword(ResetPasswordRequest request);
}
