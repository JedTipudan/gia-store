package com.giastore.config;

import com.giastore.model.PaymentMethod;
import com.giastore.model.User;
import com.giastore.repository.PaymentMethodRepository;
import com.giastore.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
@RequiredArgsConstructor
public class DataInitializer {

    @Bean
    CommandLineRunner seedData(UserRepository userRepository, PasswordEncoder encoder,
                               PaymentMethodRepository paymentMethodRepo) {
        return args -> {
            if (userRepository.findByUsername("admin").isEmpty()) {
                User admin = new User();
                admin.setUsername("admin");
                admin.setPassword(encoder.encode("admin123"));
                admin.setRole("ADMIN");
                admin.setFullName("Store Admin");
                userRepository.save(admin);
                System.out.println("Default admin created: admin / admin123");
            }

            if (paymentMethodRepo.count() == 0) {
                PaymentMethod gcash = new PaymentMethod();
                gcash.setName("GCash"); gcash.setIcon("gcash");
                gcash.setAccountNumber("09XX-XXX-XXXX");
                gcash.setAccountName("Gia Store");
                gcash.setInstructions("Send to GCash number above. Screenshot the receipt and upload as proof.");
                gcash.setActive(true);
                paymentMethodRepo.save(gcash);

                PaymentMethod cash = new PaymentMethod();
                cash.setName("Cash"); cash.setIcon("cash");
                cash.setAccountNumber("N/A");
                cash.setAccountName("Pay in person");
                cash.setInstructions("Pay cash directly to the store owner. Take a photo of the receipt.");
                cash.setActive(true);
                paymentMethodRepo.save(cash);
            }
        };
    }
}
