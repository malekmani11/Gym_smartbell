package com.gymapp.config;

import com.gymapp.security.JwtAuthenticationFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.HttpStatusEntryPoint;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfigurationSource;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthFilter;
    private final AuthenticationProvider authenticationProvider;
    private final CorsConfigurationSource corsConfigurationSource; // ← ajouter

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .cors(cors -> cors.configurationSource(corsConfigurationSource)) // ← remplacer disable
                .authorizeHttpRequests(req -> req
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                        .requestMatchers(
                                "/api/auth/**",
                                "/api-docs/**",
                                "/api-docs.yaml",
                                "/v3/api-docs/**",
                                "/v3/api-docs.yaml",
                                "/swagger-ui/**",
                                "/swagger-ui.html")
                        .permitAll()
                        // Member self-service endpoints
                        .requestMatchers("/api/members/user/**").hasAnyRole("ADMIN", "MEMBER")
                        .requestMatchers("/api/subscriptions/user/**").hasAnyRole("ADMIN", "MEMBER")
                        .requestMatchers("/api/checkins/member/**").hasAnyRole("ADMIN", "MEMBER")
                        .requestMatchers("/api/training/**").hasAnyRole("ADMIN", "COACH", "MEMBER")
                        .requestMatchers("/api/nutrition-plans/**").hasAnyRole("ADMIN", "COACH", "MEMBER")
                        .requestMatchers(HttpMethod.GET, "/api/courses/**").hasAnyRole("ADMIN", "COACH", "MEMBER")
                        .requestMatchers(HttpMethod.GET, "/api/coaches/**").hasAnyRole("ADMIN", "COACH", "MEMBER")
                        .requestMatchers("/api/notifications/user/**").hasAnyRole("ADMIN", "MEMBER")
                        .requestMatchers("/api/messages/**").hasAnyRole("ADMIN", "COACH", "MEMBER")
                        // Admin-only endpoints
                        .requestMatchers("/api/members/**").hasRole("ADMIN")
                        .requestMatchers("/api/coaches/**").hasRole("ADMIN")
                        .requestMatchers("/api/subscriptions/**").hasRole("ADMIN")
                        .requestMatchers("/api/payments/**").hasRole("ADMIN")
                        .requestMatchers("/api/dashboard/**").hasRole("ADMIN")
                        .requestMatchers("/api/rooms/**").hasRole("ADMIN")
                        .requestMatchers("/api/events/**").hasRole("ADMIN")
                        .requestMatchers("/api/machines/**").hasRole("ADMIN")
                        .requestMatchers("/api/notifications/**").hasRole("ADMIN")
                        .requestMatchers("/api/complaints/**").hasRole("ADMIN")
                        .requestMatchers("/api/reports/**").hasRole("ADMIN")
                        .requestMatchers("/api/ai/**").hasAnyRole("ADMIN", "COACH", "MEMBER")
                        .anyRequest()
                        .authenticated())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint(new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED)))
                .authenticationProvider(authenticationProvider)
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}