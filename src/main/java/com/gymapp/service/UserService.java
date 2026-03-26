package com.gymapp.service;

import com.gymapp.dto.UserDTO;
import com.gymapp.dto.UserUpdateDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface UserService {

    UserDTO getUserById(Long id);

    UserDTO getUserByEmail(String email);

    Page<UserDTO> getAllUsers(Pageable pageable);

    UserDTO updateUser(Long id, UserUpdateDTO updateDTO);

    void deleteUser(Long id);

    void toggleUserStatus(Long id, boolean enabled);
}
