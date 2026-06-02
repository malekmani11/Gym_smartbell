package com.gymapp.member.exception;

public class ActiveSubscriptionException extends RuntimeException {
    public ActiveSubscriptionException(String message) {
        super(message);
    }
}
