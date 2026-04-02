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
    private BigDecimal weeklyAmount;

    @Column(nullable = false)
    private Integer durationWeeks;

    @Column(nullable = false)
    private Integer maxSlots = 10;

    @Column(nullable = false)
    private Boolean active = true;
}
