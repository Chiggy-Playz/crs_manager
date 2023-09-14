CREATE TABLE IF NOT EXISTS buyers (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL, 
    address TEXT NOT NULL,
    state TEXT NOT NULL,
    alias TEXT NOT NULL DEFAULT '',
    gst TEXT
);

CREATE TABLE IF NOT EXISTS "challans"(
    "id" SERIAL,
    "number" INTEGER NOT NULL,
    "session" TEXT NOT NULL,
    "created_at" TIMESTAMP with TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    "buyer" JSON NOT NULL,
    "cancelled" BOOLEAN NOT NULL DEFAULT '0',
    "products" JSON NOT NULL,
    "products_value" INTEGER NOT NULL,
    -- Null means bill hasnt been created yet
    "bill_number" BIGINT,
    "notes" TEXT NOT NULL DEFAULT '',
    "delivered_by" TEXT NOT NULL,
    "vehicle_number" TEXT NOT NULL,
    "received" BOOLEAN NOT NULL DEFAULT '0',
    "digitally_signed" BOOLEAN NOT NULL DEFAULT '0',
    "photo_id" TEXT NOT NULL DEFAULT '',
    PRIMARY KEY (number, session)
);

CREATE TABLE IF NOT EXISTS "secrets"(
    "name" TEXT NOT NULL,
    "value" JSON NOT NULL,
    PRIMARY KEY (name)
);


----------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pseudo_encrypt(value int) returns int AS $$
DECLARE
l1 int;
l2 int;
r1 int;
r2 int;
i int:=0;
BEGIN
 l1:= (value >> 16) & 65535;
 r1:= value & 65535;
 WHILE i < 3 LOOP
   l2 := r1;
   r2 := l1 # ((((1368 * r1 + 150889) % 714025) / 714025.0) * 32767)::int;

   l1 := l2;
   r1 := r2;
   i := i + 1;
 END LOOP;
 return ((r1 << 16) + l1);
END;
$$ LANGUAGE plpgsql strict immutable;
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION stringify_bigint(n bigint) RETURNS text
    LANGUAGE plpgsql IMMUTABLE STRICT AS $$
DECLARE
 alphabet text:='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
 base int:=length(alphabet);
 _n bigint:=abs(n);
 output text:='';
BEGIN
 LOOP
   output := output || substr(alphabet, 1+(_n%base)::int, 1);
   _n := _n / base;
   EXIT WHEN _n=0;
 END LOOP;
 RETURN output;
END $$;
----------------------------------------------------------------------------------------------

/*

    templates.field is like 
    {
        "name": "name",
        "type": "text | number | date | select | checkbox",
        "required": true | false
    }

    assets.custom_fields is like 
    {
        "field_name": "value"
    }

    assets.additional_costs is like
    {
        "Reason": "Money Spent"
    }

    history.changes is like 
    {
        "custom_fields" : [
            {
                "fieldName": "name",
                "before": "before",
                "after": "after",
            },
        ],
        "fieldName": {
            "before": "before",
            "after": "after",
        }
    }

*/

CREATE TABLE IF NOT EXISTS "templates"(
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    "fields" JSON NOT NULL,
    "product_link" JSON NOT NULL DEFAULT '{"Description": "","Serial": "","Quantity": "","Quantity Unit": "","Additional Description": ""}',
    "metadata" TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS "assets"(
    "id" SERIAL PRIMARY KEY,
    "uuid" TEXT UNIQUE NOT NULL,
    "created_at" TIMESTAMP with TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    "location" TEXT NOT NULL,
    "purchase_cost" INTEGER NOT NULL,
    "purchase_date" TIMESTAMP with TIME ZONE NOT NULL,
    "additional_cost" JSON NOT NULL DEFAULT '{}',
    "purchased_from" TEXT NOT NULL,
    "template" INTEGER NOT NULL REFERENCES templates(id),
    "custom_fields" JSON NOT NULL,
    "notes" TEXT NOT NULL DEFAULT '',
    "recovered_cost" INTEGER NOT NULL DEFAULT 0
);

CREATE OR REPLACE FUNCTION asset_insert() RETURNS trigger AS '
     BEGIN
         NEW.uuid = stringify_bigint(pseudo_encrypt(NEW.id));
         RETURN NEW;
     END;
 ' LANGUAGE plpgsql;


CREATE TRIGGER asset_insert BEFORE INSERT OR UPDATE ON assets FOR
 EACH ROW EXECUTE PROCEDURE asset_insert();

CREATE TABLE IF NOT EXISTS "assets_history"(
    id SERIAL PRIMARY KEY,
    "asset_uuid" TEXT NOT NULL,
    "when" TIMESTAMP with TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    "changes" JSON NOT NULL,
    "challan_id" INTEGER,
    "challan_type" INTEGER
)

----------------------------------------------------------------------------------------------

-- Inward Challan

CREATE TABLE IF NOT EXISTS "inward_challans" (

    "id" SERIAL,
    "number" INTEGER NOT NULL,
    "session" TEXT NOT NULL,
    "created_at" TIMESTAMP with TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    "buyer" JSON NOT NULL,
    "products" JSON NOT NULL,
    "products_value" INTEGER NOT NULL,
    "notes" TEXT NOT NULL DEFAULT '',
    "received_by" TEXT NOT NULL,
    "vehicle_number" TEXT NOT NULL,
    "cancelled" BOOLEAN NOT NULL DEFAULT '0',
    PRIMARY KEY (id)
);

)