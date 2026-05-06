package com.gymapp.service.impl;

import com.gymapp.dto.UserDTO;
import com.gymapp.dto.UserUpdateDTO;
import com.gymapp.entity.User;
import com.gymapp.mapper.EntityMapper;
import com.gymapp.repository.UserRepository;
import com.gymapp.service.UserService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final EntityMapper mapper;

    @Override
    @Transactional(readOnly = true)
    public UserDTO getUserById(Long id) {
        log.debug("Fetching user with id: {}", id);
        User user = userRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("User not found with id: " + id));
        return mapper.toUserDTO(user);
    }

    @Override
    @Transactional(readOnly = true)
    public UserDTO getUserByEmail(String email) {
        log.debug("Fetching user with email: {}", email);
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new EntityNotFoundException("User not found with email: " + email));
        return mapper.toUserDTO(user);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<UserDTO> getAllUsers(Pageable pageable) {
        log.debug("Fetching all users, page: {}", pageable.getPageNumber());
        return userRepository.findAll(pageable).map(mapper::toUserDTO);
    }

    @Override
    public UserDTO updateUser(Long id, UserUpdateDTO updateDTO) {
        log.info("Updating user with id: {}", id);
        User user = userRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("User not found with id: " + id));

        if (updateDTO.getFirstName() != null)
            user.setFirstName(updateDTO.getFirstName());
        if (updateDTO.getLastName() != null)
            user.setLastName(updateDTO.getLastName());
        if (updateDTO.getEmail() != null)
            user.setEmail(updateDTO.getEmail());
        if (updateDTO.getPhone() != null)
            user.setPhone(updateDTO.getPhone());
        if (updateDTO.getAddress() != null)
            user.setAddress(updateDTO.getAddress());
        if (updateDTO.getDateOfBirth() != null)
            user.setDateOfBirth(updateDTO.getDateOfBirth());
        if (updateDTO.getGender() != null)
            user.setGender(updateDTO.getGender());
        if (updateDTO.getProfileImageUrl() != null)
            user.setProfileImageUrl(updateDTO.getProfileImageUrl());

        User saved = userRepository.save(user);
        log.info("User updated successfully: {}", saved.getId());
        return mapper.toUserDTO(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<UserDTO> getUsersByRole(String roleName, Pageable pageable) {
        log.debug("Fetching users with role: {}", roleName);
        return userRepository.findByRole(com.gymapp.entity.Role.valueOf(roleName), pageable).map(mapper::toUserDTO);
    }

    @Override
    public void deleteUser(Long id) {
        log.warn("Deleting user with id: {}", id);
        if (!userRepository.existsById(id)) {
            throw new EntityNotFoundException("User not found with id: " + id);
        }
        userRepository.deleteById(id);
        log.info("User deleted: {}", id);
    }

    @Override
    public void toggleUserStatus(Long id, boolean enabled) {
        log.info("Toggling user status for id: {} to {}", id, enabled);
        User user = userRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("User not found with id: " + id));
        user.setEnabled(enabled);
        userRepository.save(user);
    }
}
