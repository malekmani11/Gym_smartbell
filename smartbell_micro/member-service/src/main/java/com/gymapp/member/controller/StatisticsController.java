package com.gymapp.member.controller;

import com.gymapp.member.dto.StatisticsDTO;
import com.gymapp.member.service.StatisticsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/statistics")
@RequiredArgsConstructor
public class StatisticsController {

    private final StatisticsService statisticsService;

    @GetMapping
    public ResponseEntity<StatisticsDTO> getGymStatistics() {
        return ResponseEntity.ok(statisticsService.getGymStatistics());
    }
}
