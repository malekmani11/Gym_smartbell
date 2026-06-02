package com.gymapp.nutrition.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.List;
import java.util.Map;

@Service
public class ClaudeAiService {

    @Value("${anthropic.api.key:}")
    private String apiKey;

    private static final String CLAUDE_API_URL = "https://api.anthropic.com/v1/messages";
    private static final String MODEL = "claude-3-5-sonnet-20240620"; // Updated to a real current model name

    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    public ClaudeAiService(WebClient.Builder builder, ObjectMapper objectMapper) {
        this.webClient = builder.build();
        this.objectMapper = objectMapper;
    }

    // ──────────────────────────────────────────────────────
    //  1. Générer un programme d'entraînement
    // ──────────────────────────────────────────────────────
    public String generateTrainingProgram(
            String prenom, String nom, int age,
            double poids, double taille,
            String niveau, String objectif, int jours) {

        String prompt = """
            Tu es un coach sportif professionnel certifié.
            Génère un programme d'entraînement personnalisé en JSON pour :

            Profil de l'adhérent :
            - Nom : %s %s
            - Âge : %d ans
            - Poids : %.1f kg
            - Taille : %.0f cm
            - Niveau : %s (débutant / intermédiaire / avancé)
            - Objectif : %s (perte_de_poids / prise_de_masse / endurance / remise_en_forme)
            - Jours disponibles : %d jours par semaine

            Réponds UNIQUEMENT avec ce JSON (sans texte autour) :
            {
              "programme": {
                "titre": "...",
                "duree_semaines": 8,
                "seances_par_semaine": %d,
                "planning": [
                  {
                    "jour": "Lundi",
                    "type": "Musculation",
                    "duree_minutes": 60,
                    "exercices": [
                      {
                        "nom": "...",
                        "series": 4,
                        "repetitions": "12-15",
                        "repos_secondes": 60,
                        "conseil": "..."
                      }
                    ]
                  }
                ],
                "conseils_generaux": ["...", "...", "..."]
              }
            }
            """.formatted(prenom, nom, age, poids, taille, niveau, objectif, jours, jours);

        return callClaude(prompt);
    }

    // ──────────────────────────────────────────────────────
    //  2. Générer un plan nutritionnel
    // ──────────────────────────────────────────────────────
    public String generateNutritionPlan(
            String prenom, String nom, int age,
            double poids, double taille,
            String objectif, String allergies, int joursSport) {

        String prompt = """
            Tu es un nutritionniste sportif diplômé.
            Crée un plan nutritionnel complet pour :

            Profil :
            - Nom : %s %s
            - Âge : %d ans
            - Poids : %.1f kg
            - Taille : %.0f cm
            - Objectif : %s (perte_de_poids / prise_de_masse / maintien)
            - Allergies : %s
            - Activité physique : %d jours/semaine

            Réponds UNIQUEMENT avec ce JSON :
            {
              "nutrition": {
                "calories_journalieres": 0,
                "macros": {
                  "proteines_g": 0,
                  "glucides_g": 0,
                  "lipides_g": 0
                },
                "repas": {
                  "petit_dejeuner": { "description": "...", "aliments": ["..."], "calories": 0 },
                  "collation_matin": { "description": "...", "aliments": ["..."], "calories": 0 },
                  "dejeuner": { "description": "...", "aliments": ["..."], "calories": 0 },
                  "collation_apres_midi": { "description": "...", "aliments": ["..."], "calories": 0 },
                  "diner": { "description": "...", "aliments": ["..."], "calories": 0 }
                },
                "aliments_a_eviter": ["..."],
                "conseils": ["...", "...", "..."],
                "hydratation_litres": 2.5
              }
            }
            """.formatted(prenom, nom, age, poids, taille, objectif, allergies, joursSport);

        return callClaude(prompt);
    }

