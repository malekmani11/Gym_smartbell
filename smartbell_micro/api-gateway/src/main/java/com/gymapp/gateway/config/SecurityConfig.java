package com.gymapp.gateway.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.NimbusReactiveJwtDecoder;
import org.springframework.security.oauth2.jwt.ReactiveJwtDecoder;
import org.springframework.security.oauth2.server.resource.authentication.ReactiveJwtAuthenticationConverter;
import org.springframework.security.web.server.SecurityWebFilterChain;
import reactor.core.publisher.Flux;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.util.Base64;

@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    @Value("${application.security.jwt.secret-key}")
    private String jwtSecretKey;

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        return http
            .csrf(ServerHttpSecurity.CsrfSpec::disable)
            .authorizeExchange(ex -> ex
                // ── Public — pas de JWT requis ──────────────────────────────
                .pathMatchers(
                    "/api/auth/login",
                    "/api/auth/register",
                    "/api/auth/refresh",
                    "/api/auth/**"
                ).permitAll()
                .pathMatchers("/actuator/**").permitAll()
                .pathMatchers("/*/v3/api-docs/**", "/*/swagger-ui/**", "/swagger-ui.html").permitAll()
                // ── Accès par rôle ───────────────────────────────────────────
                .pathMatchers("/api/members/**", "/api/subscriptions/**", "/api/loyalty/**")
                    .hasAnyAuthority("ROLE_ADMIN", "ROLE_MEMBER")
                .pathMatchers("/api/coaches/**", "/api/courses/**", "/api/exercises/**", "/api/training/**")
                    .hasAnyAuthority("ROLE_ADMIN", "ROLE_COACH", "ROLE_MEMBER")
                .pathMatchers("/api/payments/**", "/api/plans/**")
                    .hasAnyAuthority("ROLE_ADMIN")
                .pathMatchers("/api/nutrition-plans/**", "/api/meals/**")
                    .hasAnyAuthority("ROLE_ADMIN", "ROLE_COACH", "ROLE_MEMBER")
                .pathMatchers("/api/complaints/**")
                    .hasAnyAuthority("ROLE_ADMIN", "ROLE_MEMBER")
                .pathMatchers("/api/events/**")
                    .hasAnyAuthority("ROLE_ADMIN", "ROLE_MEMBER")
                .pathMatchers("/api/notifications/**", "/api/messages/**")
                    .hasAnyAuthority("ROLE_ADMIN", "ROLE_MEMBER")
                .pathMatchers("/api/machines/**", "/api/salles/**")
                    .hasAnyAuthority("ROLE_ADMIN")
                .anyExchange().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt
                    .jwtDecoder(jwtDecoder())
                    .jwtAuthenticationConverter(jwtAuthenticationConverter())
                )
            )
            .build();
    }

    /**
     * Décode les JWT HS256 signés par member-service.
     * Utilise la même clé secrète (Base64) que member-service.
     */
    @Bean
    public ReactiveJwtDecoder jwtDecoder() {
        byte[] keyBytes = Base64.getDecoder().decode(jwtSecretKey);
        SecretKey key = new SecretKeySpec(keyBytes, "HmacSHA256");
        return NimbusReactiveJwtDecoder.withSecretKey(key).build();
    }

    /**
     * Extrait le claim "role" (ex : "ROLE_ADMIN") produit par member-service
     * et le convertit en GrantedAuthority Spring Security.
     */
    @Bean
    public ReactiveJwtAuthenticationConverter jwtAuthenticationConverter() {
        ReactiveJwtAuthenticationConverter converter = new ReactiveJwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(jwt -> {
            String role = jwt.getClaimAsString("role");
            if (role == null || role.isBlank()) return Flux.empty();
            return Flux.just(new SimpleGrantedAuthority(role));
        });
        return converter;
    }
}
