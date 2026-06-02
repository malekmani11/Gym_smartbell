package com.gymapp.coach.mapper;

import com.gymapp.coach.dto.CoachDTO;
import com.gymapp.coach.dto.CourseDTO;
import com.gymapp.coach.dto.CourseReservationDTO;
import com.gymapp.coach.dto.ExerciseDTO;
import com.gymapp.coach.dto.TrainingProgramDTO;
import com.gymapp.coach.dto.TrainingProgramExerciseDTO;
import com.gymapp.coach.entity.Coach;
import com.gymapp.coach.entity.Course;
import com.gymapp.coach.entity.CourseReservation;
import com.gymapp.coach.entity.Exercise;
import com.gymapp.coach.entity.TrainingProgram;
import com.gymapp.coach.entity.TrainingProgramExercise;
import org.springframework.stereotype.Component;

import java.util.stream.Collectors;

@Component
public class EntityMapper {

    public CoachDTO toCoachDTO(Coach coach) {
        if (coach == null) return null;
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
                .ratingAvg(coach.getRatingAvg())
                .build();
    }

    public CourseDTO toCourseDTO(Course course) {
        if (course == null) return null;
        return CourseDTO.builder()
                .id(course.getId())
                .name(course.getName())
                .description(course.getDescription())
                .coachId(course.getCoach() != null ? course.getCoach().getId() : null)
                .coachName(course.getCoach() != null
                        ? course.getCoach().getFirstName() + " " + course.getCoach().getLastName() : null)
                .dayOfWeek(course.getDayOfWeek())
                .startTime(course.getStartTime())
                .endTime(course.getEndTime())
                .maxParticipants(course.getMaxParticipants())
                .location(course.getLocation())
                .salleId(course.getSalleId())
                .active(course.getActive())
                .currentParticipants(course.getReservations() != null ? course.getReservations().size() : 0)
                .build();
    }

    public CourseReservationDTO toCourseReservationDTO(CourseReservation reservation) {
        if (reservation == null) return null;
        return CourseReservationDTO.builder()
                .id(reservation.getId())
                .courseId(reservation.getCourse() != null ? reservation.getCourse().getId() : null)
                .courseName(reservation.getCourse() != null ? reservation.getCourse().getName() : null)
                .memberId(reservation.getMemberId())
                .reservationDate(reservation.getReservationDate())
                .status(reservation.getStatus())
                .createdAt(reservation.getCreatedAt())
                .build();
    }

    public ExerciseDTO toExerciseDTO(Exercise exercise) {
        if (exercise == null) return null;
        return ExerciseDTO.builder()
                .id(exercise.getId())
                .name(exercise.getName())
                .description(exercise.getDescription())
                .muscleGroup(exercise.getMuscleGroup())
                .difficultyLevel(exercise.getDifficultyLevel())
                .machineId(exercise.getMachineId())
                .imageUrl(exercise.getImageUrl())
                .build();
    }

    public TrainingProgramDTO toTrainingProgramDTO(TrainingProgram program) {
        if (program == null) return null;
        return TrainingProgramDTO.builder()
                .id(program.getId())
                .name(program.getName())
                .description(program.getDescription())
                .coachId(program.getCoach() != null ? program.getCoach().getId() : null)
                .coachName(program.getCoach() != null
                        ? program.getCoach().getFirstName() + " " + program.getCoach().getLastName() : null)
                .memberId(program.getMemberId())
                .startDate(program.getStartDate())
                .endDate(program.getEndDate())
                .status(program.getStatus())
                .createdAt(program.getCreatedAt())
                .exercises(program.getProgramExercises() != null
                        ? program.getProgramExercises().stream()
                                .map(this::toTrainingProgramExerciseDTO)
                                .collect(Collectors.toList())
                        : null)
                .build();
    }

    public TrainingProgramExerciseDTO toTrainingProgramExerciseDTO(TrainingProgramExercise tpe) {
        if (tpe == null) return null;
        return TrainingProgramExerciseDTO.builder()
                .id(tpe.getId())
                .exerciseId(tpe.getExercise() != null ? tpe.getExercise().getId() : null)
                .exerciseName(tpe.getExercise() != null ? tpe.getExercise().getName() : null)
                .sets(tpe.getSets())
                .reps(tpe.getReps())
                .restSeconds(tpe.getRestSeconds())
                .dayNumber(tpe.getDayNumber())
                .orderIndex(tpe.getOrderIndex())
                .build();
    }

}
