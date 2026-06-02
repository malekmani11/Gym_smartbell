package com.gymapp.member.repository;

import com.gymapp.member.entity.QrCode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface QrCodeRepository extends JpaRepository<QrCode, Long> {

    Optional<QrCode> findByMachineId(Long machineId);

    Optional<QrCode> findByQrData(String qrData);

    Boolean existsByMachineId(Long machineId);
}
