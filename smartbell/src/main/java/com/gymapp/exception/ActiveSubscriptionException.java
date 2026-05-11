package com.gymapp.exception;

public class ActiveSubscriptionException extends RuntimeException {
    public ActiveSubscriptionException(String message) {
        super(message);
    }
}
