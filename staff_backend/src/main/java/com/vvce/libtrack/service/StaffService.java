package com.vvce.libtrack.service;

import com.vvce.libtrack.dto.StaffDto;
import com.vvce.libtrack.entity.Staff;
import com.vvce.libtrack.exception.ResourceNotFoundException;
import com.vvce.libtrack.repository.StaffRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class StaffService {

    private final StaffRepository staffRepository;

    public StaffDto getProfile(String username) {
        return StaffDto.from(findByUsername(username));
    }

    public StaffDto updateProfile(String username, StaffDto update) {
        Staff staff = findByUsername(username);
        // Department, designation, and email are set once at registration
        // and are intentionally NOT accepted from this endpoint, even if a
        // client sends different values - only name, phone, address, and
        // photo can be changed here.
        staff.setName(update.name());
        staff.setPhone(update.phone());
        if (update.address() != null) staff.setAddress(update.address());
        if (update.photoUrl() != null) staff.setPhotoUrl(update.photoUrl());
        staffRepository.save(staff);
        return StaffDto.from(staff);
    }

    private Staff findByUsername(String username) {
        return staffRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("Staff not found: " + username));
    }
}
