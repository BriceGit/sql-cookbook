-- ============================================================
-- 03 - JOINS AND TESTING
-- ============================================================

-- --- INNER JOIN : ne garde que les lignes qui matchent des deux côtés ---

SELECT c.name, o.order_id, o.amount
FROM customers c
INNER JOIN orders o ON o.customer_id = c.customer_id;


-- --- LEFT JOIN : garde toutes les lignes de la table de gauche ---

SELECT c.name, o.order_id, o.amount
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id;

-- Piège fréquent : après un LEFT JOIN, les colonnes de la table de droite
-- sont NULL quand il n'y a pas de match -> penser à COALESCE(o.amount, 0)
-- si on va sommer/compter ensuite, sinon les NULL faussent les agrégats.


-- --- Repérer les non-matchs (anti-join) ---

SELECT c.customer_id, c.name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;

-- Utilité type : clients qui n'ont jamais passé commande.
-- Piège fréquent : mettre la condition IS NULL dans le ON au lieu du WHERE
-- change complètement le résultat (le ON définit le matching, pas le filtre final).


-- --- SELF JOIN : joindre une table à elle-même ---

SELECT a.customer_id, b.customer_id
FROM customers a
JOIN customers b
    ON a.country = b.country
    AND a.customer_id < b.customer_id;

-- Utilité type : trouver des paires (ex: clients du même pays).
-- Piège fréquent : oublier "a.id < b.id" -> chaque paire apparaît deux fois
-- (A-B et B-A), et les lignes où a.id = b.id se matchent avec elles-mêmes.


-- --- Tester la qualité d'un join (sanity check) ---

-- Vérifier qu'un join ne duplique pas de lignes de façon inattendue :
SELECT COUNT(*) FROM customers;                    -- baseline
SELECT COUNT(*) FROM customers c LEFT JOIN orders o -- après join
    ON o.customer_id = c.customer_id;

-- Piège fréquent : un join "many-to-many" non voulu multiplie les lignes
-- silencieusement -> toujours comparer les COUNT(*) avant/après un join
-- pour détecter une explosion du nombre de lignes.
