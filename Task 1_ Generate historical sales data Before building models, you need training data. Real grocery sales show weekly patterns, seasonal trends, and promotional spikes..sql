-- Create dataset
CREATE SCHEMA IF NOT EXISTS `freshfoods`;

-- Generate 18 months of daily sales history
CREATE OR REPLACE TABLE `freshfoods.sales_history` AS
WITH date_series AS (
  SELECT date_day
  FROM UNNEST(GENERATE_DATE_ARRAY(
    DATE_SUB(CURRENT_DATE(), INTERVAL 540 DAY),
    DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY),
    INTERVAL 1 DAY
  )) AS date_day
),
products AS (
  SELECT product_name, base_sales FROM UNNEST([
    STRUCT('Avocados' AS product_name, 450 AS base_sales),
    STRUCT('Organic Milk' AS product_name, 320 AS base_sales),
    STRUCT('Strawberries' AS product_name, 280 AS base_sales)
  ])
)
SELECT 
  d.date_day,
  p.product_name,
  -- Simulate discount events (20% of days have promotions)
  CASE 
    WHEN RAND() < 0.20 THEN ROUND(RAND() * 0.3, 2)  -- 0-30% discount
    ELSE 0.0 
  END AS discount_percent,
  -- Mark holidays (simplified: first and last week of each month)
  CASE 
    WHEN EXTRACT(DAY FROM d.date_day) <= 7 
      OR EXTRACT(DAY FROM d.date_day) >= 24 
    THEN 1 
    ELSE 0 
  END AS is_holiday,
  -- Calculate realistic sales with noise and promotional lift
  CAST(
    p.base_sales 
    * (1 + RAND() * 0.3 - 0.15)  -- +/- 15% random variance
    * (1 + CASE WHEN RAND() < 0.20 THEN RAND() * 0.5 ELSE 0 END)  -- Promo boost
    * (1 + CASE WHEN EXTRACT(DAY FROM d.date_day) <= 7 THEN 0.25 ELSE 0 END)  -- Holiday boost
  AS INT64) AS sales_qty
FROM date_series d
CROSS JOIN products p;
