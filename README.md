# 📓 SQL Cookbook — carnet de notes récap'

Carnet de requêtes annotées, calé sur le **cheminement du module "Data transformation" du Wagon**, pour garder une cohérence directe avec le cours au fil des semaines.

## Sommaire

| # | Fichier | Module Wagon | Statut |
|---|---|---|---|
| 01 | `01_intro_transformation.sql` | Intro to Transformation | 🟢 vu |
| 02 | `02_aggregation_date_time.sql` | Aggregation, Date & Time Functions | 🟢 vu |
| 03 | `03_joins_and_testing.sql` | Joins and Testing | 🟢 vu |
| 04 | `04_subqueries.sql` | Subqueries | 🟢 vu |
| 05 | `05_udf_window_functions.sql` | User-defined Functions and Window Functions | 🟢 vu |
| 06 | `06_advanced_sql.sql` | Advanced SQL (views, partition, data warehousing) | 🟢 vu |
| 07 | `07_sql_project.md` | SQL Project | ⏳ à venir |
| 08 | `08_git_versioning.md` | Intro to Git and Versioning | ⏳ à venir |
| 09 | `09_dbt_data_layers.sql` | Intro to DBT and Data Layers | ⏳ à venir |
| 10 | `10_dbt_advanced_warehousing.sql` | DBT Advanced (macros, snapshots, incremental) | ⏳ à venir *(bases du data warehousing déjà couvertes en 06)* |

*(les fichiers "vus" ci-dessus incluent déjà du contenu de base à partir de tes 5 derniers jours de cours — les autres sont des coquilles prêtes à remplir au fur et à mesure.)*

## Convention de chaque fichier

Chaque bloc suit le même format :
1. **Syntaxe de base** — le squelette minimal
2. **Exemple concret** — sur un schéma fictif simple (`customers`, `orders`, `transactions`)
3. **Piège fréquent** — l'erreur classique à ce niveau d'apprentissage

## Comment l'utiliser

- Ajoute une entrée dès qu'une notion nouvelle te pose souci en cours, plutôt qu'en fin de semaine (à chaud c'est plus fidèle).
- Le statut (🟢 vu / ⏳ à venir) te permet de voir en un coup d'œil où tu en es dans le cursus.
- Carnet volontairement neutre/générique — les requêtes spécifiques au Projet 1 (banking) restent dans le repo du projet, pas ici.
