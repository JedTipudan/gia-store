package com.giastore.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import java.math.BigDecimal;

@Data
@AllArgsConstructor
public class DashboardSummary {
    private long totalFoodItems;
    private long totalMembers;
    private long activeMembers;
    private long totalPackages;
    private BigDecimal totalCollected;
    private long unpaidPayments;
    private long totalPayments;
    private long pendingMemberApprovals;
    private long pendingPaymentApprovals;
}
