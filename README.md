# Big Data Seeder

Un jeu de données e-commerce réaliste pour PostgreSQL : catalogue, clients, paniers, promotions et commandes, généré en SQL.

## Prérequis

- Docker
- Docker Compose
- Make

## Getting started

### 1. Démarrer la base

```sh
make up
```

Le conteneur `postgres` démarre avec la base `seeder` et le mot de passe `postgres`. Les migrations sont aussi chargées au premier démarrage via `docker-entrypoint-initdb.d`, mais `make seed` repart d'une base propre.

### 2. Vérifier les commandes disponibles

```sh
make
```

### 3. Charger les données

```sh
make seed
```

Cette commande reconstruit la base de zéro : `DROP`, `CREATE`, migrations, puis seeders. Les seeders se terminent par une batterie d'assertions (`seeders/99_checks.sql`) : si une donnée est incohérente, la transaction échoue et aucune ligne n'est conservée.

Par défaut `SCALE=1`, soit environ 50 000 clients, 5 000 produits, 30 000 paniers et 500 000 commandes. Pour changer de volume :

```sh
make seed SCALE=5
```

### 4. Explorer

```sh
make psql
```

```sql
SELECT status, count(*) FROM orders GROUP BY status;
```

Les requêtes d'analyse sont dans `scripts/` : panier moyen par pays ou par ville, clients les plus fidèles, produits jamais commandés, croissance mois par mois, etc.

---

## Base de données

Le schéma suit une boutique en ligne classique : un utilisateur a des adresses, un panier et des commandes. Les produits appartiennent à une marque et à des catégories arborescentes, et existent en variantes qui portent un historique de prix. Les promotions ciblent toute la commande, des produits ou des catégories, et sont appliquées via des codes promo.

![Diagramme de la base de données](db-diagram.png)

### Points de conception

**Prix historisés.** `product_prices` porte une date d'effet par ligne. Le prix d'une commande n'est jamais relu dans cette table : il est copié dans `order_items.unit_price` au moment de l'achat.

**Commandes figées.** `orders` copie l'adresse, l'email et le téléphone du client. Modifier une fiche client ne réécrit pas l'historique.

**Commande invité.** `orders.user_id` accepte `NULL`. Le seeder en produit environ 10 %.

**Promotions à trois portées.** `scope` vaut `order`, `products` ou `categories`. Les tables de liaison `promotion_products` et `promotion_categories` ne sont remplies que pour les portées correspondantes. `max_uses` compte les commandes de tous les codes d'une même promotion.

**Catégories en arbre.** `categories.parent_id` référence la même table. Les seeders produisent un arbre sur trois niveaux et rattachent chaque produit à une feuille.

---

## Structure du projet

```
migrations/   schéma SQL, appliqué dans l'ordre alphabétique
seeders/      génération des données puis assertions de cohérence
scripts/      requêtes d'analyse prêtes à l'emploi
Makefile      commandes make
db-diagram.png
```

---

## Commandes Make

| Commande | Effet |
| --- | --- |
| `make` | liste les commandes |
| `make up` | démarre le conteneur |
| `make down` | arrête et supprime le conteneur |
| `make seed` | reset, migrations, seeders |
| `make migrate` | migrations seules sur la base courante |
| `make db-reset` | supprime puis recrée la base vide |
| `make psql` | console SQL interactive |
| `make shell` | shell dans le conteneur |
