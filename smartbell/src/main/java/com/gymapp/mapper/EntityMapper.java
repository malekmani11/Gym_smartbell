package com.gymapp.mapper;

import com.gymapp.dto.*;
import com.gymapp.entity.*;
import org.springframework.stereotype.Component;

import java.util.stream.Collectors;

@Component
public class EntityMapper {

    // ── User ───────────────────────────────────────────────

    public UserDTO toUserDTO(User user) {
        return UserDTO.builder()
                .id(user.getId())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .address(user.getAddress())
                .dateOfBirth(user.getDateOfBirth())
                .gender(user.getGender())
                .profileImageUrl(user.getProfileImageUrl())
                .enabled(user.getEnabled())
                .role(user.getRole().name())
                .createdAt(user.getCreatedAt())
                .build();
    }

    // ── Member ─────────────────────────────────────────────

    public MemberDTO toMemberDTO(Member member) {
        String activePlan = member.getSubscriptions().stream()
                .filter(s -> s.getStatus() == com.gymapp.entity.enums.SubscriptionStatus.ACTIVE)
                .findFirst()
                .map(s -> s.getPlan().getName())
                .orElse("Aucun");

        return MemberDTO.builder()
                .id(member.getId())
                .userId(member.getId())
                .firstName(member.getFirstName())
                .lastName(member.getLastName())
                .email(member.getEmail())
                .phone(member.getPhone())
                .address(member.getAddress())
                .dateOfBirth(member.getDateOfBirth())
                .gender(member.getGender() != null ? member.getGender().name() : null)
                .emergencyContact(member.getEmergencyContact())
                .emergencyPhone(member.getEmergencyPhone())
                .medicalNotes(member.getMedicalNotes())
                .membershipStatus(member.getMembershipStatus())
                .joinDate(member.getJoinDate())
                .planName(activePlan)
                .profileImageUrl(member.getProfileImageUrl())
                .build();
    }

    // ── Coach ──────────────────────────────────────────────

    public CoachDTO toCoachDTO(Coach coach) {
        return CoachDTO.builder()
                .id(coach.getId())
                .userId(coach.getId())
                .firstName(coach.getFirstName())
                .lastName(coach.getLastName())
                .email(coach.getEmail())
                .phone(coach.getPhone())
                .specialization(coach.getSpecialization())
                .bio(coach.getBio())
                .certification(coach.getCertification())
                .hireDate(coach.getHireDate())
                .availabilityStatus(coach.getAvailabilityStatus())
                .profileImageUrl(coach.getProfileImageUrl())
                .build();
    }

    // ── Subscription Plan ──────────────────────────────────

    public SubscriptionPlanDTO toSubscriptionPlanDTO(SubscriptionPlan plan) {
        return SubscriptionPlanDTO.builder()
                .id(plan.getId())
                .name(plan.getName())
                .description(plan.getDescription())
                .durationMonths(plan.getDurationMonths())
                .price(plan.getPrice())
                .active(plan.getActive())
                .createdAt(plan.getCreatedAt())
                .build();
    }

    // ── Subscription ───────────────────────────────────────

    public SubscriptionDTO toSubscriptionDTO(Subscription subscription) {
        SubscriptionDTO dto = SubscriptionDTO.builder()
                .id(subscription.getId())
                .userId(subscription.getUser().getId())
                .planId(subscription.getPlan().getId())
                .planName(subscription.getPlan().getName())
                .startDate(subscription.getStartDate())
                .endDate(subscription.getEndDate())
                .status(subscription.getStatus())
                .createdAt(subscription.getCreatedAt())
                .build();
        if (subscription.getCoupon() != null) {
            dto.setCouponId(subscription.getCoupon().getId());
            dto.setCouponCode(subscription.getCoupon().getCode());
        }
        return dto;
    }

    // ── Payment ────────────────────────────────────────────

    public PaymentDTO toPaymentDTO(Payment payment) {
        User member = payment.getSubscription().getUser();
        return PaymentDTO.builder()
                .id(payment.getId())
                .subscriptionId(payment.getSubscription().getId())
                .amount(payment.getAmount())
                .paymentDate(payment.getPaymentDate())
                .paymentMethod(payment.getPaymentMethod())
                .status(payment.getStatus())
                .transactionRef(payment.getTransactionRef())
                .memberName(member.getFirstName() + " " + member.getLastName())
                .memberEmail(member.getEmail())
                .build();
    }

    // ── Coupon ─────────────────────────────────────────────

