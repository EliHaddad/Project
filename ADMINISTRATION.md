# Administration de l’équipe

Préparée le 8 octobre 2026 pour le schéma historique audité, pas pour les tables yi_*.

Le compte initial choisi et vérifié dans auth.users devient le premier administrateur. Les rôles de sécurité sont stockés dans crm_members. Le champ historique profiles.role et les métadonnées modifiables par un utilisateur ne donnent aucun droit administrateur.

L’administrateur accède à Administration depuis la barre du compte connecté. Il voit les membres, filtre les prospects par responsable et attribue une sélection à un membre actif. L’attribution met également à jour les rendez-vous et tâches liés, dans une transaction. Les employés voient leurs propres prospects et le suivi lié. Projets et appartements sont consultables par l’équipe, modifiables par l’administrateur. Les conditions de paiement restent personnelles, avec accès global administrateur. Les dossiers non attribués sont réservés à l’administrateur.

## Activation

1. Déployer les fichiers de l’application.
2. Appliquer supabase/migrations/202610080001_team_access.sql après validation humaine des nouveaux droits. Juste après BEGIN, ajouter `SET LOCAL crm.bootstrap_email = 'adresse du compte initial';` en remplaçant cette valeur par l’adresse vérifiée. Le script remplace les politiques permissives existantes, active RLS et conserve tous les dossiers.
3. Exécuter supabase/tests/team_access.sql. Il vérifie isolation, accès administrateur, interdiction d’auto-promotion, réattribution et compte inactif. Tous les comptes et dossiers fictifs sont annulés par ROLLBACK.
4. Dans Vercel, enregistrer SUPABASE_SERVICE_ROLE_KEY comme Secret, côté serveur uniquement, sans préfixe NEXT_PUBLIC_. Ne jamais la coller dans une conversation, un fichier versionné ou le navigateur client. Redéployer.
5. Autoriser https://crm-immo-yonathan.vercel.app/fr, /he et /en dans Authentication > URL Configuration > Redirect URLs. Vérifier le service SMTP avant les invitations aux employés réels.

L’API vérifie l’identité Supabase puis la membership administrateur active avant toute utilisation de la clé serveur. Elle invite uniquement des employés. Cliquer sur « Inviter un employé » envoie un e-mail à l’adresse saisie. Le lien ouvre le choix de mot de passe dans le CRM. Aucun mot de passe n’est créé ou envoyé par l’administrateur.

Une invitation dont le provisionnement échoue reste sans accès CRM. Corriger le profil/membership via Supabase avant de renvoyer une invitation. Les invitations sont soumises aux limites et restrictions SMTP du projet. Aucun compte Jonathan/Shmuel/Shimon/Arye n’est créé sans adresse e-mail fournie.

## Vérifications restantes

La compilation locale réussit. Les tests RLS doivent être exécutés sur Supabase après activation. Tester une invitation réelle avec l’accord de son destinataire, son lien, le choix du mot de passe et la reconnexion. La rubrique ne gère pas encore désactivation/révocation ou promotion d’autres administrateurs : ces actions restent dans Supabase. Les éventuels fichiers privés du stockage Supabase ne sont pas utilisés par cette rubrique ; leurs politiques doivent être auditées avant d’y déposer des documents clients.
