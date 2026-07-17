-- ============================================================
-- 02 - AGGREGATION, DATE & TIME FUNCTIONS
-- ============================================================

-- --- Agrégats classiques ---

SELECT
    country,
    COUNT(*) AS nb_customers,
    AVG(amount) AS avg_amount
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY country;

-- Piège fréquent : toute colonne du SELECT qui n'est pas agrégée
-- doit être présente dans le GROUP BY (sinon erreur ou comportement
-- indéfini selon le moteur SQL).


-- --- HAVING vs WHERE ---

SELECT country, COUNT(*) AS nb_customers
FROM customers
GROUP BY country
HAVING COUNT(*) > 10;

-- Piège fréquent : WHERE filtre AVANT l'agrégation (sur les lignes brutes),
-- HAVING filtre APRÈS (sur le résultat agrégé). Utiliser WHERE avec un
-- agrégat direct (WHERE COUNT(*) > 10) génère une erreur.


-- --- Fonctions de date/heure ---

SELECT
    order_id,
    order_date,
    DATE_TRUNC('month', order_date) AS order_month,
    EXTRACT(YEAR FROM order_date) AS order_year,
    order_date - LAG(order_date) OVER (ORDER BY order_date) AS days_since_last_order
FROM orders;

-- Piège fréquent : DATE_TRUNC arrondit toujours vers le début de la période
-- (ex: DATE_TRUNC('month', '2026-07-17') -> '2026-07-01'), pas vers la fin.


-- --- Pattern courant : agrégation par mois ---

SELECT
    DATE_TRUNC('month', order_date) AS month,
    COUNT(DISTINCT customer_id) AS active_customers,
    SUM(amount) AS revenue
FROM orders
GROUP BY 1
ORDER BY 1;

-- Piège fréquent : GROUP BY 1 fait référence à la 1re colonne du SELECT
-- (raccourci pratique), mais ça casse silencieusement si l'ordre des
-- colonnes change plus tard dans la requête.
