# Yonathan Immobilier — reconstruction

Cette version est une **nouvelle implémentation**, créée le 7 octobre 2026. Elle ne récupère pas mot pour mot le dernier code Codex perdu. Aucun fichier original du CRM, dump SQL, accès Supabase ou secret n'a été disponible. Aucune modification n'a été effectuée dans GitHub ou dans Supabase.

## Ce que le contexte établit avec certitude

La conversation « CRM IMMO » (`6a61fa45-431c-83eb-9eec-5f12e1c6dfaf`) confirme Next.js, un dashboard, des prospects, projets, appartements, rendez-vous, un suivi commercial et les langues FR/HE/EN. La demande actuelle précise le nom Yonathan Immobilier, App Router, TypeScript, Tailwind, Supabase, next-intl, tâches, liaison prospect-appartements et RTL.

L'historique accessible ne fournit **aucun ancien code, nom de table, champ, enum ou valeur de statut canonique**. Les captures disponibles portent sur la récupération du projet, pas sur son schéma. La fonctionnalité est connue, son ancienne implémentation ne l'est pas. Les tables, champs, relations et permissions ci-dessous sont des choix explicites de reconstruction à vérifier.

## Fonctionnalités implémentées

- Authentification Supabase par e-mail/mot de passe, session persistante, déconnexion et réinitialisation du mot de passe. Comptes créés par l'administrateur dans Supabase ; pas d'inscription publique dans l'interface.
- Dashboard avec six compteurs, prochains rendez-vous et tâches classées par échéance ; sidebar responsive.
- Liste, recherche, création, détail, édition et suppression pour prospects, projets, appartements, rendez-vous, suivi commercial et tâches.
- Fiche prospect avec appartements liés, ajout/retrait des liens et édition de leur statut ; historique des rendez-vous, activités et tâches.
- Relations choisies dans les formulaires, dates stockées en UTC, nombres formatés selon la langue.
- Traductions de l'interface FR/HE/EN avec next-intl. URLs `/fr`, `/he`, `/en`, langue HTML, RTL hébreu et propriétés CSS logiques. Les données saisies restent dans leur langue originale.
- Validation des champs obligatoires, nombres non négatifs et fin de rendez-vous ; confirmations avant suppression des dossiers.
- Migration SQL transactionnelle, clés étrangères incluant le propriétaire, RLS pour chaque opération, index et timestamps automatiques.

## Valeurs DB canoniques

**Aucune liste canonique n'est connue depuis la conversation fournie.** Les champs `status`, `source`, `kind`, `priority` et `currency` restent du texte libre. Leur valeur est sauvegardée telle qu'elle est saisie, sans traduction, changement de casse ou correspondance implicite. Aucun enum ni statut obligatoire n'a été inventé. `ILS` est seulement la valeur proposée par le formulaire d'un nouvel appartement ; elle est modifiable et n'est pas un défaut SQL. Le budget n'a pas de devise confirmée : vérifier cette convention avant utilisation réelle.

Avant de raccorder les anciennes données, relever les valeurs DISTINCT et les enums réels puis conserver exactement leur orthographe. Une future liste déroulante doit traduire les libellés affichés, tout en envoyant les valeurs DB originales. Il faut adapter le modèle et la migration à la base vérifiée ; ne pas convertir silencieusement les anciennes valeurs.

## Installation

Node.js **24 LTS** recommandé (22.18+ pour les tests TS natifs). Utiliser pnpm ; `pnpm-lock.yaml` fixe les versions effectivement vérifiées.

```sh
corepack enable
pnpm install --frozen-lockfile
```

Copier `.env.example` vers `.env.local`, renseigner l'URL du projet et la clé publique publishable Supabase (la clé legacy `anon` convient également). **Ne jamais mettre de clé `service_role` dans une variable NEXT_PUBLIC.** `.env.local` est ignoré par Git. Les variables publiques sont intégrées au build : reconstruire après modification.

```sh
pnpm dev
```

