# Segmentation RFM (Récence, Fréquence, Montant)

## Principe

La segmentation RFM classe chaque client selon 3 axes indépendants :

- **Récence (R)** : depuis combien de temps le client n'a pas acheté ? (fraîcheur de la relation)
- **Fréquence (F)** : combien de commandes a-t-il passées ? (fidélité / régularité)
- **Montant (M)** : combien a-t-il dépensé au total ? (poids financier réel)

Chaque axe est découpé en quartiles (voir chapitre `NTILE`), puis les 3 scores sont croisés pour former des segments actionnables (VIP, à fidéliser, en risque de départ, inactif...).

**Point clé :** RFM se base sur des seuils statistiques (quartiles), pas sur des seuils arbitraires choisis à la main. C'est ce qui rend la méthode objective et reproductible sur n'importe quel dataset client — banking, gaming, SaaS, e-commerce.

## Étape 1 — Récence

```sql
WITH recency_data AS (
  SELECT
    c.customer_unique_id,
    DATE_DIFF(
      (SELECT MAX(DATE(order_purchase_timestamp)) FROM `dataset.orders`),
      MAX(DATE(o.order_purchase_timestamp)),
      DAY
    ) AS recency_days
  FROM `dataset.orders` AS o
  INNER JOIN `dataset.customers` AS c
    ON o.customer_id = c.customer_id
  WHERE o.order_status = 'delivered'  -- décision à prendre consciemment, voir Piège n°2
  GROUP BY c.customer_unique_id
)
```

**⚠️ Piège n°1 — la date de référence.** Ne jamais utiliser `CURRENT_DATE()` sur un dataset historique figé (comme un extrait Kaggle ou un exercice pédagogique). Le dataset s'arrête à une date donnée ; si tu compares à aujourd'hui, tous les clients paraissent "inactifs depuis des années" et le Recency perd tout son sens. Toujours utiliser `MAX(date_de_commande)` du dataset lui-même comme date de référence.

**⚠️ Piège n°2 — le statut de la commande.** Inclure ou exclure les commandes annulées/non livrées change le sens du calcul. Si tu comptes une commande annulée comme un "achat récent", tu surestimes l'engagement réel du client. Le filtre `WHERE order_status = 'delivered'` est un choix à documenter, pas un détail à laisser par défaut.

## Étape 2 — Fréquence

```sql
WITH frequency_data AS (
  SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS frequency_orders
  FROM `dataset.orders` AS o
  INNER JOIN `dataset.customers` AS c
    ON o.customer_id = c.customer_id
  WHERE o.order_status = 'delivered'
  GROUP BY c.customer_unique_id
)
```

**⚠️ Piège — `customer_id` vs identifiant client unique.** Sur des datasets comme Olist, un même client réel peut avoir un `customer_id` différent à chaque commande (car l'identifiant est généré par commande, pas par client). Si tu groupes par `customer_id`, chaque commande devient artificiellement "un nouveau client à commande unique", et toute la Fréquence est faussée à la baisse. Toujours vérifier s'il existe un identifiant stable dédié (type `customer_unique_id`) et l'utiliser pour le `GROUP BY` et les jointures.

## Étape 3 — Montant

```sql
WITH monetary_data AS (
  SELECT
    c.customer_unique_id,
    SUM(p.payment_value) AS monetary_total
  FROM `dataset.orders` AS o
  INNER JOIN `dataset.customers` AS c
    ON o.customer_id = c.customer_id
  INNER JOIN `dataset.order_payments` AS p
    ON o.order_id = p.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY c.customer_unique_id
)
```

**⚠️ Piège — les doublons de paiement.** Si une commande a plusieurs lignes de paiement (paiement fractionné, plusieurs moyens de paiement), un `JOIN` direct sur `order_payments` peut dupliquer la commande. Vérifie que le `SUM` reste cohérent avec le nombre de commandes réelles (comparer avec `COUNT(DISTINCT order_id)` du même client comme garde-fou).

## Étape 4 — Attribution des quartiles (voir chapitre NTILE)

```sql
WITH rfm_scores AS (
  SELECT
    r.customer_unique_id,
    NTILE(4) OVER (ORDER BY r.recency_days DESC) AS r_score,   -- moins de jours = mieux → DESC
    NTILE(4) OVER (ORDER BY f.frequency_orders ASC) AS f_score, -- plus de commandes = mieux → ASC
    NTILE(4) OVER (ORDER BY m.monetary_total ASC) AS m_score    -- plus de montant = mieux → ASC
  FROM recency_data r
  JOIN frequency_data f USING (customer_unique_id)
  JOIN monetary_data m USING (customer_unique_id)
)
```

**Rappel important (voir chapitre NTILE, Piège n°1) :** le sens du `ORDER BY` doit être cohérent avec le sens "meilleur client". Pour Récence, moins de jours = meilleur, donc `DESC` sur les jours pour que le score 4 soit le meilleur. Pour Fréquence et Montant, plus = meilleur, donc `ASC`.

## Étape 5 — Croisement en segments nommés

Une fois les 3 scores obtenus (1 à 4 chacun), on les croise pour nommer des segments métier. Exemple de logique simplifiée (à adapter selon le contexte) :

```sql
SELECT
  customer_unique_id,
  r_score, f_score, m_score,
  CASE
    WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'VIP'
    WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'Risque de départ - VIP'
    WHEN r_score >= 3 AND f_score <= 2 THEN 'À fidéliser - Potentiel haut'
    WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Inactif'
    WHEN r_score <= 2 THEN 'Risque de départ'
    ELSE 'Moyenne'
  END AS segment_rfm
FROM rfm_scores;
```

Les seuils exacts (≥3, ≤2...) sont à ajuster selon la distribution réelle du dataset et le nombre de segments souhaité — l'important est que la logique reste documentée et reproductible.

## Checklist avant de lancer l'analyse

- [ ] Date de référence = `MAX(date)` du dataset, pas `CURRENT_DATE()`
- [ ] Identifiant client stable utilisé pour tous les `GROUP BY` (pas un ID généré par commande)
- [ ] Statut de commande (`delivered` ou tout) choisi consciemment et documenté
- [ ] Sens du `ORDER BY` dans chaque `NTILE` cohérent avec "meilleur client" (attention Récence = sens inversé)
- [ ] Vérification qu'un `JOIN` sur les paiements ne duplique pas les commandes

## Pourquoi cette méthode est transférable

Le squelette R/F/M ne change pas d'un secteur à l'autre — seule la donnée source change :

| Secteur | Récence | Fréquence | Montant |
|---|---|---|---|
| E-commerce / retail | Dernier achat | Nb de commandes | CA total |
| Banking | Dernière transaction | Nb de transactions | Solde / volume de transactions |
| Gaming | Dernière session | Nb de sessions | Montant dépensé en achats in-game |
| SaaS | Dernière connexion | Fréquence d'usage | MRR / valeur du contrat |

C'est cette transférabilité qui rend RFM particulièrement utile comme pièce de portfolio : la même mécanique de requête démontre une compétence directement applicable au banking.
