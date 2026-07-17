-- ============================================================
-- 05 - USER-DEFINED FUNCTIONS AND WINDOW FUNCTIONS
-- ============================================================

-- --- ROW_NUMBER : numéroter les lignes selon un ordre ---

SELECT
    customer_id,
    order_id,
    order_date,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_rank
FROM orders;

-- Utilité type : identifier la 1re commande de chaque client (order_rank = 1).
-- Piège fréquent : oublier le PARTITION BY -> le numéro continue sur
-- l'ensemble de la table au lieu de repartir à 1 pour chaque client.


-- --- RANK / DENSE_RANK : classement avec gestion des ex-aequo ---

SELECT
    customer_id,
    SUM(amount) AS total_spent,
    RANK() OVER (ORDER BY SUM(amount) DESC) AS spending_rank
FROM orders
GROUP BY customer_id;

-- Piège fréquent : RANK() saute des rangs après un ex-aequo (1,1,3...),
-- DENSE_RANK() non (1,1,2...). Bien choisir selon ce qu'on veut afficher.


-- --- LAG / LEAD : comparer une ligne à la précédente/suivante ---

SELECT
    customer_id,
    order_date,
    amount,
    LAG(amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_amount,
    amount - LAG(amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS diff_vs_previous
FROM orders;

-- Piège fréquent : LAG renvoie NULL pour la toute première ligne de chaque
-- partition -> penser à gérer ce cas (COALESCE ou filtre) si besoin.


-- --- Running total (somme cumulée) ---

SELECT
    order_date,
    amount,
    SUM(amount) OVER (ORDER BY order_date) AS running_total
FROM orders;

-- Piège fréquent : sans PARTITION BY, la somme cumule sur TOUTE la table
-- (tous clients confondus) -> ajouter PARTITION BY customer_id si le
-- cumul doit être calculé par client.


-- --- User-defined function (exemple simple, syntaxe PostgreSQL) ---

CREATE FUNCTION days_since(input_date DATE)
RETURNS INTEGER AS $$
    SELECT CURRENT_DATE - input_date;
$$ LANGUAGE SQL;

-- Piège fréquent : la syntaxe de création de fonction change beaucoup
-- selon le moteur (PostgreSQL / BigQuery / Snowflake) -> vérifier la
-- doc du moteur utilisé plutôt que de généraliser une syntaxe apprise ailleurs.
