# NTILE — Découpage en quartiles, tertiles et autres N-tiles

## À quoi ça sert

`NTILE(n)` est une fonction de fenêtrage (window function) qui répartit les lignes d'un résultat en **n groupes de taille égale**, classés selon un `ORDER BY`. C'est l'outil standard pour transformer une variable continue (montant, récence, fréquence...) en catégories statistiques, **sans fixer de seuils arbitraires**.

- `NTILE(4)` → quartiles (4 groupes, ~25% des lignes chacun)
- `NTILE(3)` → tertiles (3 groupes, ~33% des lignes chacun)
- `NTILE(10)` → déciles (10 groupes, ~10% des lignes chacun)

Le choix entre quartile/tertile n'est pas technique mais analytique : plus de groupes = plus de granularité mais des effectifs plus petits par groupe et des seuils moins lisibles à l'oral. En RFM, le quartile (4) est le standard car il donne un équilibre correct entre finesse et lisibilité.

## Syntaxe de base

```sql
SELECT
  client_id,
  montant_total,
  NTILE(4) OVER (ORDER BY montant_total) AS quartile
FROM clients;
```

- `OVER (ORDER BY montant_total)` : classe les lignes par montant croissant, puis les répartit en 4 groupes.
- Groupe 1 = les 25% avec les montants les plus bas, groupe 4 = les 25% avec les montants les plus hauts.

## Piège n°1 — le sens du ORDER BY change le sens des groupes

`NTILE` numérote toujours les groupes de 1 à n dans le sens du tri. Ça veut dire que pour une métrique comme la Récence, où "petit nombre de jours" = "bon client", il faut inverser le tri si tu veux que le groupe 4 corresponde aux meilleurs clients.

```sql
-- Montant : plus c'est haut, mieux c'est → ORDER BY ASC, le groupe 4 = les meilleurs
NTILE(4) OVER (ORDER BY montant_total ASC) AS quartile_montant

-- Récence (jours depuis dernier achat) : moins de jours = meilleur client → ORDER BY DESC
NTILE(4) OVER (ORDER BY recency_days DESC) AS quartile_recency
```

Erreur classique : garder le même sens de tri pour toutes les variables RFM par réflexe, et se retrouver avec un groupe "4" qui veut dire "meilleur" pour Montant et Fréquence, mais "pire" pour Récence. Ça fausse silencieusement toute segmentation croisée derrière — la requête ne plante pas, elle donne juste un résultat qui n'a pas de sens.

## Piège n°2 — ne pas recalculer NTILE plusieurs fois

Une erreur fréquente en débutant : appeler `NTILE(4) OVER (...)` séparément dans chaque branche d'un `CASE WHEN`, ce qui relance le calcul de fenêtrage à chaque fois.

```sql
-- ❌ Redondant — NTILE recalculé 4 fois
CASE
  WHEN NTILE(4) OVER (ORDER BY montant DESC) = 1 THEN 'VIP'
  WHEN NTILE(4) OVER (ORDER BY montant DESC) = 2 THEN 'Bon client'
  WHEN NTILE(4) OVER (ORDER BY montant DESC) = 3 THEN 'Moyen'
  WHEN NTILE(4) OVER (ORDER BY montant DESC) = 4 THEN 'Faible'
END AS segment
```

```sql
-- ✅ Une seule passe : on calcule NTILE une fois, on le nomme ensuite
WITH quartiles AS (
  SELECT
    client_id,
    montant,
    NTILE(4) OVER (ORDER BY montant DESC) AS quartile_montant
  FROM clients
)
SELECT
  client_id,
  montant,
  CASE quartile_montant
    WHEN 1 THEN 'VIP'
    WHEN 2 THEN 'Bon client'
    WHEN 3 THEN 'Moyen'
    WHEN 4 THEN 'Faible'
  END AS segment
FROM quartiles;
```

Même résultat, mais plus lisible, plus facile à déboguer, et une seule fenêtre calculée.

## Piège n°3 — effectifs non parfaitement égaux

Si le nombre de lignes n'est pas exactement divisible par n, `NTILE` distribue le reste aux premiers groupes. Sur un dataset de 1003 clients en quartiles, tu peux avoir 251/251/251/250 plutôt que 4 groupes strictement identiques. C'est normal et attendu — pas la peine de forcer un ajustement manuel, mais utile à savoir si tu compares les effectifs exacts entre segments.

## Quartile vs tertile : quand choisir quoi

| Situation | Choix recommandé |
|---|---|
| Segmentation client générale (RFM, scoring) | Quartile (`NTILE(4)`) — standard du secteur |
| Peu de clients (échantillon petit, < 100) | Tertile (`NTILE(3)`) — évite des groupes trop petits pour être significatifs |
| Besoin de repérer une élite très restreinte | Décile (`NTILE(10)`) — isole le top 10% |
| Présentation à un public non technique | Tertile ou quartile — plus simple à expliquer que des déciles |

## À retenir pour l'oral / la présentation

Si on te demande "pourquoi des quartiles et pas des seuils fixes ?" : les quartiles s'adaptent automatiquement à la distribution réelle des données (pas de seuil arbitraire choisi à l'avance), et garantissent des groupes de taille comparable, ce qui rend les comparaisons entre segments plus solides statistiquement.
