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

COMMENT ON COLUMN "orders"."user_id" IS 'null = commande invité';

COMMENT ON COLUMN "orders"."promo_code_id" IS 'une ligne = une utilisation du code';

COMMENT ON COLUMN "orders"."email" IS 'contact copié à la commande, compte ou invité';

COMMENT ON COLUMN "orders"."address" IS 'adresse de livraison copiée, jamais modifiée';

COMMENT ON COLUMN "order_items"."unit_price" IS 'prix accepté à l''achat, copié depuis product_prices, jamais modifié';

COMMENT ON COLUMN "order_items"."discount_percent" IS 'remise appliquée à cette ligne, copiée à l''achat';

ALTER TABLE "orders" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "orders" ADD FOREIGN KEY ("promo_code_id") REFERENCES "promo_codes" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "order_items" ADD FOREIGN KEY ("order_id") REFERENCES "orders" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "order_items" ADD FOREIGN KEY ("product_variant_id") REFERENCES "product_variants" ("id") DEFERRABLE INITIALLY IMMEDIATE;
