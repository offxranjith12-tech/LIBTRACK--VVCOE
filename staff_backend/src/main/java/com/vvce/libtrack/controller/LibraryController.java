package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.LibraryDtos;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** Backs the new Library Timings screen (Profile -> Settings -> Library Timings). */
@RestController
@RequestMapping("/api/library")
public class LibraryController {

    @GetMapping("/timings")
    public LibraryDtos.LibraryTimings getTimings() {
        return new LibraryDtos.LibraryTimings(
                List.of(
                        new LibraryDtos.DaySchedule("Monday", "9:00 AM - 6:00 PM", false),
                        new LibraryDtos.DaySchedule("Tuesday", "9:00 AM - 6:00 PM", false),
                        new LibraryDtos.DaySchedule("Wednesday", "9:00 AM - 6:00 PM", false),
                        new LibraryDtos.DaySchedule("Thursday", "9:00 AM - 6:00 PM", false),
                        new LibraryDtos.DaySchedule("Friday", "9:00 AM - 6:00 PM", false),
                        new LibraryDtos.DaySchedule("Saturday", "9:00 AM - 1:00 PM", false),
                        new LibraryDtos.DaySchedule("Sunday", "Closed", true)
                ),
                "Extended hours during exam weeks - check the noticeboard for updates."
        );
    }

    @GetMapping("/rules")
    public LibraryDtos.LibraryRules getRules() {
        return new LibraryDtos.LibraryRules(
                "VVCE Central Library Rules & Regulations",
                "Academic Year 2025-2026",
                List.of(
                        new LibraryDtos.RuleSection("1. General Code of Conduct", List.of(
                                "Silence must be strictly maintained inside the library premises.",
                                "Identity cards must be produced upon entering the library and on demand.",
                                "Mobile phones must be kept on silent mode inside reading halls.",
                                "Personal belongings except notebook/paper are not permitted inside reading areas."
                        )),
                        new LibraryDtos.RuleSection("2. Borrowing Policy & Loan Period", List.of(
                                "Faculty/Staff members may borrow up to 5 books at a time.",
                                "General loan duration for staff is 30 days, extendable if no reservation queue exists.",
                                "Reference books, rare manuscripts, and periodicals are strictly for in-library reference only.",
                                "Borrowed books cannot be transferred to another individual."
                        )),
                        new LibraryDtos.RuleSection("3. Overdue Fines & Return Policy", List.of(
                                "Late returns attract a fine of ₹5 per book per overdue day.",
                                "Loss or damage to borrowed books must be reported immediately to the Librarian.",
                                "Damaged or lost books must be replaced with the latest edition or paid for at double the market price."
                        )),
                        new LibraryDtos.RuleSection("4. Digital Library & Computer Lab Access", List.of(
                                "Digital Library systems are reserved strictly for academic and research reference.",
                                "Downloading unauthorized software, games, or streaming non-academic videos is strictly prohibited.",
                                "Print/Scan facilities are available at nominal charges at the library counter."
                        ))
                )
        );
    }
}
