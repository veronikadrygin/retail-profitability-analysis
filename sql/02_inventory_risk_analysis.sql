/*
QUESTION 1
Which store-product combinations have recent demand but insufficient
or unknown inventory?

FINDINGS
- 77 combinations had recent demand and confirmed zero stock.
- The highest-demand zero-stock case was Animal Figures at Maven Toys
  Culiacan 1, with 456 units sold during the latest 90 days.
- The lowest positive-stock coverage was approximately 0.4 days.
- 23 combinations had recent sales but no inventory record.
- All 23 missing-inventory combinations were Jenga and generated
  371 units during the latest 90 days.
- Missing inventory records are treated as data-investigation cases,
  not as zero-stock or replenishment cases.
*/
WITH recent_demand AS (
    SELECT
        store_id,
        product_id,
        SUM(units) AS recent_units_sold
    FROM sales
    WHERE sale_date BETWEEN DATE '2023-07-03' AND DATE '2023-09-30'
    GROUP BY
        store_id,
        product_id
),

coverage_data AS (
    SELECT
        rd.store_id,
        rd.product_id,
        rd.recent_units_sold,
        i.stock_on_hand,
		p.product_name,
		p.product_category,
		st.store_name,
		st.store_city,
		st.store_location,

        CASE
            WHEN i.stock_on_hand IS NULL
                THEN 'inventory_record_missing'
            WHEN i.stock_on_hand = 0
                THEN 'confirmed_zero_stock'
            ELSE 'positive_stock'
        END AS inventory_status,

        ROUND(
            i.stock_on_hand * 90.0 / rd.recent_units_sold,
            1
        ) AS days_of_stock_coverage

    FROM recent_demand AS rd
    LEFT JOIN inventory AS i
        ON rd.store_id = i.store_id
        AND rd.product_id = i.product_id
	JOIN products AS p
    ON rd.product_id = p.product_id

	JOIN stores AS st
    ON rd.store_id = st.store_id
)

SELECT
    store_id,
    store_name,
    store_city,
    store_location,
    product_id,
    product_name,
    product_category,
    recent_units_sold,
    stock_on_hand,
    inventory_status,
    days_of_stock_coverage
FROM coverage_data
WHERE inventory_status = 'inventory_record_missing'
ORDER BY recent_units_sold DESC;

/*
QUESTION 2
Which store-product combinations have positive stock but weak or
declining recent demand?

FINDINGS
- 93 store-product combinations had positive stock but no sales
  during the latest 90-day period.
- 38 had no sales in either 90-day period.
- 55 had previous sales but no sales in the latest period.
- These 93 combinations held 1,349 units in total.
- These results are investigation candidates, not automatic
  transfer or purchasing recommendations.
  - 35 store-product combinations had recent demand decline by at
  least 50% and estimated stock coverage above 180 days.
- These combinations held 946 units of inventory.
- Together with the 93 zero-recent-demand combinations, Question 2
  identified 128 distinct investigation candidates holding 2,295 units.
- The 180-day threshold is an analyst-defined review threshold,
  not a confirmed optimal inventory target.
*/

WITH demand_comparison AS (
	SELECT
	    i.store_id,
	    st.store_name,
	    i.product_id,
	    p.product_name,
	    i.stock_on_hand,
	
	    SUM(
	        CASE
	            WHEN s.sale_date BETWEEN DATE '2023-04-04' AND DATE '2023-07-02'
	            THEN s.units
	            ELSE 0
	        END
	    ) AS previous_units_sold,
	
	    SUM(
	        CASE
	            WHEN s.sale_date BETWEEN DATE '2023-07-03' AND DATE '2023-09-30'
	            THEN s.units
	            ELSE 0
	        END
	    ) AS recent_units_sold
	
	FROM inventory AS i
	
	JOIN stores AS st
	    ON i.store_id = st.store_id
	
	JOIN products AS p
	    ON i.product_id = p.product_id
	
	LEFT JOIN sales AS s
	    ON i.store_id = s.store_id
	    AND i.product_id = s.product_id
	    AND s.sale_date BETWEEN DATE '2023-04-04' AND DATE '2023-09-30'
	
	WHERE i.stock_on_hand > 0
	
	GROUP BY
	    i.store_id,
	    st.store_name,
	    i.product_id,
	    p.product_name,
	    i.stock_on_hand
	
	ORDER BY
	    recent_units_sold ASC,
	    i.stock_on_hand DESC
)
SELECT
    *,
    CASE
        WHEN previous_units_sold = 0
             AND recent_units_sold = 0
            THEN 'no_demand_in_both_periods'

        WHEN previous_units_sold > 0
             AND recent_units_sold = 0
            THEN 'recent_demand_stopped'
    END AS demand_status

FROM demand_comparison

WHERE recent_units_sold = 0

ORDER BY stock_on_hand DESC;