    // ──────────────────────────────────────────────────────
    //  3. Analyser les stats du dashboard admin
    // ──────────────────────────────────────────────────────
    public String analyzeDashboardStats(
            int membresActifs, int nouveauxMembres,
            int membresInactifs, double revenu,
            int seances, int reservations, double tauxRetention) {

        String prompt = """
            Tu es un consultant business spécialisé dans les salles de sport.
            Analyse ces données de SmartBell Gym et donne des recommandations :

            Statistiques du mois :
            - Membres actifs : %d
            - Nouveaux inscrits : %d
            - Membres inactifs : %d
            - Revenu total : %.2f DT
            - Séances effectuées : %d
            - Réservations cours : %d
            - Taux de rétention : %.1f%%

            Réponds UNIQUEMENT avec ce JSON :
            {
              "analyse": {
                "resume": "...",
                "points_positifs": ["...", "..."],
                "points_a_ameliorer": ["...", "..."],
                "recommandations": [
                  { "priorite": "haute", "action": "...", "impact_estime": "..." }
                ],
                "objectifs_mois_prochain": {
                  "membres_cible": 0,
                  "revenu_cible": 0,
                  "taux_retention_cible": 0
                }
              }
            }
            """.formatted(membresActifs, nouveauxMembres, membresInactifs,
                          revenu, seances, reservations, tauxRetention);

        return callClaude(prompt);
    }

    // ──────────────────────────────────────────────────────
    //  4. Générer une notification personnalisée
    // ──────────────────────────────────────────────────────
    public String generateNotification(
            String typeNotification, String cible, String sujet) {

        String prompt = """
            Tu es un expert en communication et marketing sportif.
            Rédige un message de notification pour SmartBell Gym.

            Contexte :
            - Type : %s (promo / rappel / motivation / réactivation)
            - Cible : %s (tous / membres_inactifs / abonnements_expirant / nouveaux)
            - Sujet : %s
            - Ton : professionnel mais chaleureux

            Réponds UNIQUEMENT avec ce JSON :
            {
              "notification": {
                "titre": "...",
                "message_court": "...(max 80 caractères)",
                "message_long": "...",
                "call_to_action": "...",
                "emoji": "..."
              }
            }
            """.formatted(typeNotification, cible, sujet);

        return callClaude(prompt);
    }

    // ──────────────────────────────────────────────────────
    //  5. Recommander des cours pour un adhérent
    // ──────────────────────────────────────────────────────
    public String recommendCourses(
            String niveau, String objectif,
            String joursDisponibles, String coursSuivis,
            String listeCours) {

        String prompt = """
            Tu es un conseiller sportif de SmartBell Gym.
            Recommande des cours collectifs adaptés à cet adhérent :

            Profil adhérent :
            - Niveau : %s
            - Objectif : %s
            - Disponibilités : %s
            - Cours déjà suivis : %s

            Cours disponibles dans la salle :
            %s

            Réponds UNIQUEMENT avec ce JSON :
            {
              "recommandations": [
                {
                  "cours": "...",
                  "raison": "...",
                  "benefices": ["...", "..."],
                  "frequence_conseillee": "2 fois par semaine",
                  "niveau_requis": "débutant"
                }
              ],
              "message_personnalise": "..."
            }
            """.formatted(niveau, objectif, joursDisponibles, coursSuivis, listeCours);

        return callClaude(prompt);
    }

    // ──────────────────────────────────────────────────────
    //  6. Évaluer la progression d'un adhérent
    // ──────────────────────────────────────────────────────
    public String evaluateProgression(
            String prenom, String objectif,
            double poidsInitial, double poidsActuel,
            int seancesMois, int seancesObjectif) {

        String prompt = """
            Tu es un coach sportif de SmartBell Gym.
            Évalue la progression de cet adhérent et motive-le :

            Données de progression :
            - Prénom : %s
            - Objectif initial : %s
            - Poids initial : %.1f kg → Poids actuel : %.1f kg
            - Séances effectuées ce mois : %d / %d prévues
            - Évolution poids : %.1f kg

            Réponds UNIQUEMENT avec ce JSON :
            {
              "evaluation": {
                "score_progression": 0,
                "message_motivation": "...",
                "points_forts": ["...", "..."],
                "axes_amelioration": ["...", "..."],
                "objectif_prochain_mois": "...",
                "badge_merite": "...",
                "points_fidelite_suggeres": 0
              }
            }
            """.formatted(prenom, objectif, poidsInitial, poidsActuel,
                          seancesMois, seancesObjectif, poidsActuel - poidsInitial);

        return callClaude(prompt);
    }

