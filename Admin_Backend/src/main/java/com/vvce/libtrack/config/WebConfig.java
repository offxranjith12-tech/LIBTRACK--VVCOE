package com.vvce.libtrack.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.io.File;

/**
 * Serves uploaded files (currently just profile-picture avatars) back out
 * statically at /uploads/**, so the Flutter app can render them directly
 * with a plain image URL — no auth header needed for the image bytes
 * themselves (only the upload endpoint requires a JWT).
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${libtrack.uploads.dir:./uploads}")
    private String uploadsDir;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String absolutePath = new File(uploadsDir).getAbsolutePath();
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:" + absolutePath + File.separator);
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/uploads/**").allowedOriginPatterns("*").allowedMethods("GET");
    }
}
