package com.giastore.repository;

import com.giastore.model.Payment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.math.BigDecimal;
import java.util.List;

public interface PaymentRepository extends JpaRepository<Payment, Long> {
    List<Payment> findByMemberId(Long memberId);
    List<Payment> findByPaidFalse();
    List<Payment> findByPaidTrue();

    @Query("SELECT COALESCE(SUM(p.amount), 0) FROM Payment p WHERE p.paid = true")
    BigDecimal sumPaidPayments();

    @Query("SELECT COUNT(p) FROM Payment p WHERE p.paid = false")
    Long countUnpaidPayments();
}
