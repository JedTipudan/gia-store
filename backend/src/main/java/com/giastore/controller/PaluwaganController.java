package com.giastore.controller;

import com.giastore.model.*;
import com.giastore.repository.UserRepository;
import com.giastore.service.PaluwaganService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/paluwagan")
@RequiredArgsConstructor
public class PaluwaganController {

    private final PaluwaganService service;
    private final UserRepository userRepository;

    // Packages
    @GetMapping("/packages")
    public List<PaluwaganPackage> getPackages() { return service.getAllPackages(); }

    @GetMapping("/packages/active")
    public List<PaluwaganPackage> getActivePackages() { return service.getActivePackages(); }

    @GetMapping("/packages/{id}/enrolled-count")
    public ResponseEntity<?> getEnrolledCount(@PathVariable Long id) {
        return ResponseEntity.ok(Map.of("enrolled", service.getEnrolledCount(id)));
    }

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
        try {
            service.deletePackage(id);
            return ResponseEntity.ok().build();
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    // Members
    @GetMapping("/members")
    public List<Member> getMembers() { return service.getAllMembers(); }

    @GetMapping("/members/pending")
    public List<Member> getPendingMembers() { return service.getPendingMembers(); }

    @GetMapping("/members/user/{userId}")
    public List<Member> getMembersByUser(@PathVariable Long userId) {
        return service.getMembersByUser(userId);
    }

    @GetMapping("/members/{id}")
    public Member getMember(@PathVariable Long id) { return service.getMemberById(id); }

    @PostMapping("/members")
    public Member createMember(@RequestBody Member member) { return service.saveMember(member); }

    // Customer applies — accepts flat body with userId and packageId
    @PostMapping("/members/apply")
    public ResponseEntity<?> applyMember(@RequestBody Map<String, Object> body) {
        try {
            Long userId = Long.valueOf(body.get("userId").toString());
            Long packageId = Long.valueOf(
                ((Map<?, ?>) body.get("paluwaganPackage")).get("id").toString());

            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("User not found"));

            Member member = new Member();
            member.setFullName(body.getOrDefault("fullName", "").toString());
            member.setPhone(body.getOrDefault("phone", "").toString());
            member.setAddress(body.getOrDefault("address", "").toString());
            member.setUser(user);

            PaluwaganPackage pkg = new PaluwaganPackage();
            pkg.setId(packageId);
            member.setPaluwaganPackage(pkg);

            return ResponseEntity.ok(service.applyMember(member));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @PatchMapping("/members/{id}/approve")
    public ResponseEntity<?> approveMember(@PathVariable Long id,
            @RequestBody(required = false) Map<String, String> body) {
        try {
            return ResponseEntity.ok(service.approveMember(id,
                    body != null ? body.get("note") : null));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @PatchMapping("/members/{id}/reject")
    public Member rejectMember(@PathVariable Long id,
            @RequestBody(required = false) Map<String, String> body) {
        return service.rejectMember(id, body != null ? body.get("note") : null);
    }

    @PutMapping("/members/{id}")
    public Member updateMember(@PathVariable Long id, @RequestBody Member member) {
        return service.updateMember(id, member);
    }

    @DeleteMapping("/members/{id}")
    public ResponseEntity<?> deleteMember(@PathVariable Long id) {
        service.deleteMember(id);
        return ResponseEntity.ok().build();
    }

    // Payments
    @GetMapping("/payments")
    public List<Payment> getAllPayments() { return service.getAllPayments(); }

    @GetMapping("/payments/paid")
    public List<Payment> getPaidPayments() { return service.getPaidPayments(); }

    @GetMapping("/payments/pending-approvals")
    public List<Payment> getPendingApprovals() { return service.getPendingPaymentApprovals(); }

    @GetMapping("/payments/member/{memberId}")
    public List<Payment> getPaymentsByMember(@PathVariable Long memberId) {
        return service.getPaymentsByMember(memberId);
    }

    @GetMapping("/payments/user/{userId}")
    public List<Payment> getPaymentsByUser(@PathVariable Long userId) {
        return service.getPaymentsByUser(userId);
    }

    @PatchMapping("/payments/{id}/pay")
    public Payment markAsPaid(@PathVariable Long id) { return service.markAsPaid(id); }

    @PatchMapping("/payments/{id}/unpay")
    public Payment markAsUnpaid(@PathVariable Long id) { return service.markAsUnpaid(id); }

    @PatchMapping("/payments/{id}/submit-proof")
    public Payment submitProof(@PathVariable Long id, @RequestBody Map<String, String> body) {
        return service.submitPaymentProof(id, body.get("proofImageUrl"),
                body.get("paymentMethod"), body.get("referenceNumber"));
    }

    @PatchMapping("/payments/{id}/approve")
    public Payment approvePayment(@PathVariable Long id,
            @RequestBody(required = false) Map<String, String> body) {
        return service.approvePayment(id, body != null ? body.get("note") : null);
    }

    @PatchMapping("/payments/{id}/reject")
    public Payment rejectPayment(@PathVariable Long id,
            @RequestBody(required = false) Map<String, String> body) {
        return service.rejectPayment(id, body != null ? body.get("note") : null);
    }

    @DeleteMapping("/payments/{id}")
    public ResponseEntity<?> deletePayment(@PathVariable Long id) {
        service.deletePayment(id);
        return ResponseEntity.ok().build();
    }

    // Payment Methods
    @GetMapping("/payment-methods")
    public List<PaymentMethod> getPaymentMethods() { return service.getAllPaymentMethods(); }

    @GetMapping("/payment-methods/active")
    public List<PaymentMethod> getActivePaymentMethods() { return service.getActivePaymentMethods(); }

    @PostMapping("/payment-methods")
    public PaymentMethod createPaymentMethod(@RequestBody PaymentMethod pm) {
        return service.savePaymentMethod(pm);
    }

    @PutMapping("/payment-methods/{id}")
    public PaymentMethod updatePaymentMethod(@PathVariable Long id, @RequestBody PaymentMethod pm) {
        return service.updatePaymentMethod(id, pm);
    }

    @DeleteMapping("/payment-methods/{id}")
    public ResponseEntity<?> deletePaymentMethod(@PathVariable Long id) {
        service.deletePaymentMethod(id);
        return ResponseEntity.ok().build();
    }
}
