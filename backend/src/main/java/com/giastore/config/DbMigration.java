package com.giastore.config;

import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;

@Configuration
@RequiredArgsConstructor
public class DbMigration {

    @Bean
    CommandLineRunner migrateDb(JdbcTemplate jdbc) {
        return args -> {
            try {
            // Add missing columns if they don't exist
            jdbc.execute("ALTER TABLE paluwagan_packages ADD COLUMN IF NOT EXISTS image_url VARCHAR(500)");
            jdbc.execute("ALTER TABLE paluwagan_packages ADD COLUMN IF NOT EXISTS max_slots INT NOT NULL DEFAULT 10");
            System.out.println("✓ DB migration completed");
        } catch (Exception e) {
            System.out.println("DB migration skipped or already applied: " + e.getMessage());
        }
        };
    }
}
