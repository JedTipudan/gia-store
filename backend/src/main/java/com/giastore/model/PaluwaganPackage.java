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

    @Column(nullable = false)
    private Integer maxSlots = 10;

    private String imageUrl;

    @Column(nullable = false)
    private Boolean active = true;

    // Helper: treat durationWeeks as months
    @Transient
    public Integer getDurationMonths() {
        return durationWeeks;
    }

    @Transient
    public void setDurationMonths(Integer months) {
        this.durationWeeks = months;
    }
}
