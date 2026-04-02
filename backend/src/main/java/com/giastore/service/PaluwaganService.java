package com.giastore.service;

import com.giastore.model.*;
import com.giastore.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
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

    // --- Packages ---
    public List<PaluwaganPackage> getAllPackages() { return packageRepo.findAll(); }
    public List<PaluwaganPackage> getActivePackages() { return packageRepo.findByActiveTrue(); }

    public int getEnrolledCount(Long packageId) {
        return (int) memberRepo.findByPaluwaganPackageId(packageId).stream()
                .filter(m -> m.getStatus().equals("ACTIVE")).count();
    }

    public PaluwaganPackage savePackage(PaluwaganPackage pkg) { return packageRepo.save(pkg); }

    public PaluwaganPackage updatePackage(Long id, PaluwaganPackage updated) {
        PaluwaganPackage pkg = packageRepo.findById(id)
                .orElseThrow(() -> new RuntimeException("Package not found"));
        pkg.setName(updated.getName()); pkg.setDescription(updated.getDescription());
        pkg.setWeeklyAmount(updated.getWeeklyAmount());
        pkg.setDurationWeeks(updated.getDurationWeeks());
        pkg.setDurationMonths(updated.getDurationMonths());
        pkg.setPaymentType(updated.getPaymentType());
        pkg.setMaxSlots(updated.getMaxSlots()); pkg.setImageUrl(updated.getImageUrl());
        pkg.setActive(updated.getActive());
        return packageRepo.save(pkg);
    }

    public void deletePackage(Long id) {
        // Hard delete — remove from DB
        // First check if any active members exist
        long activeMembers = memberRepo.findByPaluwaganPackageId(id).stream()
                .filter(m -> m.getStatus().equals("ACTIVE")).count();
        if (activeMembers > 0)
            throw new RuntimeException("Cannot delete: " + activeMembers + " active member(s) enrolled");
        packageRepo.deleteById(id);
    }

    // --- Members ---
    public List<Member> getAllMembers() { return memberRepo.findAll(); }
    public List<Member> getActiveMembers() { return memberRepo.findByStatus("ACTIVE"); }
    public List<Member> getPendingMembers() { return memberRepo.findByStatus("PENDING"); }
    public List<Member> getMembersByUser(Long userId) { return memberRepo.findByUserId(userId); }

    public Member getMemberById(Long id) {
        return memberRepo.findById(id).orElseThrow(() -> new RuntimeException("Member not found"));
    }

    public Member applyMember(Member member) {
        // Fetch the full package entity from DB — JPA needs the full object not just an ID shell
        PaluwaganPackage pkg = packageRepo.findById(member.getPaluwaganPackage().getId())
                .orElseThrow(() -> new RuntimeException("Package not found"));
        member.setPaluwaganPackage(pkg);
        member.setStatus("PENDING");
        member.setAppliedAt(LocalDateTime.now());
        return memberRepo.save(member);
    }

    public Member saveMember(Member member) {
        PaluwaganPackage pkg = packageRepo.findById(member.getPaluwaganPackage().getId())
                .orElseThrow(() -> new RuntimeException("Package not found"));
        member.setPaluwaganPackage(pkg);
        member.setStatus("ACTIVE");
        member.setApprovedAt(LocalDateTime.now());
        if (member.getStartDate() == null) member.setStartDate(LocalDate.now());
        Member saved = memberRepo.save(member);
        generatePaymentSchedule(saved);
        return saved;
    }

    public Member approveMember(Long id, String note) {
        Member member = getMemberById(id);
        PaluwaganPackage pkg = member.getPaluwaganPackage();
        int enrolled = getEnrolledCount(pkg.getId());
        if (enrolled >= pkg.getMaxSlots())
            throw new RuntimeException("Package is full. Max slots: " + pkg.getMaxSlots());
        member.setStatus("ACTIVE");
        member.setApprovedAt(LocalDateTime.now());
        member.setStartDate(LocalDate.now());
        member.setAdminNote(note);
        Member saved = memberRepo.save(member);
        generatePaymentSchedule(saved);
        return saved;
    }

    public Member rejectMember(Long id, String note) {
        Member member = getMemberById(id);
        member.setStatus("REJECTED"); member.setAdminNote(note);
        return memberRepo.save(member);
    }

    public Member updateMember(Long id, Member updated) {
        Member existing = getMemberById(id);
        existing.setFullName(updated.getFullName()); existing.setPhone(updated.getPhone());
        existing.setAddress(updated.getAddress()); existing.setStatus(updated.getStatus());
        return memberRepo.save(existing);
    }

    public void deleteMember(Long id) {
        // Delete payments first, then member
        paymentRepo.deleteAll(paymentRepo.findByMemberId(id));
        memberRepo.deleteById(id);
    }

    private void generatePaymentSchedule(Member member) {
        PaluwaganPackage pkg = member.getPaluwaganPackage();
        // Use durationMonths if set, otherwise fall back to durationWeeks
        int totalMonths = pkg.getDurationMonths() != null && pkg.getDurationMonths() > 0
                ? pkg.getDurationMonths() : pkg.getDurationWeeks();
        List<Payment> payments = new ArrayList<>();
        LocalDate startDate = member.getStartDate();
        for (int i = 1; i <= totalMonths; i++) {
            LocalDate dueDate = startDate.withDayOfMonth(1).plusMonths(i - 1);
            Payment p = new Payment();
            p.setMember(member); p.setPeriodNumber(i); p.setWeekNumber(i);
            p.setPeriodLabel("Month " + i + " (" +
                dueDate.getMonth().getDisplayName(
                    java.time.format.TextStyle.SHORT, java.util.Locale.ENGLISH)
                + " " + dueDate.getYear() + ")");
            p.setAmount(pkg.getWeeklyAmount());
            p.setDueDate(dueDate);
            p.setPaid(false); p.setApprovalStatus("PENDING");
            payments.add(p);
        }
        paymentRepo.saveAll(payments);
    }

    // --- Payments ---
    public List<Payment> getAllPayments() { return paymentRepo.findAll(); }
    public List<Payment> getPaidPayments() { return paymentRepo.findByPaidTrue(); }
    public List<Payment> getPaymentsByMember(Long memberId) { return paymentRepo.findByMemberId(memberId); }
    public List<Payment> getPaymentsByUser(Long userId) { return paymentRepo.findByMemberUserId(userId); }
    public List<Payment> getPendingPaymentApprovals() { return paymentRepo.findByApprovalStatus("SUBMITTED"); }

    public Payment getPaymentById(Long id) {
        return paymentRepo.findById(id).orElseThrow(() -> new RuntimeException("Payment not found"));
    }

    public Payment submitPaymentProof(Long id, String proofUrl, String method, String ref) {
        Payment p = getPaymentById(id);
        p.setProofImageUrl(proofUrl); p.setPaymentMethod(method);
        p.setReferenceNumber(ref); p.setApprovalStatus("SUBMITTED");
        p.setSubmittedAt(LocalDateTime.now());
        return paymentRepo.save(p);
    }

    public Payment approvePayment(Long id, String note) {
        Payment p = getPaymentById(id);
        p.setPaid(true); p.setPaidAt(LocalDateTime.now());
        p.setApprovalStatus("APPROVED"); p.setAdminNote(note);
        p.setReceiptNumber(String.format("RCP-%05d-%s", p.getId(),
                LocalDate.now().toString().replace("-", "")));
        return paymentRepo.save(p);
    }

    public Payment rejectPayment(Long id, String note) {
        Payment p = getPaymentById(id);
        p.setApprovalStatus("REJECTED"); p.setAdminNote(note); p.setProofImageUrl(null);
        return paymentRepo.save(p);
    }

    public Payment markAsPaid(Long id) {
        Payment p = getPaymentById(id);
        p.setPaid(true); p.setPaidAt(LocalDateTime.now()); p.setApprovalStatus("APPROVED");
        p.setReceiptNumber(String.format("RCP-%05d-%s", p.getId(),
                LocalDate.now().toString().replace("-", "")));
        return paymentRepo.save(p);
    }

    public Payment markAsUnpaid(Long id) {
        Payment p = getPaymentById(id);
        p.setPaid(false); p.setPaidAt(null); p.setReceiptNumber(null);
        p.setApprovalStatus("PENDING"); p.setProofImageUrl(null);
        return paymentRepo.save(p);
    }

    public void deletePayment(Long id) { paymentRepo.deleteById(id); }

    // --- Payment Methods ---
    public List<PaymentMethod> getAllPaymentMethods() { return paymentMethodRepo.findAll(); }
    public List<PaymentMethod> getActivePaymentMethods() { return paymentMethodRepo.findByActiveTrue(); }
    public PaymentMethod savePaymentMethod(PaymentMethod pm) { return paymentMethodRepo.save(pm); }

    public PaymentMethod updatePaymentMethod(Long id, PaymentMethod updated) {
        PaymentMethod pm = paymentMethodRepo.findById(id)
                .orElseThrow(() -> new RuntimeException("Not found"));
        pm.setName(updated.getName()); pm.setAccountNumber(updated.getAccountNumber());
        pm.setAccountName(updated.getAccountName()); pm.setInstructions(updated.getInstructions());
        pm.setIcon(updated.getIcon()); pm.setActive(updated.getActive());
        return paymentMethodRepo.save(pm);
    }

    public void deletePaymentMethod(Long id) { paymentMethodRepo.deleteById(id); }
}
