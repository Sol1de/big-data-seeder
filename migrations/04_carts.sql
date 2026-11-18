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

COMMENT ON COLUMN "cart_items"."quantity" IS 'quantity > 0';

ALTER TABLE "carts" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "cart_items" ADD FOREIGN KEY ("cart_id") REFERENCES "carts" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "cart_items" ADD FOREIGN KEY ("product_variant_id") REFERENCES "product_variants" ("id") DEFERRABLE INITIALLY IMMEDIATE;
