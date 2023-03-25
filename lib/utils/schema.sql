CREATE TABLE IF NOT EXISTS buyers (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL, 
    address TEXT NOT NULL,
    state TEXT NOT NULL,
    alias TEXT NOT NULL DEFAULT '',
    gst TEXT
);

CREATE TABLE IF NOT EXISTS "challans"(
    "id" INTEGER NOT NULL,
    "number" INTEGER NOT NULL,
    "session" TEXT NOT NULL,
    "created_at" TIMESTAMP with TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    "buyer" JSON NOT NULL,
    "cancelled" BOOLEAN NOT NULL DEFAULT '0',
    "products" JSON NOT NULL,
    "product_value" INTEGER NOT NULL,
    "notes" TEXT NOT NULL DEFAULT '',
    "delivered_by" TEXT NOT NULL,
    "vehicle_number" TEXT NOT NULL,
    "received" BOOLEAN NOT NULL DEFAULT '0',
    "digitally_signed" BOOLEAN NOT NULL DEFAULT '0'
);
