package com.gymapp.member.service.impl;

import com.gymapp.member.dto.ChangePasswordDTO;
import com.gymapp.member.dto.UserDTO;
import com.gymapp.member.dto.UserUpdateDTO;
import com.gymapp.member.entity.Role;
import com.gymapp.member.entity.User;
import com.gymapp.member.mapper.EntityMapper;
import com.gymapp.member.repository.UserRepository;
import com.gymapp.member.service.UserService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class UserServiceImpl implements UserService {

    private final UserRepository  userRepository;
    private final EntityMapper    mapper;
    private final PasswordEncoder passwordEncoder;

    @Override
    @Transactional(readOnly = true)
    public UserDTO getUserById(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("User not found with id: " + id));
        return mapper.toUserDTO(user);
    }

    @Override
    @Transactional(readOnly = true)
    public UserDTO getUserByEmail(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new EntityNotFoundException("User not found with email: " + email));
        return mapper.toUserDTO(user);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<UserDTO> getAllUsers(Pageable pageable) {
        return userRepository.findAll(pageable).map(mapper::toUserDTO);
    }

    @Override
    public UserDTO updateUser(Long id, UserUpdateDTO updateDTO) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("User not found with id: " + id));

        if (updateDTO.getFirstName() != null)      user.setFirstName(updateDTO.getFirstName());
        if (updateDTO.getLastName() != null)       user.setLastName(updateDTO.getLastName());
        if (updateDTO.getEmail() != null)          user.setEmail(updateDTO.getEmail());
        if (updateDTO.getPhone() != null)          user.setPhone(updateDTO.getPhone());
        if (updateDTO.getAddress() != null)        user.setAddress(updateDTO.getAddress());
        if (updateDTO.getDateOfBirth() != null)    user.setDateOfBirth(updateDTO.getDateOfBirth());
        if (updateDTO.getGender() != null)         user.setGender(updateDTO.getGender());
        if (updateDTO.getProfileImageUrl() != null) user.setProfileImageUrl(updateDTO.getProfileImageUrl());

        return mapper.toUserDTO(userRepository.save(user));
    }

    @Override
    @Transactional(readOnly = true)
    public Page<UserDTO> getUsersByRole(String roleName, Pageable pageable) {
        return userRepository.findByRole(Role.valueOf(roleName), pageable).map(mapper::toUserDTO);
    }

    @Override
    public void changePassword(Long id, ChangePasswordDTO dto) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("User not found with id: " + id));
        if (!passwordEncoder.matches(dto.getCurrentPassword(), user.getPassword())) {
            throw new IllegalArgumentException("Mot de passe actuel incorrect");
        }
        user.setPassword(passwordEncoder.encode(dto.getNewPassword()));
    }

    @Override
    public void deleteUser(Long id) {
        if (!userRepository.existsById(id)) {
            throw new EntityNotFoundException("User not found with id: " + id);
        }
        userRepository.deleteById(id);
    }

    @Override
    public void toggleUserStatus(Long id, boolean enabled) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("User not found with id: " + id));
        user.setEnabled(enabled);
        userRepository.save(user);
    }
}
