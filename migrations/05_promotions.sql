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

CREATE UNIQUE INDEX ON "promotion_products" ("promotion_id", "product_id");

CREATE UNIQUE INDEX ON "promotion_categories" ("promotion_id", "category_id");

COMMENT ON COLUMN "promotions"."percent" IS 'percent > 0 and percent <= 100';

COMMENT ON COLUMN "promotions"."ends_at" IS 'ends_at > starts_at';

COMMENT ON COLUMN "promotions"."max_uses" IS 'null = illimité, compte toutes les commandes de tous ses codes';

COMMENT ON COLUMN "promo_codes"."user_id" IS 'renseigné = code réservé à cette personne';

ALTER TABLE "promotion_products" ADD FOREIGN KEY ("promotion_id") REFERENCES "promotions" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "promotion_products" ADD FOREIGN KEY ("product_id") REFERENCES "products" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "promotion_categories" ADD FOREIGN KEY ("promotion_id") REFERENCES "promotions" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "promotion_categories" ADD FOREIGN KEY ("category_id") REFERENCES "categories" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "promo_codes" ADD FOREIGN KEY ("promotion_id") REFERENCES "promotions" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "promo_codes" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;
