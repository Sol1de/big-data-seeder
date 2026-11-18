CREATE TYPE "promotion_scope" AS ENUM (
  'order',
  'products',
  'categories'
);

CREATE TYPE "order_status" AS ENUM (
  'pending',
  'paid',
  'shipped',
  'delivered',
  'cancelled'
);

CREATE TABLE "users" (
  "id" uuid PRIMARY KEY,
  "email" varchar UNIQUE NOT NULL,
  "phone" varchar UNIQUE,
  "password_hash" varchar NOT NULL,
  "first_name" varchar,
  "last_name" varchar,
  "username" varchar UNIQUE NOT NULL,
  "is_active" boolean NOT NULL DEFAULT true,
  "created_at" timestamp NOT NULL DEFAULT (now()),
  "updated_at" timestamp NOT NULL DEFAULT (now())
);

CREATE TABLE "addresses" (
  "id" uuid PRIMARY KEY,
  "user_id" uuid NOT NULL,
  "name" varchar NOT NULL,
  "address" varchar NOT NULL,
  "city" varchar NOT NULL,
  "state" varchar,
  "postal_code" varchar NOT NULL,
  "country_code" char(2) NOT NULL,
  "created_at" timestamp NOT NULL DEFAULT (now()),
  "updated_at" timestamp NOT NULL DEFAULT (now())
);

CREATE TABLE "carts" (
  "id" uuid PRIMARY KEY,
  "user_id" uuid UNIQUE NOT NULL,
  "created_at" timestamp NOT NULL DEFAULT (now()),
  "updated_at" timestamp NOT NULL DEFAULT (now())
);

CREATE TABLE "cart_items" (
  "id" uuid PRIMARY KEY,
  "cart_id" uuid NOT NULL,
  "product_variant_id" uuid NOT NULL,
  "quantity" int NOT NULL
);

CREATE TABLE "brands" (
  "id" uuid PRIMARY KEY,
  "name" varchar NOT NULL,
  "commercial_name" varchar UNIQUE NOT NULL,
  "created_at" timestamp NOT NULL DEFAULT (now()),
  "updated_at" timestamp NOT NULL DEFAULT (now())
);

CREATE TABLE "products" (
  "id" uuid PRIMARY KEY,
  "name" varchar NOT NULL,
  "description" text,
  "brand_id" uuid NOT NULL,
  "created_at" timestamp NOT NULL DEFAULT (now()),
  "updated_at" timestamp NOT NULL DEFAULT (now())
);

CREATE TABLE "product_variants" (
  "id" uuid PRIMARY KEY,
  "product_id" uuid NOT NULL,
  "reference" varchar UNIQUE NOT NULL,
  "height" varchar NOT NULL,
  "color" varchar NOT NULL,
  "created_at" timestamp NOT NULL DEFAULT (now()),
  "updated_at" timestamp NOT NULL DEFAULT (now())
);

CREATE TABLE "product_prices" (
  "id" uuid PRIMARY KEY,
  "product_variant_id" uuid NOT NULL,
  "price" decimal(10,2) NOT NULL,
  "currency" char(3) NOT NULL,
  "valid_from" timestamp NOT NULL
);

CREATE TABLE "categories" (
  "id" uuid PRIMARY KEY,
  "name" varchar NOT NULL,
  "parent_id" uuid
);

CREATE TABLE "product_categories" (
  "id" uuid PRIMARY KEY,
  "product_id" uuid NOT NULL,
  "category_id" uuid NOT NULL
);

CREATE TABLE "promotions" (
  "id" uuid PRIMARY KEY,
  "name" varchar NOT NULL,
  "percent" decimal(5,2) NOT NULL,
  "scope" promotion_scope NOT NULL,
  "starts_at" timestamp NOT NULL,
  "ends_at" timestamp NOT NULL,
  "max_uses" int,
  "created_at" timestamp NOT NULL DEFAULT (now()),
  "updated_at" timestamp NOT NULL DEFAULT (now())
);

CREATE TABLE "promotion_products" (
  "id" uuid PRIMARY KEY,
  "promotion_id" uuid NOT NULL,
  "product_id" uuid NOT NULL
);

CREATE TABLE "promotion_categories" (
  "id" uuid PRIMARY KEY,
  "promotion_id" uuid NOT NULL,
  "category_id" uuid NOT NULL
);

