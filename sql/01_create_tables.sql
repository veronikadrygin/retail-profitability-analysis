CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    product_category TEXT NOT NULL,
    product_cost NUMERIC(10, 2) NOT NULL,
    product_price NUMERIC(10, 2) NOT NULL,

    CHECK (product_cost > 0),
    CHECK (product_price > 0),
    CHECK (product_price > product_cost)
);


CREATE TABLE stores (
    store_id INTEGER PRIMARY KEY,
    store_name TEXT NOT NULL,
    store_city TEXT NOT NULL,
    store_location TEXT NOT NULL,
    store_open_date DATE NOT NULL
);


CREATE TABLE calendar (
    calendar_date DATE PRIMARY KEY
);


CREATE TABLE inventory (
    store_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    stock_on_hand INTEGER NOT NULL,

    PRIMARY KEY (store_id, product_id),

    FOREIGN KEY (store_id)
        REFERENCES stores(store_id),

    FOREIGN KEY (product_id)
        REFERENCES products(product_id),

    CHECK (stock_on_hand >= 0)
);


CREATE TABLE sales (
    sale_id INTEGER PRIMARY KEY,
    sale_date DATE NOT NULL,
    store_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    units INTEGER NOT NULL,

    FOREIGN KEY (sale_date)
        REFERENCES calendar(calendar_date),

    FOREIGN KEY (store_id)
        REFERENCES stores(store_id),

    FOREIGN KEY (product_id)
        REFERENCES products(product_id),

    CHECK (units > 0)
);
