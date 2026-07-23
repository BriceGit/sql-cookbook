-- =====================================================================
-- 09_dbt_data_layers.sql
-- Blocs de code DBT réutilisables, organisés par couche.
-- Compagnon technique de 09_dbt_intro.md — copier-coller direct.
-- Convention : {{ source() }} en staging uniquement, {{ ref() }} partout ailleurs.
-- =====================================================================


-- =====================================================================
-- 1. SOURCES — déclarer puis lire la donnée brute
-- =====================================================================

-- Déclaration dans models/schema.yml (pas du SQL, mais toujours utile sous la main)
/*
sources:
  - name: jaffle_shop
    schema: raw
    tables:
      - name: customers
        identifier: raw_customers
      - name: orders
        identifier: raw_orders
      - name: payments
        identifier: raw_payments
*/

-- Lire une source dans un modèle staging
SELECT * FROM {{ source('jaffle_shop', 'customers') }}


-- =====================================================================
-- 2. STAGING — 1 modèle = 1 source. Jamais de join, jamais d'agrégation.
-- =====================================================================

-- Template CTE standard : à copier-coller pour CHAQUE modèle staging
WITH source AS (
    SELECT * FROM {{ source('jaffle_shop', 'customers') }}
),

renamed AS (
    SELECT
        id            AS customer_id,
        first_name,
        last_name
    FROM source
)

SELECT * FROM renamed


-- Renommage + cast de type : le combo le plus courant en staging
SELECT
    id::integer                    AS order_id,
    user_id::integer               AS customer_id,
    order_date::date               AS order_date,
    status::varchar                AS status,
    CAST(amount AS DECIMAL(10,2))  AS amount
FROM source


-- Conversion d'unité (centimes -> unité), très courant sur les montants
SELECT
    id             AS payment_id,
    order_id,
    amount / 100.0 AS amount   -- la source stocke amount en centimes
FROM source


-- Déduplication, méthode 1 : ROW_NUMBER + filtre (garder la ligne la plus récente)
WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY id
            ORDER BY updated_at DESC
        ) AS row_num
    FROM source
)

SELECT * FROM ranked
WHERE row_num = 1


-- Déduplication, méthode 2 : DISTINCT simple si aucune notion de version
SELECT DISTINCT * FROM source


-- Coalescer un null sur une colonne texte
SELECT
    id,
    COALESCE(email, 'unknown') AS email
FROM source


-- Filtre basique : autorisé en staging, contrairement au join/à l'agrégation
SELECT * FROM source
WHERE deleted_at IS NULL


-- =====================================================================
-- 3. INTERMEDIATE — la logique métier : joins, agrégations, KPIs
-- =====================================================================

-- Le pattern le plus courant : agréger une table puis la joindre à une autre
WITH orders   AS (SELECT * FROM {{ ref('stg_orders') }}),
     payments AS (SELECT * FROM {{ ref('stg_payments') }}),

payment_totals AS (
    SELECT
        order_id,
        SUM(amount) AS total_amount
    FROM payments
    GROUP BY order_id
),

orders_with_payments AS (
    SELECT
        orders.*,
        COALESCE(payment_totals.total_amount, 0) AS total_amount
    FROM orders
    LEFT JOIN payment_totals USING (order_id)
)

SELECT * FROM orders_with_payments


-- LEFT JOIN + COALESCE : le réflexe pour une relation optionnelle
SELECT
    a.*,
    COALESCE(b.some_metric, 0) AS some_metric
FROM {{ ref('stg_a') }} a
LEFT JOIN {{ ref('stg_b') }} b USING (id)


-- Grain check : A LANCER APRES CHAQUE JOIN, sans exception
SELECT
    COUNT(*)                 AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM {{ ref('int_orders_with_payments') }}
-- Les deux nombres doivent être égaux.
-- Si total_rows > distinct_orders : le join duplique des lignes, il est cassé.


-- Fenêtre analytique : première commande, rang, cumul dans le temps
SELECT
    customer_id,
    order_date,
    MIN(order_date) OVER (PARTITION BY customer_id)                      AS first_order_date,
    ROW_NUMBER()    OVER (PARTITION BY customer_id ORDER BY order_date)  AS order_sequence,
    SUM(total_amount) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_spend
FROM {{ ref('stg_orders') }}


-- Colonne dérivée / règle métier conditionnelle
SELECT
    order_id,
    total_amount,
    CASE
        WHEN total_amount >= 100 THEN 'high_value'
        WHEN total_amount >= 30  THEN 'medium_value'
        ELSE 'low_value'
    END AS order_value_segment
FROM {{ ref('int_orders_with_payments') }}


-- =====================================================================
-- 4. MARTS — la couche servie : dim_ et fct_, matérialisés en TABLE
-- =====================================================================

-- Table de DIMENSION : "qui est cette entité ?" + métriques lifetime
WITH customers AS (SELECT * FROM {{ ref('stg_customers') }}),
     orders    AS (SELECT * FROM {{ ref('int_orders_with_payments') }}),

customer_metrics AS (
    SELECT
        customer_id,
        MIN(order_date)   AS first_order_date,
        MAX(order_date)   AS most_recent_order_date,
        COUNT(order_id)   AS number_of_orders,
        SUM(total_amount) AS lifetime_value
    FROM orders
    GROUP BY customer_id
)

SELECT
    customers.*,
    customer_metrics.*
FROM customers
LEFT JOIN customer_metrics USING (customer_id)


-- Table de FAITS : "qu'est-ce qui s'est passé ?", une ligne par événement
WITH orders    AS (SELECT * FROM {{ ref('int_orders_with_payments') }}),
     customers AS (SELECT * FROM {{ ref('stg_customers') }})

SELECT
    orders.order_id,
    orders.customer_id,
    orders.order_date,
    orders.status,
    orders.total_amount,
    customers.first_name,
    customers.last_name
FROM orders
LEFT JOIN customers USING (customer_id)
-- Règle : pas de métriques lifetime ici, elles vivent dans dim_customers


-- Intégrité du star schema : chaque FK de la fact doit exister dans sa dimension
SELECT COUNT(*)
FROM {{ ref('fct_orders') }} f
LEFT JOIN {{ ref('dim_customers') }} d USING (customer_id)
WHERE d.customer_id IS NULL
-- Doit renvoyer 0. Sinon : clé orpheline, une commande pointe vers un client
-- qui n'existe pas dans dim_customers.


-- =====================================================================
-- 5. TESTS RAPIDES — a lancer en console avant tout commit
-- =====================================================================

-- Test not_null "à la main"
SELECT COUNT(*) FROM {{ ref('stg_customers') }} WHERE customer_id IS NULL
-- Doit renvoyer 0

-- Test unique "à la main"
SELECT customer_id, COUNT(*)
FROM {{ ref('stg_customers') }}
GROUP BY customer_id
HAVING COUNT(*) > 1
-- Ne doit renvoyer aucune ligne

-- Équivalent déclaratif dans schema.yml (remplace le SQL à la main une fois en place)
/*
columns:
  - name: customer_id
    tests: [unique, not_null]
*/
