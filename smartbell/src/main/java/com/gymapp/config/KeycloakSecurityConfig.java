package com.gymapp.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.HttpStatusEntryPoint;
import org.springframework.web.cors.CorsConfigurationSource;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Security config active quand keycloak.enabled=true dans application.properties.
 * Remplace la config JWT maison par la validation Keycloak.
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@ConditionalOnProperty(name = "keycloak.enabled", havingValue = "true")
@Primary
public class KeycloakSecurityConfig {

    private final CorsConfigurationSource corsConfigurationSource;

    public KeycloakSecurityConfig(CorsConfigurationSource corsConfigurationSource) {
        this.corsConfigurationSource = corsConfigurationSource;
    }

    @Bean
    public SecurityFilterChain keycloakFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .cors(cors -> cors.configurationSource(corsConfigurationSource))
            .authorizeHttpRequests(req -> req
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                .requestMatchers(
                    "/api/auth/**",
                    "/api-docs/**",
                    "/v3/api-docs/**",
                    "/swagger-ui/**",
                    "/swagger-ui.html").permitAll()
                // Member self-service
                .requestMatchers("/api/members/user/**").hasAnyRole("ADMIN", "MEMBER")
                .requestMatchers("/api/subscriptions/user/**").hasAnyRole("ADMIN", "MEMBER")
                .requestMatchers("/api/training/**").hasAnyRole("ADMIN", "COACH", "MEMBER")
                .requestMatchers("/api/nutrition-plans/**").hasAnyRole("ADMIN", "COACH", "MEMBER")
                .requestMatchers(HttpMethod.GET, "/api/courses/**").hasAnyRole("ADMIN", "COACH", "MEMBER")
                .requestMatchers(HttpMethod.GET, "/api/coaches/**").hasAnyRole("ADMIN", "COACH", "MEMBER")
                .requestMatchers(HttpMethod.POST, "/api/coaches/*/ratings").hasAnyRole("ADMIN", "MEMBER")
                .requestMatchers("/api/notifications/user/**").hasAnyRole("ADMIN", "MEMBER")
                .requestMatchers("/api/messages/**").hasAnyRole("ADMIN", "COACH", "MEMBER")
                .requestMatchers("/api/devices/**").hasAnyRole("ADMIN", "COACH", "MEMBER")
                // Admin only
                .requestMatchers("/api/members/**").hasRole("ADMIN")
                .requestMatchers("/api/coaches/**").hasRole("ADMIN")
                .requestMatchers("/api/subscriptions/**").hasRole("ADMIN")
                .requestMatchers("/api/payments/**").hasRole("ADMIN")
                .requestMatchers("/api/events/**").hasRole("ADMIN")
                .requestMatchers("/api/machines/**").hasRole("ADMIN")
                .requestMatchers("/api/notifications/**").hasRole("ADMIN")
                .requestMatchers("/api/complaints/**").hasRole("ADMIN")
                .requestMatchers("/api/ai/**").hasAnyRole("ADMIN", "COACH", "MEMBER")
                .anyRequest().authenticated()
            )
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .exceptionHandling(ex -> ex
                .authenticationEntryPoint(new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED)))
            // Valider les JWT émis par Keycloak
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt.jwtAuthenticationConverter(keycloakJwtConverter()))
            );

        return http.build();
    }

    /**
     * Convertit les rôles Keycloak (realm_access.roles) en GrantedAuthority Spring.
     * Keycloak retourne : { "realm_access": { "roles": ["ROLE_ADMIN", "ROLE_MEMBER"] } }
     */
    @Bean
    @ConditionalOnProperty(name = "keycloak.enabled", havingValue = "true")
    public JwtAuthenticationConverter keycloakJwtConverter() {
        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(jwt -> {
            Map<String, Object> realmAccess = jwt.getClaim("realm_access");
            if (realmAccess == null || !realmAccess.containsKey("roles")) {
                return List.of();
            }
            @SuppressWarnings("unchecked")
            Collection<String> roles = (Collection<String>) realmAccess.get("roles");
            return roles.stream()
                .filter(r -> r.startsWith("ROLE_"))
                .map(SimpleGrantedAuthority::new)
                .collect(Collectors.toList());
        });
        return converter;
    }

    /**
     * Décode les JWT Keycloak en utilisant la clé publique JWKS de Keycloak.
     * URL format : http://localhost:8180/realms/{realm}/protocol/openid-connect/certs
     */
    @Bean
    @ConditionalOnProperty(name = "keycloak.enabled", havingValue = "true")
    public JwtDecoder keycloakJwtDecoder(
            @org.springframework.beans.factory.annotation.Value("${keycloak.jwks-uri}") String jwksUri) {
        return NimbusJwtDecoder.withJwkSetUri(jwksUri).build();
    }
}
