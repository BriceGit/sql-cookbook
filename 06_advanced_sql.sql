-- ============================================================
-- 06 - ADVANCED SQL
-- Views, partitionnement, notions de data warehousing
-- ============================================================

-- --- VIEW : requête sauvegardée, réutilisable comme une table ---

CREATE VIEW active_customers AS
SELECT customer_id, name, country
FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.customer_id
    AND o.order_date > CURRENT_DATE - INTERVAL '90 days'
);

-- Utilité : encapsuler une logique métier répétée (ex: "client actif")
-- pour ne pas réécrire la même définition dans 10 requêtes différentes.

SELECT * FROM active_customers WHERE country = 'CH';

-- Piège fréquent : une VIEW classique ne stocke PAS les données,
-- elle ré-exécute la requête sous-jacente à chaque appel -> pas de gain
-- de performance en soi, juste un gain de lisibilité/maintenabilité.


-- --- MATERIALIZED VIEW : view qui stocke physiquement le résultat ---

CREATE MATERIALIZED VIEW monthly_revenue AS
SELECT DATE_TRUNC('month', order_date) AS month, SUM(amount) AS revenue
FROM orders
GROUP BY 1;

-- Piège fréquent : une materialized view ne se met PAS à jour automatiquement
-- quand les données sources changent -> il faut la rafraîchir explicitement
-- (REFRESH MATERIALIZED VIEW monthly_revenue;).


-- --- PARTITION BY : au-delà des window functions simples ---

-- Rappel express (déjà vu module 05) : PARTITION BY découpe la table en
-- sous-groupes pour un calcul de fenêtre, sans réduire le nombre de lignes
-- (contrairement à GROUP BY qui, lui, agrège et réduit les lignes).

SELECT
    customer_id,
    order_date,
    amount,
    SUM(amount) OVER (PARTITION BY customer_id) AS total_customer_spend,
    amount * 1.0 / SUM(amount) OVER (PARTITION BY customer_id) AS pct_of_customer_spend
FROM orders;

-- Piège fréquent : confondre PARTITION BY (window function, garde toutes les
-- lignes) et GROUP BY (agrégation, une seule ligne par groupe en sortie).
-- Ici, chaque commande individuelle reste visible, avec le total du client à côté.


-- --- Table physiquement partitionnée (notion de warehouse, pas une window function) ---

-- Ici "PARTITION" a un 2e sens : découper physiquement une grosse table
-- pour accélérer les requêtes qui filtrent sur la clé de partition.

CREATE TABLE orders_partitioned (
    order_id INTEGER,
    customer_id INTEGER,
    order_date DATE,
    amount NUMERIC
) PARTITION BY RANGE (order_date);

CREATE TABLE orders_2026_q1 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2026-01-01') TO ('2026-04-01');

-- Piège fréquent : bien distinguer "PARTITION BY" dans une window function
-- (logique, à l'intérieur d'une requête) et "PARTITION BY" dans un CREATE TABLE
-- (physique, structure de stockage) -> même mot-clé, deux concepts différents.


-- --- Data warehousing : star schema (fact / dimension tables) ---

-- Table de faits (fact table) : les événements mesurables, très granulaires
-- CREATE TABLE fact_orders (
--     order_id INTEGER PRIMARY KEY,
--     customer_id INTEGER REFERENCES dim_customers(customer_id),
--     date_id INTEGER REFERENCES dim_date(date_id),
--     amount NUMERIC
-- );

-- Table de dimension (dimension table) : le contexte descriptif, peu volumineux
-- CREATE TABLE dim_customers (
--     customer_id INTEGER PRIMARY KEY,
--     name TEXT,
--     country TEXT,
--     segment TEXT
-- );

-- Utilité : séparer "ce qui s'est passé" (faits, souvent des milliards de lignes)
-- de "qui/quoi/quand" (dimensions, quelques milliers de lignes) -> requêtes
-- de reporting plus simples et plus rapides qu'un schéma tout-en-un.

-- Piège fréquent : un schéma en étoile est volontairement dénormalisé
-- (redondance acceptée dans les dimensions) pour privilégier la vitesse de
-- lecture -> ne pas essayer de le normaliser "proprement" comme un schéma
-- transactionnel (OLTP), ce n'est pas le même objectif (OLAP = lecture/reporting).
