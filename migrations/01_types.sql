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