Ouvrir http://localhost:3000/fr. Sans configuration, une page d'installation s'affiche, sans données fictives. Le CRM fonctionne avec de vraies requêtes Supabase après configuration et migration.

## Supabase : projet neuf ou existant

### Projet neuf / environnement de test

1. Créer un projet Supabase de test.
2. Exécuter `supabase/migrations/202610070001_reconstruction.sql` dans SQL Editor, ou via le workflow de migrations Supabase CLI de votre projet lié.
3. Créer un utilisateur dans Authentication > Users. Pour un compte invité, terminer la définition du mot de passe par le flux d'invitation configuré ; sinon créer un compte e-mail/mot de passe confirmé pour le test.
4. Configurer Authentication > URL Configuration : Site URL `http://localhost:3000` et Redirect URLs exactes `http://localhost:3000/fr`, `/he`, `/en` (avec le préfixe complet pour chaque URL). Ajouter les trois équivalents HTTPS lors du déploiement.
5. Configurer le SMTP et vérifier l'envoi des e-mails de réinitialisation. Le lien doit retourner dans le même navigateur ; le client Supabase détecte `PASSWORD_RECOVERY`, puis affiche le formulaire de nouveau mot de passe. Ce flux utilise les liens implicites pris en charge par le client navigateur, pas un callback serveur PKCE.
6. Renseigner `.env.local` et vérifier la connexion.

### Supabase existant « Projet Immo »

**Auditer et sauvegarder d'abord ; la migration n'a pas été appliquée à votre base.** `supabase/audit-existing.sql` est une inspection en lecture seule des colonnes, enums, contraintes et politiques. Relever également les valeurs DISTINCT des statuts, devises, priorités et types sur les colonnes réellement présentes.

Toutes les nouvelles tables sont préfixées `yi_` pour ne pas écraser les tables historiques. La migration ne contient aucun DROP, ALTER ou UPDATE visant les anciennes tables, aucun import automatique ni seed commercial. Elle échoue si les tables `yi_` ou la fonction existent déjà : cela évite de masquer un schéma incompatible. Appliquer sur une copie/test en premier. Ces tables sont vides : elles n'affichent pas spontanément les données du CRM précédent.

Deux chemins restent à valider : adapter `src/lib/model.ts` et les requêtes au schéma historique, ou établir une migration d'import vers `yi_*`. Dans les deux cas vérifier les colonnes, identifiants, valeurs canoniques, liens et propriétaires avant toute écriture. Aucun mapping d'import n'est fourni faute de schéma source.

## Schéma proposé

Toutes les tables possèdent `id`, `owner_id`, `created_at`, `updated_at`.

| Table | Contenu principal |
| --- | --- |
| `yi_prospects` | nom, e-mail, téléphone, statut, origine, budget, ville, notes |
| `yi_projects` | nom, ville, adresse, promoteur, statut, livraison, notes |
| `yi_apartments` | référence, projet obligatoire, étage, pièces, surface, prix, devise, statut |
| `yi_prospect_apartments` | lien unique prospect/appartement et statut commercial du lien |
| `yi_appointments` | titre, prospect obligatoire, appartement facultatif, début/fin, lieu, statut |
| `yi_activities` | titre, prospect obligatoire, type, date, notes |
| `yi_tasks` | titre, prospect facultatif, échéance, statut, priorité, notes |

La référence d'un appartement est unique dans un projet et pour un propriétaire. La suppression d'un prospect supprime ses liens, rendez-vous, activités et tâches. La suppression d'un projet contenant des appartements est bloquée ; celle d'un appartement ayant des rendez-vous est bloquée. Les liens prospect-appartements sont retirés automatiquement lors de la suppression d'un appartement. Aucun effacement logique n'est supposé.

## Authentification et accès

Cette version utilise le client Supabase dans le navigateur ; les sessions sont gérées par son SDK. Le serveur Next.js rend la structure, pas les données privées. Il n'y a ni session SSR par cookies, ni middleware de protection serveur. La vérification de session côté UI améliore l'expérience ; **la protection réelle des données est la RLS Postgres**, indépendante de l'interface.

