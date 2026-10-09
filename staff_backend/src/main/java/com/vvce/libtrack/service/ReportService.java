package com.vvce.libtrack.service;

import com.lowagie.text.Document;
import com.lowagie.text.FontFactory;
import com.lowagie.text.Paragraph;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import com.vvce.libtrack.dto.StatsDtos;
import com.vvce.libtrack.entity.BorrowTransaction;
import com.vvce.libtrack.repository.BorrowTransactionRepository;
import lombok.RequiredArgsConstructor;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ReportService {

    private final BorrowTransactionRepository transactionRepository;

    /** Powers the Reports screen overview grid. */
    public StatsDtos.ReportSummary getSummary() {
        LocalDate today = LocalDate.now();
        List<BorrowTransaction> all = transactionRepository.findAll();

        long todaysIssues = all.stream().filter(t -> t.getIssueDate().isEqual(today)).count();
        long todaysReturns = all.stream().filter(t -> t.getReturnDate() != null && t.getReturnDate().isEqual(today)).count();
        long overdue = transactionRepository.countOverdue(today);
        double fineCollection = all.stream()
                .filter(t -> Boolean.TRUE.equals(t.getFineCollected()))
                .mapToDouble(t -> t.getFine() == null ? 0 : t.getFine())
                .sum();
        long activeStudents = transactionRepository.countActiveBorrowers();

        Map<String, Long> byTitle = all.stream()
                .collect(Collectors.groupingBy(t -> t.getBook().getTitle(), Collectors.counting()));
        List<StatsDtos.TopBook> mostBorrowed = byTitle.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                .limit(5)
                .map(e -> new StatsDtos.TopBook(e.getKey(), e.getValue()))
                .toList();

        return new StatsDtos.ReportSummary(todaysIssues, todaysReturns, overdue, fineCollection, mostBorrowed, activeStudents);
    }

    /** Powers the "Export PDF" button on the Reports screen. */
    public byte[] exportPdf() {
        StatsDtos.ReportSummary summary = getSummary();
        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {

            Document doc = new Document();
            PdfWriter.getInstance(doc, out);
            doc.open();

            com.lowagie.text.Font titleFont =
                    FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18);

            com.lowagie.text.Font labelFont =
                    FontFactory.getFont(FontFactory.HELVETICA_BOLD, 11);

            doc.add(new Paragraph("LibTrack — Library Report", titleFont));
            doc.add(new Paragraph("V V College of Engineering", labelFont));
            doc.add(new Paragraph("Generated on: " + LocalDate.now()));
            doc.add(new Paragraph(" "));

            PdfPTable table = new PdfPTable(2);
            table.setWidthPercentage(100);

            addRow(table, "Today's Issues", String.valueOf(summary.todaysIssues()));
            addRow(table, "Today's Returns", String.valueOf(summary.todaysReturns()));
            addRow(table, "Overdue Books", String.valueOf(summary.overdueBooks()));
            addRow(table, "Fine Collection", "₹" + summary.fineCollection());
            addRow(table, "Active Students", String.valueOf(summary.activeStudents()));

            doc.add(table);

            doc.add(new Paragraph(" "));
            doc.add(new Paragraph("Most Borrowed Books", labelFont));

            PdfPTable topTable = new PdfPTable(2);
            topTable.setWidthPercentage(100);

            addRow(topTable, "Title", "Borrow Count");

            for (var book : summary.mostBorrowedBooks()) {
                addRow(topTable, book.title(), String.valueOf(book.borrowCount()));
            }

            doc.add(topTable);

            doc.close();
            return out.toByteArray();

        } catch (Exception e) {
            throw new RuntimeException("Failed to generate PDF report", e);
        }
    }

    /** Powers the "Export Excel" button on the Reports screen. */
    public byte[] exportExcel() {

        StatsDtos.ReportSummary summary = getSummary();

        try (Workbook workbook = new XSSFWorkbook();
             ByteArrayOutputStream out = new ByteArrayOutputStream()) {

            Sheet sheet = workbook.createSheet("Library Report");

            CellStyle headerStyle = workbook.createCellStyle();

            org.apache.poi.ss.usermodel.Font headerFont = workbook.createFont();
            headerFont.setBold(true);

            headerStyle.setFont(headerFont);

            int rowIdx = 0;

            Row header = sheet.createRow(rowIdx++);
            header.createCell(0).setCellValue("Metric");
            header.createCell(1).setCellValue("Value");

            header.getCell(0).setCellStyle(headerStyle);
            header.getCell(1).setCellStyle(headerStyle);

            rowIdx = writeRow(sheet, rowIdx, "Today's Issues", summary.todaysIssues());
            rowIdx = writeRow(sheet, rowIdx, "Today's Returns", summary.todaysReturns());
            rowIdx = writeRow(sheet, rowIdx, "Overdue Books", summary.overdueBooks());
            rowIdx = writeRow(sheet, rowIdx, "Fine Collection (₹)", summary.fineCollection());
            rowIdx = writeRow(sheet, rowIdx, "Active Students", summary.activeStudents());

            rowIdx++;

            Row topHeader = sheet.createRow(rowIdx++);
            topHeader.createCell(0).setCellValue("Most Borrowed Book");
            topHeader.createCell(1).setCellValue("Borrow Count");

            topHeader.getCell(0).setCellStyle(headerStyle);
            topHeader.getCell(1).setCellStyle(headerStyle);

            for (var book : summary.mostBorrowedBooks()) {
                rowIdx = writeRow(sheet, rowIdx, book.title(), book.borrowCount());
            }

            sheet.autoSizeColumn(0);
            sheet.autoSizeColumn(1);

            workbook.write(out);

            return out.toByteArray();

        } catch (Exception e) {
            throw new RuntimeException("Failed to generate Excel report", e);
        }
    }

    private void addRow(PdfPTable table, String label, String value) {
        table.addCell(new PdfPCell(new com.lowagie.text.Phrase(label)));
        table.addCell(new PdfPCell(new com.lowagie.text.Phrase(value)));
    }

    private int writeRow(Sheet sheet, int rowIdx, String label, double value) {
        Row row = sheet.createRow(rowIdx);
        row.createCell(0).setCellValue(label);
        row.createCell(1).setCellValue(value);
        return rowIdx + 1;
    }
}
