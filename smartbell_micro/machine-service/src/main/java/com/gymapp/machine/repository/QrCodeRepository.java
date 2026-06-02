package com.gymapp.machine.repository;

import com.gymapp.machine.entity.QrCode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface QrCodeRepository extends JpaRepository<QrCode, Long> {

    Optional<QrCode> findByQrData(String qrData);

    Optional<QrCode> findByMachineId(Long machineId);
}
