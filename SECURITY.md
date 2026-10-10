# Renforcement du CRM — 10 octobre 2026

## Changements
- Le bucket privé `documents` avait quatre politiques accordant lecture, ajout, modification et suppression à tout utilisateur authentifié. Ces politiques ont été remplacées : membre CRM actif, propriétaire du fichier ou administrateur uniquement. Les fichiers sans propriétaire restent accessibles uniquement à l'administrateur. Aucun fichier n'a été supprimé.
- `profiles` n'accorde plus de droits aux visiteurs anonymes ni d'écriture directe aux comptes employés. La création des profils reste effectuée par la route administrateur avec la clé serveur. Les rôles CRM restent dans `crm_members`.
- Suppression des droits d'exécution anonymes sur les fonctions publiques. Les fonctions CRM vérifiaient déjà les droits, mais Supabase avait conservé des droits `anon` explicites malgré la révocation de `PUBLIC`. Chemin de recherche verrouillé sur le déclencheur historique de création des profils.
- Double authentification TOTP, en FR/HE/EN, dans `/[locale]/security`. L'utilisateur active lui-même son application Authenticator. Les comptes déjà inscrits au TOTP doivent présenter un jeton `aal2` : contrôle de la base via `crm_active`/`crm_admin`, des API et de l'interface. Les comptes sans facteur vérifié restent utilisables ; le TOTP n'est pas encore obligatoire pour tous.
- Quotas PostgreSQL par compte, partagés entre instances Vercel : assistant 5 requêtes/minute et 100/24 h ; invitations 3/minute et 20/24 h. Un refus de la fenêtre minute peut également consommer un crédit de la fenêtre 24 h, choix conservateur. Les erreurs de quota bloquent la requête. Les quotas ne remplacent pas les plafonds de dépenses OpenAI.
- Les API privées vérifient le jeton avec `getUser`, le rôle/compte actif et le TOTP avant une opération externe. Corps JSON bornés pendant la lecture, y compris les requêtes sans Content-Length ; refus de null, tableaux et types incorrects.
- Les images publiques ne peuvent venir que du domaine et du répertoire prévus ; lecture arrêtée au-delà de 15 Mo, redirections refusées.
- En-têtes contre l'inclusion en iframe, les objets actifs et la détection erronée du type de contenu ; HTTPS/HSTS en production, absence de cache pour les API privées. La CSP est volontairement partielle : elle ne bloque pas tous les scripts inline.
- Audit des dépendances de production : une alerte modérée sur `uuid` via ExcelJS, corrigée par un override ciblé vers 11.1.1. Versions principales Next.js/React/ExcelJS conservées. Nouvel audit du verrou : aucune alerte connue au 10 octobre 2026. L'usage ExcelJS est `v4`, alors que l'alerte concerne `v3/v5/v6` avec buffers ; la correction est préventive ([avis officiel](https://github.com/advisories/GHSA-w5hq-g745-h8pq)).

Inscriptions publiques désactivées dans Supabase ; connexions anonymes déjà désactivées et confirmation d’e-mail conservée. Minimum des nouveaux mots de passe porté à 12 caractères ; changement de mot de passe exigeant une session récente. Les mots de passe existants ne sont pas modifiés. Protection contre les mots de passe divulgués indisponible sur le forfait Free, aucun abonnement acheté.

## Migration et déploiement
Base historique seulement, après les migrations d'équipe/messagerie :
1. `202610100001_security.sql`
2. `202610100002_api_limits.sql`
3. `202610100003_mfa.sql`
4. `202610100004_function_access.sql`

Les migrations sont transactionnelles. Publier également le code ; aucun secret ne doit être ajouté à GitHub. Ne pas appliquer la migration initiale de reconstruction sur cette base.

## Vérification et limites
TypeScript, compilation de production et 32 tests unitaires passent. Les tests couvrent notamment l'authentification, les comptes inactifs, le consentement IA, les corps malformés/trop grands, le quota et le rejet d'une session sans second facteur. Test isolé de lecture/écriture XLSX et d'UUID v4 avec uuid 11.1.1 réussi. Test transactionnel Supabase des privilèges, quotas et accès administrateur réussi, avec rollback. Redirections d'authentification contrôlées : les trois URL exactes FR/HE/EN du domaine principal, aucun joker. L'activation réelle d'un Authenticator doit être effectuée et testée par le titulaire du compte. Ne jamais publier ou envoyer le QR code ou le code de secours.

À compléter pour un niveau de sécurité supérieur : rendre le TOTP obligatoire après inscription de tous les employés et validation de la procédure de récupération ; activer le TOTP aussi sur GitHub, Vercel et Supabase ; contrôler les adresses exactes de redirection ; vérifier les sauvegardes et tester une restauration ; contrôler régulièrement les dépendances, les journaux et les droits ; protéger les ordinateurs et navigateurs utilisés. Aucun audit exhaustif de pénétration ou de dépendances n'est prétendu ici.

La session Supabase reste stockée par le SDK dans le navigateur. Une migration vers des cookies HttpOnly et une CSP avec nonces demanderait de modifier le fonctionnement de l'authentification ; elle n'est pas incluse dans ce changement. Pas de chiffrement de bout en bout de la messagerie. La clé `service_role` est réservée au serveur et ne doit jamais être préfixée `NEXT_PUBLIC_`.
