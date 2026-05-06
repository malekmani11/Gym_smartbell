package com.gymapp.service;

import com.gymapp.dto.CouponDTO;
import java.util.List;

public interface CouponService {

    CouponDTO createCoupon(CouponDTO dto);

    CouponDTO getCouponById(Long id);

    CouponDTO getCouponByCode(String code);

    List<CouponDTO> getActiveCoupons();

    CouponDTO updateCoupon(Long id, CouponDTO dto);

    void deleteCoupon(Long id);

    CouponDTO validateCoupon(String code);
}
