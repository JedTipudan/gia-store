package com.giastore.service;

import com.giastore.model.Payment;
import com.itextpdf.kernel.colors.ColorConstants;
import com.itextpdf.kernel.pdf.*;
import com.itextpdf.layout.Document;
import com.itextpdf.layout.element.*;
import com.itextpdf.layout.properties.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.io.ByteArrayOutputStream;
import java.text.NumberFormat;
import java.util.Locale;

@Service
@RequiredArgsConstructor
public class ReceiptService {

    private final PaluwaganService paluwaganService;

    public byte[] generateReceiptPdf(Long paymentId) {
        Payment payment = paluwaganService.getPaymentById(paymentId);
        if (!payment.getPaid()) throw new RuntimeException("Payment is not yet paid");

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        PdfWriter writer = new PdfWriter(baos);
        PdfDocument pdf = new PdfDocument(writer);
        Document doc = new Document(pdf);

        // Header
        Paragraph header = new Paragraph("Gia Foodies - Official Receipt")
                .setBold().setFontSize(18).setTextAlignment(TextAlignment.CENTER);
        doc.add(header);

        doc.add(new Paragraph("OFFICIAL RECEIPT")
                .setBold().setFontSize(14).setTextAlignment(TextAlignment.CENTER)
                .setFontColor(ColorConstants.DARK_GRAY));

        doc.add(new Paragraph("\n"));

        // Receipt details table
        Table table = new Table(UnitValue.createPercentArray(new float[]{40, 60}))
                .setWidth(UnitValue.createPercentValue(100));

        addRow(table, "Receipt No.:", payment.getReceiptNumber());
        addRow(table, "Member Name:", payment.getMember().getFullName());
        addRow(table, "Phone:", payment.getMember().getPhone() != null ? payment.getMember().getPhone() : "N/A");
        addRow(table, "Package:", payment.getMember().getPaluwaganPackage().getName());
        addRow(table, "Period:", (payment.getPeriodLabel() != null ? payment.getPeriodLabel() : "Month " + payment.getPeriodNumber()) + " of " +
                payment.getMember().getPaluwaganPackage().getDurationMonths() + " months");
        addRow(table, "Due Date:", payment.getDueDate() != null ? payment.getDueDate().toString() : "N/A");
        addRow(table, "Paid On:", payment.getPaidAt() != null ? payment.getPaidAt().toString() : "N/A");

        NumberFormat php = NumberFormat.getCurrencyInstance(new Locale("fil", "PH"));
        addRow(table, "Amount Paid:", php.format(payment.getAmount()));

        doc.add(table);

        doc.add(new Paragraph("\n"));
        doc.add(new Paragraph("Status: PAID ✓")
                .setBold().setFontSize(14).setFontColor(ColorConstants.GREEN)
                .setTextAlignment(TextAlignment.CENTER));

        doc.add(new Paragraph("\n\n"));
        doc.add(new Paragraph("Thank you for your payment!")
                .setItalic().setTextAlignment(TextAlignment.CENTER));

        doc.add(new Paragraph("_________________________")
                .setTextAlignment(TextAlignment.RIGHT).setMarginTop(40));
        doc.add(new Paragraph("Authorized Signature")
                .setTextAlignment(TextAlignment.RIGHT));

        doc.close();
        return baos.toByteArray();
    }

    private void addRow(Table table, String label, String value) {
        table.addCell(new Cell().add(new Paragraph(label).setBold())
                .setBorder(com.itextpdf.layout.borders.Border.NO_BORDER));
        table.addCell(new Cell().add(new Paragraph(value))
                .setBorder(com.itextpdf.layout.borders.Border.NO_BORDER));
    }
}
