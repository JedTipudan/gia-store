package com.giastore.model;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDate;

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

    @Column(nullable = false)
    private LocalDate startDate;

    @Column(nullable = false)
    private String status = "ACTIVE"; // ACTIVE, COMPLETED, DROPPED
}