    public CouponDTO toCouponDTO(Coupon coupon) {
        return CouponDTO.builder()
                .id(coupon.getId())
                .code(coupon.getCode())
                .discountPercentage(coupon.getDiscountPercentage())
                .validFrom(coupon.getValidFrom())
                .validUntil(coupon.getValidUntil())
                .maxUses(coupon.getMaxUses())
                .currentUses(coupon.getCurrentUses())
                .active(coupon.getActive())
                .build();
    }

    // ── Course ─────────────────────────────────────────────

    public CourseDTO toCourseDTO(Course course) {
        Coach coach = course.getCoach();
        Salle salle = course.getSalle();
        return CourseDTO.builder()
                .id(course.getId())
                .name(course.getName())
                .description(course.getDescription())
                .coachId(coach.getId())
                .coachName(coach.getFirstName() + " " + coach.getLastName())
                .dayOfWeek(course.getDayOfWeek())
                .startTime(course.getStartTime())
                .endTime(course.getEndTime())
                .maxParticipants(course.getMaxParticipants())
                .location(course.getLocation())
                .active(course.getActive())
                .salleId(salle != null ? salle.getId() : null)
                .salleName(salle != null ? salle.getName() : null)
                .build();
    }

    // ── Course Reservation ─────────────────────────────────

    public CourseReservationDTO toCourseReservationDTO(CourseReservation reservation) {
        Member member = reservation.getMember();
        return CourseReservationDTO.builder()
                .id(reservation.getId())
                .courseId(reservation.getCourse().getId())
                .courseName(reservation.getCourse().getName())
                .memberId(member.getId())
                .memberName(member.getFirstName() + " " + member.getLastName())
                .reservationDate(reservation.getReservationDate())
                .status(reservation.getStatus())
                .createdAt(reservation.getCreatedAt())
                .build();
    }

    // ── Event ──────────────────────────────────────────────

    public EventDTO toEventDTO(Event event) {
        return EventDTO.builder()
                .id(event.getId())
                .title(event.getTitle())
                .description(event.getDescription())
                .createdById(event.getCreatedBy().getId())
                .createdByName(event.getCreatedBy().getFirstName() + " " + event.getCreatedBy().getLastName())
                .eventDate(event.getEventDate())
                .endDate(event.getEndDate())
                .location(event.getLocation())
                .maxParticipants(event.getMaxParticipants())
                .imageUrl(event.getImageUrl())
                .active(event.getActive())
                .createdAt(event.getCreatedAt())
                .build();
    }

    // ── Event Registration ─────────────────────────────────

    public EventRegistrationDTO toEventRegistrationDTO(EventRegistration reg) {
        return EventRegistrationDTO.builder()
                .id(reg.getId())
                .eventId(reg.getEvent().getId())
                .eventTitle(reg.getEvent().getTitle())
                .userId(reg.getUser().getId())
                .userName(reg.getUser().getFirstName() + " " + reg.getUser().getLastName())
                .firstName(reg.getUser().getFirstName())
                .lastName(reg.getUser().getLastName())
                .email(reg.getUser().getEmail())
                .profileImageUrl(reg.getUser().getProfileImageUrl())
                .registrationDate(reg.getRegistrationDate())
                .status(reg.getStatus())
                .build();
    }

    // ── Training Program ───────────────────────────────────

    public TrainingProgramDTO toTrainingProgramDTO(TrainingProgram program) {
        Coach programCoach = program.getCoach();
        Member programMember = program.getMember();
        return TrainingProgramDTO.builder()
                .id(program.getId())
                .name(program.getName())
                .description(program.getDescription())
                .coachId(programCoach.getId())
                .coachName(programCoach.getFirstName() + " " + programCoach.getLastName())
                .memberId(programMember.getId())
                .memberName(programMember.getFirstName() + " " + programMember.getLastName())
                .startDate(program.getStartDate())
                .endDate(program.getEndDate())
                .status(program.getStatus())
                .createdAt(program.getCreatedAt())
                .exercises(program.getProgramExercises().stream()
                        .map(this::toTrainingProgramExerciseDTO)
                        .collect(Collectors.toList()))
                .build();
    }

    public TrainingProgramExerciseDTO toTrainingProgramExerciseDTO(TrainingProgramExercise tpe) {
        return TrainingProgramExerciseDTO.builder()
                .id(tpe.getId())
                .exerciseId(tpe.getExercise().getId())
                .exerciseName(tpe.getExercise().getName())
                .sets(tpe.getSets())
                .reps(tpe.getReps())
                .restSeconds(tpe.getRestSeconds())
                .dayNumber(tpe.getDayNumber())
                .orderIndex(tpe.getOrderIndex())
                .build();
    }

