package com.giastore.controller;

import com.giastore.model.*;
import com.giastore.service.PaluwaganService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/paluwagan")
@RequiredArgsConstructor
public class PaluwaganController {

    private final PaluwaganService service;

    // Packages
    @GetMapping("/packages")
    public List<PaluwaganPackage> getPackages() { return service.getAllPackages(); }

    @PostMapping("/packages")
    public PaluwaganPackage createPackage(@RequestBody PaluwaganPackage pkg) {
        return service.savePackage(pkg);
    }

    @PutMapping("/packages/{id}")
    public PaluwaganPackage updatePackage(@PathVariable Long id, @RequestBody PaluwaganPackage pkg) {
        return service.updatePackage(id, pkg);
    }

    @DeleteMapping("/packages/{id}")
    public ResponseEntity<?> deletePackage(@PathVariable Long id) {
        service.deletePackage(id);
        return ResponseEntity.ok().build();
    }

    // Members
    @GetMapping("/members")
    public List<Member> getMembers() { return service.getAllMembers(); }

    @GetMapping("/members/{id}")
    public Member getMember(@PathVariable Long id) { return service.getMemberById(id); }

    @PostMapping("/members")
    public Member createMember(@RequestBody Member member) { return service.saveMember(member); }

    @PutMapping("/members/{id}")
    public Member updateMember(@PathVariable Long id, @RequestBody Member member) {
        return service.updateMember(id, member);
    }

    // Payments
    @GetMapping("/payments")
    public List<Payment> getAllPayments() { return service.getAllPayments(); }

    @GetMapping("/payments/member/{memberId}")
    public List<Payment> getPaymentsByMember(@PathVariable Long memberId) {
        return service.getPaymentsByMember(memberId);
    }

    @PatchMapping("/payments/{id}/pay")
    public Payment markAsPaid(@PathVariable Long id) { return service.markAsPaid(id); }

    @PatchMapping("/payments/{id}/unpay")
    public Payment markAsUnpaid(@PathVariable Long id) { return service.markAsUnpaid(id); }
}
