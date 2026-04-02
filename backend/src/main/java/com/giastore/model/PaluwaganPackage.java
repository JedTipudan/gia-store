package com.giastore.model;

import jakarta.persistence.*;
import lombok.Data;
import java.math.BigDecimal;

@Data
@Entity
@Table(name = "paluwagan_packages")
public class PaluwaganPackage {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    private String description;

    @Column(nullable = false)
    private BigDecimal weeklyAmount; // monthly payment amount

    // Stored as duration_weeks in DB but represents months
    @Column(name = "duration_weeks", nullable = false)
    private Integer durationWeeks;

    @Column(name = "duration_months")
    private Integer durationMonths;

    @Column(name = "payment_type")
    private String paymentType = "MONTHLY";

    @Column(nullable = false)
    private Integer maxSlots = 10;

    private String imageUrl;

    @Column(nullable = false)
    private Boolean active = true;
}
