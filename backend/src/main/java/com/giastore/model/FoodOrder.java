package com.giastore.model;

import jakarta.persistence.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "food_orders")
public class FoodOrder {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne
    @JoinColumn(name = "food_item_id", nullable = false)
    private FoodItem foodItem;

    @Column(nullable = false)
    private Integer quantity = 1;

    @Column(nullable = false)
    private BigDecimal totalPrice;

    @Column(nullable = false)
    private String status = "PENDING"; // PENDING, PAID, CONFIRMED, CANCELLED

    @Column(nullable = false)
    private LocalDateTime orderedAt = LocalDateTime.now();

    private String note;

    // Payment proof
    private String paymentMethod;
    private String referenceNumber;
    private String proofImageUrl;
    private LocalDateTime paidAt;
}
