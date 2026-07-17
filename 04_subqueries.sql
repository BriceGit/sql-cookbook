-- ============================================================
-- 04 - SUBQUERIES
-- ============================================================

-- --- Sous-requête dans le WHERE (filtre sur un ensemble de valeurs) ---

SELECT customer_id, name
FROM customers
WHERE customer_id IN (
    SELECT customer_id FROM orders WHERE amount > 1000
);

-- Piège fréquent : si la sous-requête peut renvoyer NULL parmi ses valeurs,
-- NOT IN (...) devient piégeux -> NOT IN avec un NULL dans la liste renvoie
-- un résultat vide au lieu du résultat attendu. Préférer NOT EXISTS dans ce cas.


-- --- Sous-requête dans le FROM (table dérivée) ---

SELECT country, AVG(nb_orders) AS avg_orders_per_customer
FROM (
    SELECT c.customer_id, c.country, COUNT(o.order_id) AS nb_orders
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.country
) AS orders_per_customer
GROUP BY country;

-- Utilité type : agréger un résultat déjà agrégé (ex: moyenne d'un COUNT
-- par groupe) -> impossible en un seul niveau de GROUP BY, d'où la sous-requête.


-- --- CTE (WITH ...) : alternative lisible à la sous-requête imbriquée ---

WITH orders_per_customer AS (
    SELECT c.customer_id, c.country, COUNT(o.order_id) AS nb_orders
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.country
)
SELECT country, AVG(nb_orders) AS avg_orders_per_customer
FROM orders_per_customer
GROUP BY country;

-- Même résultat que la version FROM (sous-requête), mais plus lisible dès que
-- la logique s'empile sur plusieurs étapes. On peut même chaîner plusieurs CTE :
-- WITH step1 AS (...), step2 AS (SELECT ... FROM step1 ...) SELECT * FROM step2;


-- --- Sous-requête corrélée (référence la requête externe) ---

SELECT c.customer_id, c.name
FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.customer_id
    AND o.amount > 1000
);

-- Piège fréquent : une sous-requête corrélée est ré-exécutée pour CHAQUE ligne
-- de la requête externe (ici, une fois par client) -> coûteux sur un gros volume.
-- Une sous-requête non corrélée (comme l'exemple IN plus haut) ne s'exécute
-- qu'une seule fois, indépendamment du nombre de lignes externes.


-- --- IN vs EXISTS : lequel choisir ---

-- IN : plus lisible quand la sous-requête renvoie une petite liste de valeurs simples.
-- EXISTS : généralement plus performant sur de gros volumes, et plus sûr
-- vis-à-vis des NULL (voir piège NOT IN ci-dessus).