    // ── Exercise ───────────────────────────────────────────

    public ExerciseDTO toExerciseDTO(Exercise exercise) {
        ExerciseDTO dto = ExerciseDTO.builder()
                .id(exercise.getId())
                .name(exercise.getName())
                .description(exercise.getDescription())
                .muscleGroup(exercise.getMuscleGroup())
                .difficultyLevel(exercise.getDifficultyLevel())
                .imageUrl(exercise.getImageUrl())
                .build();
        if (exercise.getMachine() != null) {
            dto.setMachineId(exercise.getMachine().getId());
            dto.setMachineName(exercise.getMachine().getName());
        }
        return dto;
    }

    // ── Machine ────────────────────────────────────────────

    public MachineDTO toMachineDTO(Machine machine) {
        MachineDTO dto = MachineDTO.builder()
                .id(machine.getId())
                .name(machine.getName())
                .description(machine.getDescription())
                .location(machine.getLocation())
                .status(machine.getStatus())
                .imageUrl(machine.getImageUrl())
                .tutorialUrl(machine.getTutorialUrl())
                .build();
        if (machine.getQrCode() != null) {
            dto.setQrCodeData(machine.getQrCode().getQrData());
        }
        return dto;
    }

    // ── Nutrition Plan ─────────────────────────────────────

    public NutritionPlanDTO toNutritionPlanDTO(NutritionPlan plan) {
        Member planMember = plan.getMember();
        return NutritionPlanDTO.builder()
                .id(plan.getId())
                .title(plan.getTitle())
                .description(plan.getDescription())
                .createdById(plan.getCreatedBy().getId())
                .createdByName(plan.getCreatedBy().getFirstName() + " " + plan.getCreatedBy().getLastName())
                .memberId(planMember.getId())
                .memberName(planMember.getFirstName() + " " + planMember.getLastName())
                .startDate(plan.getStartDate())
                .endDate(plan.getEndDate())
                .goal(plan.getGoal())
                .status(plan.getStatus())
                .createdAt(plan.getCreatedAt())
                .meals(plan.getMeals().stream()
                        .map(this::toMealDTO)
                        .collect(Collectors.toList()))
                .build();
    }

    public MealDTO toMealDTO(Meal meal) {
        return MealDTO.builder()
                .id(meal.getId())
                .nutritionPlanId(meal.getNutritionPlan().getId())
                .name(meal.getName())
                .mealType(meal.getMealType())
                .dayNumber(meal.getDayNumber())
                .calories(meal.getCalories())
                .proteinGrams(meal.getProteinGrams())
                .carbsGrams(meal.getCarbsGrams())
                .fatGrams(meal.getFatGrams())
                .description(meal.getDescription())
                .build();
    }

    // ── Message ────────────────────────────────────────────

    public MessageDTO toMessageDTO(Message message) {
        return MessageDTO.builder()
                .id(message.getId())
                .senderId(message.getSender().getId())
                .senderName(message.getSender().getFirstName() + " " + message.getSender().getLastName())
                .receiverId(message.getReceiver().getId())
                .receiverName(message.getReceiver().getFirstName() + " " + message.getReceiver().getLastName())
                .content(message.getContent())
                .sentAt(message.getSentAt())
                .isRead(message.getIsRead())
                .build();
    }

    // ── Notification ───────────────────────────────────────

    public NotificationDTO toBroadcastDTO(NotificationBroadcast b, boolean isRead) {
        return NotificationDTO.builder()
                .id(b.getId())
                .title(b.getTitle())
                .message(b.getMessage())
                .type(b.getType())
                .isRead(isRead)
                .createdAt(b.getCreatedAt())
                .targetAll(b.getTargetAll())
                .targetRole(b.getTargetRole() != null ? b.getTargetRole().name() : null)
                .targetUserId(b.getTargetUserId())
                .build();
    }

    // ── Complaint ──────────────────────────────────────────

    public ComplaintDTO toComplaintDTO(Complaint complaint) {
        return ComplaintDTO.builder()
                .id(complaint.getId())
                .userId(complaint.getUser().getId())
                .firstName(complaint.getUser().getFirstName())
                .lastName(complaint.getUser().getLastName())
                .userName(complaint.getUser().getFirstName() + " " + complaint.getUser().getLastName())
                .subject(complaint.getSubject())
                .description(complaint.getDescription())
                .status(complaint.getStatus())
                .response(complaint.getResponse())
                .createdAt(complaint.getCreatedAt())
                .resolvedAt(complaint.getResolvedAt())
                .build();
    }

}
