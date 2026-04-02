package com.giastore.model;

import jakarta.persistence.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "payments")
public class Payment {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "member_id", nullable = false)
    private Member member;

    @Column(nullable = false)
    private Integer periodNumber; // week or month number

    @Column(nullable = false)
    private String periodLabel; // e.g. "Week 1", "Month 1"

    @Column(nullable = false)
    private BigDecimal amount;

    @Column(nullable = false)
    private Boolean paid = false;

    private LocalDate dueDate;
    private LocalDateTime paidAt;
    private String receiptNumber;

    // Customer proof submission
    private String proofImageUrl;
    private String paymentMethod;
    private String referenceNumber;
    private LocalDateTime submittedAt;

    // Admin approval
    @Column(nullable = false)
    private String approvalStatus = "PENDING"; // PENDING, SUBMITTED, APPROVED, REJECTED

    private String adminNote;
}
