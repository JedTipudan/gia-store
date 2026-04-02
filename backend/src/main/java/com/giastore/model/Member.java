package com.giastore.model;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "members")
public class Member {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String fullName;

    private String phone;
    private String address;

    @ManyToOne
    @JoinColumn(name = "package_id", nullable = false)
    private PaluwaganPackage paluwaganPackage;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;

    private LocalDate startDate;

    @Column(nullable = false)
    private String status = "PENDING"; // PENDING, ACTIVE, REJECTED, COMPLETED, DROPPED

    private LocalDateTime appliedAt = LocalDateTime.now();
    private LocalDateTime approvedAt;
    private String adminNote;
}
