package com.gymapp.service.impl;

import com.gymapp.dto.CouponDTO;
import com.gymapp.entity.Coupon;
import com.gymapp.mapper.EntityMapper;
import com.gymapp.repository.CouponRepository;
import com.gymapp.service.CouponService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class CouponServiceImpl implements CouponService {

    private final CouponRepository couponRepository;
    private final EntityMapper mapper;

    @Override
    public CouponDTO createCoupon(CouponDTO dto) {
        log.info("Creating coupon: {}", dto.getCode());
        if (couponRepository.existsByCode(dto.getCode())) {
            throw new IllegalStateException("Coupon code already exists");
        }

        Coupon coupon = Coupon.builder()
                .code(dto.getCode().toUpperCase())
                .discountPercentage(dto.getDiscountPercentage())
                .validFrom(dto.getValidFrom())
                .validUntil(dto.getValidUntil())
                .maxUses(dto.getMaxUses())
                .currentUses(0)
                .active(true)
                .build();

        return mapper.toCouponDTO(couponRepository.save(coupon));
    }

    @Override
    @Transactional(readOnly = true)
    public CouponDTO getCouponById(Long id) {
        return mapper.toCouponDTO(couponRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Coupon not found")));
    }

    @Override
    @Transactional(readOnly = true)
    public CouponDTO getCouponByCode(String code) {
        return mapper.toCouponDTO(couponRepository.findByCode(code)
                .orElseThrow(() -> new EntityNotFoundException("Coupon not found with code: " + code)));
    }

    @Override
    @Transactional(readOnly = true)
    public List<CouponDTO> getActiveCoupons() {
        return couponRepository.findByActiveTrue().stream()
                .map(mapper::toCouponDTO).collect(Collectors.toList());
    }

    @Override
    public CouponDTO updateCoupon(Long id, CouponDTO dto) {
        Coupon coupon = couponRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Coupon not found"));

        if (dto.getDiscountPercentage() != null)
            coupon.setDiscountPercentage(dto.getDiscountPercentage());
        if (dto.getValidFrom() != null)
            coupon.setValidFrom(dto.getValidFrom());
        if (dto.getValidUntil() != null)
            coupon.setValidUntil(dto.getValidUntil());
        if (dto.getMaxUses() != null)
            coupon.setMaxUses(dto.getMaxUses());
        if (dto.getActive() != null)
            coupon.setActive(dto.getActive());

        return mapper.toCouponDTO(couponRepository.save(coupon));
    }

    @Override
    public void deleteCoupon(Long id) {
        if (!couponRepository.existsById(id))
            throw new EntityNotFoundException("Coupon not found");
        couponRepository.deleteById(id);
    }

    @Override
    @Transactional(readOnly = true)
    public CouponDTO validateCoupon(String code) {
        Coupon coupon = couponRepository.findByCode(code)
                .orElseThrow(() -> new EntityNotFoundException("Invalid coupon code"));

        if (!coupon.getActive())
            throw new IllegalStateException("Coupon is not active");
        if (coupon.getValidUntil().isBefore(LocalDate.now()))
            throw new IllegalStateException("Coupon has expired");
        if (coupon.getMaxUses() != null && coupon.getCurrentUses() >= coupon.getMaxUses()) {
            throw new IllegalStateException("Coupon usage limit reached");
        }

        return mapper.toCouponDTO(coupon);
    }
}
