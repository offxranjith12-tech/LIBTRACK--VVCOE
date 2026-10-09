package com.vvce.libtrack.dto;

import java.util.List;

public class StatsDtos {

    public record DashboardStats(
            long borrowedBooks,
            long returnedBooks,
            long dueSoon,
            long reservedBooks,
            long issuedToday,
            long returnedToday,
            long pendingReturns,
            long activeBorrowers
    ) {}

    public record ReportSummary(
            long todaysIssues,
            long todaysReturns,
            long overdueBooks,
            double fineCollection,
            List<TopBook> mostBorrowedBooks,
            long activeStudents
    ) {}

    public record TopBook(String title, long borrowCount) {}
}
