package com.giastore.service;

import com.giastore.model.*;
import com.giastore.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class PaluwaganService {

    private final PaluwaganPackageRepository packageRepo;
    private final MemberRepository memberRepo;
    private final PaymentRepository paymentRepo;

    // --- Packages ---
    public List<PaluwaganPackage> getAllPackages() { return packageRepo.findAll(); }

    public PaluwaganPackage savePackage(PaluwaganPackage pkg) { return packageRepo.save(pkg); }

    public PaluwaganPackage updatePackage(Long id, PaluwaganPackage updated) {
        PaluwaganPackage pkg = packageRepo.findById(id)
                .orElseThrow(() -> new RuntimeException("Package not found"));
        pkg.setName(updated.getName());
        pkg.setDescription(updated.getDescription());
        pkg.setWeeklyAmount(updated.getWeeklyAmount());
        pkg.setDurationWeeks(updated.getDurationWeeks());
        pkg.setActive(updated.getActive());
        return packageRepo.save(pkg);
    }

    public void deletePackage(Long id) {
        PaluwaganPackage pkg = packageRepo.findById(id)
                .orElseThrow(() -> new RuntimeException("Package not found"));
        pkg.setActive(false);
        packageRepo.save(pkg);
    }

    // --- Members ---
    public List<Member> getAllMembers() { return memberRepo.findAll(); }

    public Member getMemberById(Long id) {
        return memberRepo.findById(id).orElseThrow(() -> new RuntimeException("Member not found"));
    }

    public Member saveMember(Member member) {
        Member saved = memberRepo.save(member);
        generatePaymentSchedule(saved);
        return saved;
    }

    public Member updateMember(Long id, Member updated) {
        Member existing = getMemberById(id);
        existing.setFullName(updated.getFullName());
        existing.setPhone(updated.getPhone());
        existing.setAddress(updated.getAddress());
        existing.setStatus(updated.getStatus());
        return memberRepo.save(existing);
    }

    private void generatePaymentSchedule(Member member) {
        PaluwaganPackage pkg = member.getPaluwaganPackage();
        List<Payment> payments = new ArrayList<>();
        for (int week = 1; week <= pkg.getDurationWeeks(); week++) {
            Payment p = new Payment();
            p.setMember(member);
            p.setWeekNumber(week);
            p.setAmount(pkg.getWeeklyAmount());
            p.setDueDate(member.getStartDate().plusWeeks(week - 1));
            p.setPaid(false);
            payments.add(p);
        }
        paymentRepo.saveAll(payments);
    }

    // --- Payments ---
    public List<Payment> getPaymentsByMember(Long memberId) {
        return paymentRepo.findByMemberId(memberId);
    }

    public List<Payment> getAllPayments() { return paymentRepo.findAll(); }

    public Payment getPaymentById(Long id) {
        return paymentRepo.findById(id).orElseThrow(() -> new RuntimeException("Payment not found"));
    }

    public Payment markAsPaid(Long paymentId) {
        Payment payment = getPaymentById(paymentId);
        payment.setPaid(true);
        payment.setPaidAt(java.time.LocalDateTime.now());
        payment.setReceiptNumber(generateReceiptNumber(payment));
        return paymentRepo.save(payment);
    }

    public Payment markAsUnpaid(Long paymentId) {
        Payment payment = getPaymentById(paymentId);
        payment.setPaid(false);
        payment.setPaidAt(null);
        payment.setReceiptNumber(null);
        return paymentRepo.save(payment);
    }

    private String generateReceiptNumber(Payment payment) {
        return String.format("RCP-%05d-%s", payment.getId(),
                LocalDate.now().toString().replace("-", ""));
    }
}