    // ──────────────────────────────────────────────────────
    //  7. Générer le contenu d'un rapport mensuel
    // ──────────────────────────────────────────────────────
    public String generateMonthlyReport(
            String mois, int annee,
            int nouveaux, int departs,
            double revenuAbonnements, double revenuCours,
            String topCours, String topCoach, int satisfaction) {

        double revenuTotal = revenuAbonnements + revenuCours;

        String prompt = """
            Tu es un assistant administratif de SmartBell Gym.
            Génère le contenu d'un rapport mensuel professionnel.

            Données du mois de %s %d :
            - Nouveaux membres : %d
            - Membres ayant quitté : %d
            - Revenu abonnements : %.2f DT
            - Revenu cours : %.2f DT
            - Revenu total : %.2f DT
            - Cours les plus populaires : %s
            - Coach le mieux noté : %s
            - Taux de satisfaction : %d%%

            Réponds UNIQUEMENT avec ce JSON :
            {
              "rapport": {
                "titre": "Rapport Mensuel SmartBell Gym — %s %d",
                "resume_executif": "...",
                "faits_marquants": ["...", "...", "..."],
                "analyse_financiere": "...",
                "analyse_membres": "...",
                "recommandations_strategiques": ["...", "...", "..."],
                "conclusion": "..."
              }
            }
            """.formatted(mois, annee, nouveaux, departs,
                          revenuAbonnements, revenuCours, revenuTotal,
                          topCours, topCoach, satisfaction, mois, annee);

        return callClaude(prompt);
    }

    // ──────────────────────────────────────────────────────
    //  8. Chatbot assistant SmartBell Gym
    // ──────────────────────────────────────────────────────
    public String chatbotResponse(
            String prenom, String nom,
            String typeAbonnement, int points,
            int nombreCoachs, String question) {

        String prompt = """
            Tu es l'assistant virtuel de SmartBell Gym, une salle de sport moderne.
            Tu aides les adhérents et les visiteurs avec leurs questions.

            Informations sur la salle :
            - Nom : SmartBell Gym
            - Horaires : 6h-23h tous les jours
            - Abonnements : Mensuel (80 DT), Trimestriel (200 DT), Annuel (700 DT)
            - Services : Musculation, Cardio, Cours collectifs, Coaching, Nutrition
            - Équipe : %d coachs certifiés

            Profil du membre connecté :
            - Nom : %s %s
            - Abonnement : %s
            - Points fidélité : %d

            Question de l'adhérent : %s

            Réponds de façon naturelle, chaleureuse et utile en français.
            Si tu ne sais pas, propose de contacter la réception.
            """.formatted(nombreCoachs, prenom, nom, typeAbonnement, points, question);

        return callClaude(prompt);
    }

    // ──────────────────────────────────────────────────────
    //  Méthode privée : appel à l'API Claude
    // ──────────────────────────────────────────────────────
    private String callClaude(String userPrompt) {
        try {
            var requestBody = Map.of(
                "model", MODEL,
                "max_tokens", 1500,
                "messages", List.of(
                    Map.of("role", "user", "content", userPrompt)
                )
            );

            var response = webClient.post()
                .uri(CLAUDE_API_URL)
                .header("x-api-key", apiKey)
                .header("anthropic-version", "2023-06-01")
                .header("Content-Type", "application/json")
                .bodyValue(requestBody)
                .retrieve()
                .bodyToMono(Map.class)
                .block();

            if (response == null || !response.containsKey("content")) {
                return "{\"error\": \"Réponse invalide de l'API Claude\"}";
            }

            // Extraire le texte de la réponse
            var content = (List<?>) response.get("content");
            var firstBlock = (Map<?, ?>) content.get(0);
            return (String) firstBlock.get("text");

        } catch (Exception e) {
            return "{\"error\": \"Erreur Claude API : " + e.getMessage() + "\"}";
        }
    }
}
