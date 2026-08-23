CREATE OR REPLACE VIEW vw_inventory_risk_analysis AS

WITH sales_comparison AS (
    SELECT
        store_id,
        product_id,

        SUM(
            CASE
                WHEN sale_date BETWEEN DATE '2023-04-04'
                                   AND DATE '2023-07-02'
                THEN units
                ELSE 0
            END
        ) AS previous_units_sold,

        SUM(
            CASE
                WHEN sale_date BETWEEN DATE '2023-07-03'
                                   AND DATE '2023-09-30'
                THEN units
                ELSE 0
            END
        ) AS recent_units_sold

    FROM sales

    WHERE sale_date BETWEEN DATE '2023-04-04'
                        AND DATE '2023-09-30'

    GROUP BY
        store_id,
        product_id
)

SELECT
    st.store_id,
    st.store_name,
    st.store_city,
    st.store_location,

    p.product_id,
    p.product_name,
    p.product_category,
    p.product_cost,
    p.product_price,

    i.stock_on_hand,

    CASE
        WHEN i.stock_on_hand IS NULL
            THEN 'inventory_record_missing'
        WHEN i.stock_on_hand = 0
            THEN 'confirmed_zero_stock'
        ELSE 'positive_stock'
    END AS inventory_status,

    COALESCE(
        sc.previous_units_sold,
        0
    ) AS previous_units_sold,

    COALESCE(
        sc.recent_units_sold,
        0
    ) AS recent_units_sold,

    ROUND(
        COALESCE(sc.recent_units_sold, 0) / 90.0,
        2
    ) AS average_daily_units,

    CASE
        WHEN i.stock_on_hand IS NULL
            THEN NULL
        WHEN COALESCE(sc.recent_units_sold, 0) = 0
            THEN NULL
        ELSE ROUND(
            i.stock_on_hand * 90.0 / sc.recent_units_sold,
            1
        )
    END AS days_of_stock_coverage,

    CASE
        WHEN COALESCE(sc.previous_units_sold, 0) = 0
            THEN NULL
        ELSE ROUND(
            (
                COALESCE(sc.recent_units_sold, 0)
                - sc.previous_units_sold
            ) * 100.0 / sc.previous_units_sold,
            1
        )
    END AS demand_change_percent,

    ROUND(
        p.product_price - p.product_cost,
        2
    ) AS unit_margin,

    ROUND(
        COALESCE(sc.recent_units_sold, 0)
        * p.product_price,
        2
    ) AS estimated_recent_revenue,

    ROUND(
        COALESCE(sc.recent_units_sold, 0)
        * (p.product_price - p.product_cost),
        2
    ) AS estimated_recent_gross_profit,

    CASE
        WHEN i.stock_on_hand IS NULL
            THEN NULL
        ELSE ROUND(
            i.stock_on_hand * p.product_cost,
            2
        )
    END AS inventory_value_at_cost

FROM stores AS st

CROSS JOIN products AS p

LEFT JOIN inventory AS i
    ON st.store_id = i.store_id
    AND p.product_id = i.product_id

LEFT JOIN sales_comparison AS sc
    ON st.store_id = sc.store_id
    AND p.product_id = sc.product_id;