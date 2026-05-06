package com.gymapp.service;

import com.gymapp.dto.CrmMemberDTO;

import java.util.List;
import java.util.Map;

public interface CrmService {

    Map<String, List<CrmMemberDTO>> getPipeline();

    CrmMemberDTO updateStage(Long memberId, String stage);

    CrmMemberDTO addNote(Long memberId, String note);
}
