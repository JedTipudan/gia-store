package com.giastore.service;

import com.giastore.dto.DashboardSummary;
import com.giastore.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final FoodItemRepository foodItemRepo;
    private final MemberRepository memberRepo;
    private final PaluwaganPackageRepository packageRepo;
    private final PaymentRepository paymentRepo;

    public DashboardSummary getSummary() {
        return new DashboardSummary(
                foodItemRepo.count(),
                memberRepo.count(),
                memberRepo.findByStatus("ACTIVE").size(),
                packageRepo.count(),
                paymentRepo.sumPaidPayments(),
                paymentRepo.countUnpaidPayments(),
                paymentRepo.count()
        );
    }
}
