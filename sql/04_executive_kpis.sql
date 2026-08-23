/*
EXECUTIVE KPI SUMMARY

Default screening thresholds:
- Low coverage: 7 days or fewer
- High coverage: 120 days or more

The thresholds remain adjustable in Tableau.
*/


-- KPI 1: Replenishment candidates

SELECT
    COUNT(*) AS replenishment_candidates,
    ROUND(
        SUM(estimated_recent_gross_profit),
        2
    ) AS estimated_recent_gross_profit

FROM vw_inventory_risk_analysis

WHERE inventory_status = 'confirmed_zero_stock'
   OR (
        inventory_status = 'positive_stock'
        AND recent_units_sold > 0
        AND days_of_stock_coverage <= 7
   );

/*
Result:
369 replenishment candidates generated approximately
$198,038.00 in estimated gross profit during the latest 90 days.
*/


-- KPI 2: Excess-stock candidates

SELECT
    COUNT(*) AS excess_stock_candidates,
    ROUND(
        SUM(inventory_value_at_cost),
        2
    ) AS inventory_value_at_cost

FROM vw_inventory_risk_analysis

WHERE inventory_status = 'positive_stock'
  AND (
        recent_units_sold = 0
        OR days_of_stock_coverage >= 120
  );

/*
Result:
177 excess-stock candidates hold approximately
$40,023.79 of inventory at cost.
*/


-- KPI 3: Active combinations with missing inventory records

SELECT
    COUNT(*) AS active_missing_inventory_records,
    SUM(recent_units_sold) AS recent_units_sold,
    ROUND(
        SUM(estimated_recent_gross_profit),
        2
    ) AS estimated_recent_gross_profit

FROM vw_inventory_risk_analysis

WHERE inventory_status = 'inventory_record_missing'
  AND recent_units_sold > 0;

/*
Result:
23 store-product combinations with missing inventory records
generated 371 recent units and approximately $2,597.00
in estimated gross profit.
*/