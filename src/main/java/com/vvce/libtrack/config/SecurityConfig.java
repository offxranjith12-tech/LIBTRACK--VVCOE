package com.vvce.libtrack.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/v1/auth/**").permitAll()
                .requestMatchers("/actuator/health").permitAll()
                .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/uploads/**").permitAll()
                // Feedback: any logged-in role can submit; only Admin/Librarian can list/resolve.
                .requestMatchers(HttpMethod.POST, "/api/v1/feedback").authenticated()
                .requestMatchers(HttpMethod.GET, "/api/v1/feedback").hasAnyRole("ADMIN", "LIBRARIAN")
                .requestMatchers(HttpMethod.PATCH, "/api/v1/feedback/**").hasAnyRole("ADMIN", "LIBRARIAN")
                // Library settings: everyone can read (hours/limits), only Admin/Librarian can edit.
                .requestMatchers(HttpMethod.GET, "/api/v1/settings").authenticated()
                .requestMatchers(HttpMethod.PUT, "/api/v1/settings").hasAnyRole("ADMIN", "LIBRARIAN")
                // Student/Staff account management: Admin/Librarian only.
                .requestMatchers(HttpMethod.POST, "/api/v1/students/**").hasAnyRole("ADMIN", "LIBRARIAN")
                .requestMatchers(HttpMethod.PUT, "/api/v1/students/**").hasAnyRole("ADMIN", "LIBRARIAN")
                .requestMatchers(HttpMethod.PATCH, "/api/v1/students/**").hasAnyRole("ADMIN", "LIBRARIAN")
                .requestMatchers(HttpMethod.DELETE, "/api/v1/students/**").hasAnyRole("ADMIN", "LIBRARIAN")
                .requestMatchers(HttpMethod.POST, "/api/v1/staff/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.PUT, "/api/v1/staff/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.PATCH, "/api/v1/staff/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/v1/staff/**").hasRole("ADMIN")
                // Notifications: Admin/Librarian broadcast only (no individual notification concept).
                .requestMatchers(HttpMethod.POST, "/api/v1/notifications").hasAnyRole("ADMIN", "LIBRARIAN")
                .requestMatchers(HttpMethod.DELETE, "/api/v1/notifications/**").hasAnyRole("ADMIN", "LIBRARIAN")
                // Manual overrides (fine status, status correction, extension approval): Admin/Librarian only.
                .requestMatchers(HttpMethod.PATCH, "/api/v1/transactions/*/fine-status").hasAnyRole("ADMIN", "LIBRARIAN")
                .requestMatchers(HttpMethod.PATCH, "/api/v1/transactions/*/manual-status").hasAnyRole("ADMIN", "LIBRARIAN")
                .requestMatchers(HttpMethod.PATCH, "/api/v1/transactions/*/extension/**").hasAnyRole("ADMIN", "LIBRARIAN")
                .requestMatchers("/api/v1/reports/**").hasAnyRole("ADMIN", "LIBRARIAN")
                .requestMatchers(HttpMethod.POST, "/api/v1/books/bulk-import").hasAnyRole("ADMIN", "LIBRARIAN")
                // Book catalogue writes: any authenticated user can browse/search, but only
                // Admin/Librarian can add, edit, delete, or change a cover image.
                .requestMatchers(HttpMethod.POST, "/api/v1/books").hasAnyRole("ADMIN", "LIBRARIAN")
                .requestMatchers(HttpMethod.PUT, "/api/v1/books/**").hasAnyRole("ADMIN", "LIBRARIAN")
                .requestMatchers(HttpMethod.DELETE, "/api/v1/books/**").hasAnyRole("ADMIN", "LIBRARIAN")
                .requestMatchers(HttpMethod.POST, "/api/v1/books/*/cover").hasAnyRole("ADMIN", "LIBRARIAN")
                // Issue/return happens at the counter — Admin/Librarian only, never Student.
                .requestMatchers(HttpMethod.POST, "/api/v1/transactions/issue").hasAnyRole("ADMIN", "LIBRARIAN")
                .requestMatchers(HttpMethod.POST, "/api/v1/transactions/return").hasAnyRole("ADMIN", "LIBRARIAN")

                .requestMatchers(HttpMethod.POST, "/api/v1/book-requests").authenticated()
                .requestMatchers(HttpMethod.GET, "/api/v1/book-requests").hasAnyRole("ADMIN", "LIBRARIAN")
                .requestMatchers(HttpMethod.POST, "/api/v1/book-requests/*/approve").hasAnyRole("ADMIN", "LIBRARIAN")
                .requestMatchers(HttpMethod.POST, "/api/v1/book-requests/*/reject").hasAnyRole("ADMIN", "LIBRARIAN")
                .anyRequest().authenticated()
            )
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        // Tighten this to your actual app/domain origins before going to production.
        configuration.setAllowedOriginPatterns(List.of("*"));
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
