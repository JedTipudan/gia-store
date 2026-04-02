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
    private Integer weekNumber;

    @Column(nullable = false)
    private BigDecimal amount;

    @Column(nullable = false)
    private Boolean paid = false;

    private LocalDate dueDate;
    private LocalDateTime paidAt;
    private String receiptNumber;
}
