package com.giastore.service;

import com.giastore.model.*;
import com.giastore.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class PaluwaganService {

    private final PaluwaganPackageRepository packageRepo;
    private final MemberRepository memberRepo;
    private final PaymentRepository paymentRepo;
    private final PaymentMethodRepository paymentMethodRepo;
    private final UserRepository userRepository;

    // --- Packages ---
    public List<PaluwaganPackage> getAllPackages() { return packageRepo.findAll(); }
    public List<PaluwaganPackage> getActivePackages() { return packageRepo.findByActiveTrue(); }

    public PaluwaganPackage savePackage(PaluwaganPackage pkg) { return packageRepo.save(pkg); }

    public PaluwaganPackage updatePackage(Long id, PaluwaganPackage updated) {
        PaluwaganPackage pkg = packageRepo.findById(id).orElseThrow(() -> new RuntimeException("Package not found"));
        pkg.setName(updated.getName()); pkg.setDescription(updated.getDescription());
        pkg.setWeeklyAmount(updated.getWeeklyAmount()); pkg.setDurationWeeks(updated.getDurationWeeks());
        pkg.setActive(updated.getActive());
        return packageRepo.save(pkg);
    }

    public void deletePackage(Long id) {
        PaluwaganPackage pkg = packageRepo.findById(id).orElseThrow(() -> new RuntimeException("Package not found"));
        pkg.setActive(false); packageRepo.save(pkg);
    }

    // --- Members ---
    public List<Member> getAllMembers() { return memberRepo.findAll(); }
    public List<Member> getPendingMembers() { return memberRepo.findByStatus("PENDING"); }
    public List<Member> getMembersByUser(Long userId) { return memberRepo.findByUserId(userId); }

    public Member getMemberById(Long id) {
        return memberRepo.findById(id).orElseThrow(() -> new RuntimeException("Member not found"));
    }

    // Customer applies for paluwagan
    public Member applyMember(Member member) {
        member.setStatus("PENDING");
        member.setAppliedAt(LocalDateTime.now());
        return memberRepo.save(member);
    }

    // Admin adds member directly (auto-approved)
    public Member saveMember(Member member) {
        member.setStatus("ACTIVE");
        member.setApprovedAt(LocalDateTime.now());
        if (member.getStartDate() == null) member.setStartDate(LocalDate.now());
        Member saved = memberRepo.save(member);
        generatePaymentSchedule(saved);
        return saved;
    }

    // Admin approves member application
    public Member approveMember(Long id, String note) {
        Member member = getMemberById(id);
        member.setStatus("ACTIVE");
        member.setApprovedAt(LocalDateTime.now());
        member.setStartDate(LocalDate.now());
        member.setAdminNote(note);
        Member saved = memberRepo.save(member);
        generatePaymentSchedule(saved);
        return saved;
    }

    // Admin rejects member application
    public Member rejectMember(Long id, String note) {
        Member member = getMemberById(id);
        member.setStatus("REJECTED");
        member.setAdminNote(note);
        return memberRepo.save(member);
    }

    public Member updateMember(Long id, Member updated) {
        Member existing = getMemberById(id);
        existing.setFullName(updated.getFullName()); existing.setPhone(updated.getPhone());
        existing.setAddress(updated.getAddress()); existing.setStatus(updated.getStatus());
        return memberRepo.save(existing);
    }

    public void deleteMember(Long id) { memberRepo.deleteById(id); }

    private void generatePaymentSchedule(Member member) {
        PaluwaganPackage pkg = member.getPaluwaganPackage();
        List<Payment> payments = new ArrayList<>();
        for (int week = 1; week <= pkg.getDurationWeeks(); week++) {
            Payment p = new Payment();
            p.setMember(member); p.setWeekNumber(week); p.setAmount(pkg.getWeeklyAmount());
            p.setDueDate(member.getStartDate().plusWeeks(week - 1));
            p.setPaid(false); p.setApprovalStatus("PENDING");
            payments.add(p);
        }
        paymentRepo.saveAll(payments);
    }

    // --- Payments ---
    public List<Payment> getAllPayments() { return paymentRepo.findAll(); }
    public List<Payment> getPaymentsByMember(Long memberId) { return paymentRepo.findByMemberId(memberId); }
    public List<Payment> getPaymentsByUser(Long userId) { return paymentRepo.findByMemberUserId(userId); }
    public List<Payment> getPendingPaymentApprovals() { return paymentRepo.findByApprovalStatus("SUBMITTED"); }

    public Payment getPaymentById(Long id) {
        return paymentRepo.findById(id).orElseThrow(() -> new RuntimeException("Payment not found"));
    }

    // Customer submits payment proof
    public Payment submitPaymentProof(Long paymentId, String proofImageUrl,
                                       String paymentMethod, String referenceNumber) {
        Payment payment = getPaymentById(paymentId);
        payment.setProofImageUrl(proofImageUrl);
        payment.setPaymentMethod(paymentMethod);
        payment.setReferenceNumber(referenceNumber);
        payment.setApprovalStatus("SUBMITTED");
        payment.setSubmittedAt(LocalDateTime.now());
        return paymentRepo.save(payment);
    }

    // Admin approves payment
    public Payment approvePayment(Long paymentId, String note) {
        Payment payment = getPaymentById(paymentId);
        payment.setPaid(true);
        payment.setPaidAt(LocalDateTime.now());
        payment.setApprovalStatus("APPROVED");
        payment.setAdminNote(note);
        payment.setReceiptNumber(generateReceiptNumber(payment));
        return paymentRepo.save(payment);
    }

    // Admin rejects payment
    public Payment rejectPayment(Long paymentId, String note) {
        Payment payment = getPaymentById(paymentId);
        payment.setApprovalStatus("REJECTED");
        payment.setAdminNote(note);
        payment.setProofImageUrl(null);
        return paymentRepo.save(payment);
    }

    public Payment markAsPaid(Long paymentId) {
        Payment payment = getPaymentById(paymentId);
        payment.setPaid(true); payment.setPaidAt(LocalDateTime.now());
        payment.setApprovalStatus("APPROVED");
        payment.setReceiptNumber(generateReceiptNumber(payment));
        return paymentRepo.save(payment);
    }

    public Payment markAsUnpaid(Long paymentId) {
        Payment payment = getPaymentById(paymentId);
        payment.setPaid(false); payment.setPaidAt(null);
        payment.setReceiptNumber(null); payment.setApprovalStatus("PENDING");
        payment.setProofImageUrl(null);
        return paymentRepo.save(payment);
    }

    public void deletePayment(Long id) { paymentRepo.deleteById(id); }

    private String generateReceiptNumber(Payment payment) {
        return String.format("RCP-%05d-%s", payment.getId(),
                LocalDate.now().toString().replace("-", ""));
    }

    // --- Payment Methods ---
    public List<PaymentMethod> getAllPaymentMethods() { return paymentMethodRepo.findAll(); }
    public List<PaymentMethod> getActivePaymentMethods() { return paymentMethodRepo.findByActiveTrue(); }

    public PaymentMethod savePaymentMethod(PaymentMethod pm) { return paymentMethodRepo.save(pm); }

    public PaymentMethod updatePaymentMethod(Long id, PaymentMethod updated) {
        PaymentMethod pm = paymentMethodRepo.findById(id).orElseThrow(() -> new RuntimeException("Not found"));
        pm.setName(updated.getName()); pm.setAccountNumber(updated.getAccountNumber());
        pm.setAccountName(updated.getAccountName()); pm.setInstructions(updated.getInstructions());
        pm.setIcon(updated.getIcon()); pm.setActive(updated.getActive());
        return paymentMethodRepo.save(pm);
    }

    public void deletePaymentMethod(Long id) { paymentMethodRepo.deleteById(id); }
}
