package com.vvce.libtrack.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BulkImportResponse {
    private int totalRows;
    private int importedCount;
    private int skippedCount;
    private long durationMs;
    private List<String> errors;
}
