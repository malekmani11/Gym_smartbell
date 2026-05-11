package com.gymapp.entity.enums;

public enum LoyaltyTransactionType {
    EARN,         // Points gagnés (séance, événement, IA progression)
    REDEEM,       // Points utilisés (réduction sur abonnement)
    EXPIRE,       // Points expirés
    ADMIN_ADJUST  // Ajustement manuel par l'admin
}