CREATE TABLE "promo_codes" (
  "id" uuid PRIMARY KEY,
  "promotion_id" uuid NOT NULL,
  "code" varchar UNIQUE NOT NULL,
  "user_id" uuid,
  "once_per_customer" boolean NOT NULL DEFAULT false,
  "created_at" timestamp NOT NULL DEFAULT (now()),
  "updated_at" timestamp NOT NULL DEFAULT (now())
);

CREATE TABLE "orders" (
  "id" uuid PRIMARY KEY,
  "public_id" varchar UNIQUE NOT NULL,
  "user_id" uuid,
  "promo_code_id" uuid,
  "status" order_status NOT NULL DEFAULT 'pending',
  "email" varchar NOT NULL,
  "phone" varchar,
  "first_name" varchar NOT NULL,
  "last_name" varchar NOT NULL,
  "address" varchar NOT NULL,
  "city" varchar NOT NULL,
  "state" varchar,
  "postal_code" varchar NOT NULL,
  "country_code" char(2) NOT NULL,
  "created_at" timestamp NOT NULL DEFAULT (now()),
  "updated_at" timestamp NOT NULL DEFAULT (now())
);

CREATE TABLE "order_items" (
  "id" uuid PRIMARY KEY,
  "order_id" uuid NOT NULL,
  "product_variant_id" uuid NOT NULL,
  "quantity" int NOT NULL,
  "unit_price" decimal(10,2) NOT NULL,
  "currency" char(3) NOT NULL,
  "discount_percent" decimal(5,2) NOT NULL DEFAULT 0
);

CREATE UNIQUE INDEX ON "promotion_products" ("promotion_id", "product_id");

CREATE UNIQUE INDEX ON "promotion_categories" ("promotion_id", "category_id");

COMMENT ON COLUMN "cart_items"."quantity" IS 'quantity > 0';

COMMENT ON COLUMN "promotions"."percent" IS 'percent > 0 and percent <= 100';

COMMENT ON COLUMN "promotions"."ends_at" IS 'ends_at > starts_at';

COMMENT ON COLUMN "promotions"."max_uses" IS 'null = illimité, compte toutes les commandes de tous ses codes';

COMMENT ON COLUMN "promo_codes"."user_id" IS 'renseigné = code réservé à cette personne';

COMMENT ON COLUMN "orders"."user_id" IS 'null = commande invité';

COMMENT ON COLUMN "orders"."promo_code_id" IS 'une ligne = une utilisation du code';

COMMENT ON COLUMN "orders"."email" IS 'contact copié à la commande, compte ou invité';

COMMENT ON COLUMN "orders"."address" IS 'adresse de livraison copiée, jamais modifiée';

COMMENT ON COLUMN "order_items"."unit_price" IS 'prix accepté à l''achat, copié depuis product_prices, jamais modifié';

COMMENT ON COLUMN "order_items"."discount_percent" IS 'remise appliquée à cette ligne, copiée à l''achat';

ALTER TABLE "addresses" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "carts" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "cart_items" ADD FOREIGN KEY ("cart_id") REFERENCES "carts" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "cart_items" ADD FOREIGN KEY ("product_variant_id") REFERENCES "product_variants" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "products" ADD FOREIGN KEY ("brand_id") REFERENCES "brands" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "product_variants" ADD FOREIGN KEY ("product_id") REFERENCES "products" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "product_prices" ADD FOREIGN KEY ("product_variant_id") REFERENCES "product_variants" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "categories" ADD FOREIGN KEY ("parent_id") REFERENCES "categories" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "product_categories" ADD FOREIGN KEY ("product_id") REFERENCES "products" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "product_categories" ADD FOREIGN KEY ("category_id") REFERENCES "categories" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "promotion_products" ADD FOREIGN KEY ("promotion_id") REFERENCES "promotions" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "promotion_products" ADD FOREIGN KEY ("product_id") REFERENCES "products" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "promotion_categories" ADD FOREIGN KEY ("promotion_id") REFERENCES "promotions" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "promotion_categories" ADD FOREIGN KEY ("category_id") REFERENCES "categories" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "promo_codes" ADD FOREIGN KEY ("promotion_id") REFERENCES "promotions" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "promo_codes" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "orders" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "orders" ADD FOREIGN KEY ("promo_code_id") REFERENCES "promo_codes" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "order_items" ADD FOREIGN KEY ("order_id") REFERENCES "orders" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "order_items" ADD FOREIGN KEY ("product_variant_id") REFERENCES "product_variants" ("id") DEFERRABLE INITIALLY IMMEDIATE;
