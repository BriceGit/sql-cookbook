-- ============================================================
-- 01 - INTRO TO TRANSFORMATION
-- Bases du SELECT, contraintes de schéma (primary key, foreign key)
-- ============================================================

-- Schéma fictif utilisé dans tout le carnet :
-- customers(customer_id PK, name, country, signup_date)
-- orders(order_id PK, customer_id FK, order_date, amount)
-- transactions(transaction_id PK, order_id FK, status, transaction_date)


-- --- SELECT / WHERE / ORDER BY : le squelette de base ---

SELECT customer_id, name, country
FROM customers
WHERE country = 'CH'
ORDER BY signup_date DESC;

-- Piège fréquent : WHERE ne peut PAS filtrer sur un alias de SELECT
-- (ex: WHERE nb_orders > 5 après un alias "nb_orders" -> erreur, il faut HAVING ou une sous-requête)


-- --- PRIMARY KEY : identifiant unique d'une ligne ---

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    country TEXT,
    signup_date DATE
);

-- Piège fréquent : une primary key est automatiquement UNIQUE + NOT NULL,
-- pas besoin de le repréciser à côté.


-- --- FOREIGN KEY : lien entre deux tables ---

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    order_date DATE,
    amount NUMERIC
);

-- Piège fréquent : une foreign key n'empêche pas les doublons,
-- elle garantit juste que la valeur existe dans la table référencée.
-- Ne pas confondre "intégrité référentielle" et "unicité".


-- --- NOT NULL / UNIQUE : contraintes de qualité de donnée ---

ALTER TABLE customers
ADD CONSTRAINT unique_email UNIQUE (email);

-- Piège fréquent : ajouter une contrainte UNIQUE sur une colonne qui contient
-- déjà des doublons fait échouer l'ALTER TABLE -> nettoyer les données avant.
