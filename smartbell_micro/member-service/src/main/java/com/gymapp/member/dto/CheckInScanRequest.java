package com.gymapp.member.dto;

import lombok.Data;

@Data
public class CheckInScanRequest {
    private Long memberId;
    private String qrCode;
}
