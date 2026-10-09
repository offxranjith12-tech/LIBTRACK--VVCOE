package com.vvce.libtrack.dto;

import java.util.List;

public class LibraryDtos {

    public record DaySchedule(String day, String hours, boolean closed) {}

    public record LibraryTimings(List<DaySchedule> schedule, String note) {}

    public record RuleSection(String title, List<String> points) {}

    public record LibraryRules(String title, String version, List<RuleSection> sections) {}
}
