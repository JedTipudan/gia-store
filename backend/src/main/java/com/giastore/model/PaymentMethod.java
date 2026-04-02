package com.giastore.model;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "payment_methods")
public class PaymentMethod {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name; // e.g. GCash, Cash, BDO

    private String accountNumber; // e.g. 09XX-XXX-XXXX
    private String accountName;
    private String instructions;
    private String icon; // gcash, cash, bank

    @Column(nullable = false)
    private Boolean active = true;
}
