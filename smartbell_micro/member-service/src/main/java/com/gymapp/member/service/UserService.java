package com.gymapp.member.service;

import com.gymapp.member.dto.ChangePasswordDTO;
import com.gymapp.member.dto.UserDTO;
import com.gymapp.member.dto.UserUpdateDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface UserService {

    UserDTO getUserById(Long id);

    UserDTO getUserByEmail(String email);

    Page<UserDTO> getAllUsers(Pageable pageable);

    Page<UserDTO> getUsersByRole(String roleName, Pageable pageable);

    UserDTO updateUser(Long id, UserUpdateDTO updateDTO);

    void changePassword(Long id, ChangePasswordDTO dto);

    void deleteUser(Long id);

    void toggleUserStatus(Long id, boolean enabled);
}
