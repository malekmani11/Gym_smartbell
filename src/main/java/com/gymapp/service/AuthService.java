package com.gymapp.service;

import com.gymapp.dto.auth.AuthResponse;
import com.gymapp.dto.auth.LoginRequest;
import com.gymapp.dto.auth.RegisterRequest;

public interface AuthService {
    AuthResponse register(RegisterRequest request);

    AuthResponse login(LoginRequest request);
}