Le modèle proposé est **un propriétaire par dossier**, `owner_id = auth.uid()`. Les filtres clients seuls ne sont pas une protection : chaque table a des politiques SELECT, INSERT, UPDATE et DELETE avec contrôle du propriétaire. Les clés étrangères composites empêchent de relier des dossiers appartenant à deux utilisateurs différents. Pas de clé administrateur utilisée par l'application.

À vérifier : agence partagée, collaborateurs, administrateurs, attribution des prospects et droits de visibilité. Ces règles ne sont pas connues. Ne pas supprimer la RLS pour simuler un accès agence ; concevoir alors des memberships/roles explicites et les tester. Tous les comptes voient uniquement leurs propres dossiers dans cette version.

## Vérifications et limites

```sh
pnpm typecheck
pnpm test
pnpm build
pnpm start
```

Les tests unitaires vérifient la conservation des valeurs DB, les nombres, les dates UTC, l'ordre des rendez-vous et le whitelist des champs. `supabase/tests/rls.sql` est un test d'intégration rollback pour une **base de test jetable** après migration. Il vérifie accès anonyme, isolation lecture/écriture, tentative de changement de propriétaire, relations entre propriétaires et cascade. À exécuter avec `psql -v ON_ERROR_STOP=1` sous un compte postgres. Il n'a pas été exécuté ici faute d'accès Supabase/Postgres.

La connexion réelle, les parcours CRUD, les e-mails et les migrations nécessitent une recette sur votre Supabase. Dates affichées dans le fuseau du navigateur, dates de livraison sans heure, fuseau next-intl `Asia/Jerusalem`. Vérifier la règle souhaitée pour toute l'agence.

Les listes et choix relationnels chargent actuellement les dossiers par lots de 250 côté client pour dépasser la limite PostgREST par défaut, avec recherche locale. Régler la limite de lignes API à au moins 250. Pour de gros volumes, prévoir recherche et pagination visibles côté serveur. Calendrier graphique, notifications, pièces jointes, audit utilisateur, rôles agence, export et automatisations ne sont pas reconstitués depuis le contexte. Aucun service externe d'e-mail/SMS commercial n'est appelé.

### Résultats de vérification de cette livraison

- Build Next.js de production et vérification TypeScript réussis.
- 5 tests unitaires réussis (validation métier et cohérence des traductions).
- Réponses HTTP 200 vérifiées sur `/fr`, `/he`, `/en`, avec attributs HTML `lang` et `dir` corrects ; redirection `/` vers `/fr` et locale non prise en charge en 404 vérifiées.
- Page de configuration inspectée dans le navigateur, avec changement FR vers HE et mise en page responsive.
- Migrations SQL, RLS, authentification réelle, CRUD réel et e-mails **non exécutés contre Supabase** : recette requise avec vos accès.

Le test des pages sans Supabase peut être relancé avec `node tests/local-smoke.mjs` après démarrage sur le port 3100, ou en renseignant `SMOKE_URL`. Les traductions sont utilisées dans les composants clients ; le layout fournit explicitement tous les paramètres next-intl, sans middleware de langue ni plugin serveur.

## Recette avant utilisation réelle

1. Vérifier schéma et valeurs canoniques sur une copie de Supabase.
2. Avec deux comptes, créer un projet et deux appartements, puis un prospect ; contrôler que l'autre compte ne voit ni ne modifie les données.
3. Lier/délier les appartements, modifier le statut du lien, créer rendez-vous, activité et tâche pour le prospect.
4. Vérifier édition, recherche, détails et règles de suppression, notamment les cascades.
5. Refaire les écrans en FR/HE/EN, vérifier RTL sur mobile et dates/fuseaux.
6. Tester connexion, déconnexion et réinitialisation réelle du mot de passe.

Références techniques : [Next.js App Router](https://nextjs.org/docs/app/getting-started), [next-intl configuration](https://next-intl.dev/docs/usage/configuration), [Supabase Auth resetPasswordForEmail](https://supabase.com/docs/reference/javascript/auth-resetpasswordforemail).
