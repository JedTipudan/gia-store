package com.giastore.controller;

import com.giastore.dto.DashboardSummary;
import com.giastore.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService dashboardService;

    @GetMapping
    public DashboardSummary getSummary() { return dashboardService.getSummary(); }
}
