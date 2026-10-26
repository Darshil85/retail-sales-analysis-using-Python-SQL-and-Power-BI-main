/* ============================================================
   MULTI-STORE RETAIL ANALYTICS
   SQL ANALYSIS
   ============================================================

   Dataset:
   Multi-Store Retail POS

   Analysis Period:
   2024-2025

   Database:
   retail_analytics

   Table:
   transactions

   ============================================================
   1. OVERALL BUSINESS PERFORMANCE
   ============================================================ */


/* ------------------------------------------------------------
   QUERY 01 — Validate all rows were imported
   ------------------------------------------------------------ */

-- Validating all rows are imported. There should 970838 rows imported.
SELECT
COUNT(*)
FROM
transactions;

-- NOTE / FINDING:
-- Expected dataset size is 970,838 transaction line items.


/* ------------------------------------------------------------
   QUERY 02 — Validate customer_id null transformation
   ------------------------------------------------------------ */

SELECT
COUNT(DISTINCT transaction_id) AS total_transactions
FROM
transactions
WHERE
event_type = 'Payment';

-- NOTE / FINDING:
-- The query validates the number of unique payment transactions
-- after customer_id cleaning.


/* ------------------------------------------------------------
   QUERY 03 — Validate transaction line distribution
   ------------------------------------------------------------ */

-- Validating Transaction line distribution.
WITH line_items AS(
SELECT
transaction_id, COUNT(transaction_id) AS transactions
FROM
transactions
WHERE event_type = 'Payment'
GROUP BY transaction_id)
SELECT
COUNT(transaction_id) AS customer_count, transactions
FROM
line_items
GROUP BY transactions;

-- NOTE / FINDING:
-- Transactions are multi-line orders. The recorded distribution
-- includes:
-- 1 line: 317,999 transactions
-- 2 lines: 160,319 transactions
-- 3 lines: 68,944 transactions
-- 4 lines: 28,980 transactions
-- The average order contains approximately 1.67 line items.


/* ------------------------------------------------------------
   QUERY 04 — Validate refund quantities
   ------------------------------------------------------------ */

-- Validating all the quantity in the refund event_type are negative.
SELECT
quantity
FROM
transactions
WHERE
event_type = 'Refund'
GROUP BY quantity;

-- NOTE / FINDING:
-- Refund transactions use negative quantities, allowing refunds
-- to be incorporated naturally into net-unit calculations.


/* ------------------------------------------------------------
   QUERY 05 — Overall financial totals
   ------------------------------------------------------------ */

SELECT
SUM(gross_sales) AS gross_sales,
SUM(discount * -1) AS dsicount,
SUM(net_sales) AS net_sales,
SUM(tax) AS tax,
SUM(total_collected) AS total_collected,
SUM(gross_profit) AS gross_profit
FROM
transactions;

-- NOTE / FINDING:
-- The dataset generates $46.60M in net sales and $25.78M in
-- gross profit across the two-year period.


/* ------------------------------------------------------------
   QUERY 06 — Validate gross profit calculation
   ------------------------------------------------------------ */

WITH total_cte AS (
SELECT
line_item_id, quantity * unit_cost AS total_cost
FROM
transactions)
SELECT
t.total_collected - tt.total_cost - t.tax, t.gross_profit
FROM
transactions t
JOIN
total_cte tt ON t.line_item_id = tt.line_item_id;

-- NOTE / FINDING:
-- This validates the relationship between collected revenue,
-- tax, product cost and gross profit at line-item level.


/* ------------------------------------------------------------
   QUERY 07 — Total payment transactions
   ------------------------------------------------------------ */

SELECT
COUNT(DISTINCT transaction_id) AS total_transactions
FROM
transactions
WHERE
event_type = 'Payment';

-- NOTE / FINDING:
-- The authoritative final transaction count is 576,242 payment
-- transactions.


/* ------------------------------------------------------------
   QUERY 08 — Total net units sold
   ------------------------------------------------------------ */

SELECT
SUM(quantity) AS net_units_sold
FROM
transactions;

-- NOTE / FINDING:
-- Total net units sold = 1,173,116.


/* ------------------------------------------------------------
   QUERY 09 — Average Order Value
   ------------------------------------------------------------ */

SELECT
ROUND(SUM(net_sales) / COUNT(DISTINCT CASE
WHEN event_type = 'Payment' THEN transaction_id
END),
2) AS avg_order_value
FROM
transactions;

-- NOTE / FINDING:
-- AOV is calculated using net sales divided by payment
-- transactions.


/* ------------------------------------------------------------
   QUERY 10 — Total gross profit
   ------------------------------------------------------------ */

SELECT
SUM(gross_profit) AS total_gross_profit
FROM
transactions;

-- NOTE / FINDING:
-- Total gross profit over the two-year period =
-- $25,784,056.34.


/* ------------------------------------------------------------
   QUERY 11 — Gross profit margin
   ------------------------------------------------------------ */

SELECT
ROUND(100 * SUM(gross_profit) / SUM(net_sales),
2) AS gross_profit_margin
FROM
transactions;

-- NOTE / FINDING:
-- Overall gross profit margin is approximately 55.34%.


/* ------------------------------------------------------------
   QUERY 12 — Total quantity returned
   ------------------------------------------------------------ */

SELECT
SUM(quantity * -1) AS total_quantity_returned
FROM
transactions
WHERE
event_type = 'Refund';

-- NOTE / FINDING:
-- Refund quantities are converted to positive values to report
-- the total quantity returned.


/* ------------------------------------------------------------
   QUERY 13 — Total amount refunded
   ------------------------------------------------------------ */

SELECT
SUM(net_sales * -1) AS total_amount_refunded
FROM
transactions
WHERE
event_type = 'Refund';

-- NOTE / FINDING:
-- Refund values are converted to positive values for reporting.


/* ============================================================
   2. YEARLY PERFORMANCE
   ============================================================ */


/* ------------------------------------------------------------
   QUERY 14 — Monthly performance
   ------------------------------------------------------------ */

SELECT
DATE_FORMAT(transaction_date, '%Y-%m') AS 'year_month',
SUM(net_sales) AS net_sales,
COUNT(DISTINCT CASE
WHEN event_type = 'Payment' THEN transaction_id
END) AS transactions,
SUM(gross_profit) AS gross_profit,
SUM(net_sales) / COUNT(DISTINCT CASE
WHEN event_type = 'Payment' THEN transaction_id
END) AS AOV,
100 * SUM(gross_profit) / SUM(net_sales) AS gross_margin
FROM
transactions
GROUP BY DATE_FORMAT(transaction_date, '%Y-%m')
ORDER BY `year_month`;

-- NOTE / FINDING:
-- Monthly analysis provides the foundation for identifying
-- seasonality, sales trends, transaction growth and margin
-- movements throughout 2024-2025.
--
-- Example:
-- 2024-01 net sales = $1,385,911.59
-- 2024-02 net sales = $1,680,416.99
-- 2024-03 net sales = $1,921,063.06


/* ------------------------------------------------------------
   QUERY 15 — Yearly performance
   ------------------------------------------------------------ */

SELECT
DATE_FORMAT(transaction_date, '%Y') AS 'year',
SUM(net_sales) AS net_sales,
COUNT(DISTINCT CASE
WHEN event_type = 'Payment' THEN transaction_id
END) AS transactions,
SUM(gross_profit) AS gross_profit,
SUM(net_sales) / COUNT(DISTINCT CASE
WHEN event_type = 'Payment' THEN transaction_id
END) AS AOV,
100 * SUM(gross_profit) / SUM(net_sales) AS gross_margin
FROM
transactions
GROUP BY DATE_FORMAT(transaction_date, '%Y')
ORDER BY `year`;

-- NOTE / FINDING:
-- 2024:
-- Net sales = $22,675,326.92
-- Transactions = 280,270
-- Gross profit = $12,544,958.43
-- AOV = $80.91
-- Gross margin = 55.32%
--
-- 2025:
-- Net sales = $23,919,846.35
-- Transactions = 295,972
-- Gross profit = $13,239,097.91
-- AOV = $80.82
-- Gross margin = 55.35%
--
-- The business grew in 2025 primarily through higher transaction
-- volume, while AOV remained essentially flat.


/* ============================================================
   3. STORE ANALYSIS
   ============================================================ */


/* ------------------------------------------------------------
   QUERY 16 — Store performance
   ------------------------------------------------------------ */

SELECT
location,
SUM(net_sales) AS net_sales,
COUNT(DISTINCT CASE
WHEN event_type = 'Payment' THEN transaction_id
END) AS transactions,
SUM(gross_profit) AS gross_profit,
SUM(net_sales) / COUNT(DISTINCT CASE
WHEN event_type = 'Payment' THEN transaction_id
END) AS AOV,
100 * SUM(gross_profit) / SUM(net_sales) AS gross_margin
FROM
transactions
GROUP BY location;

-- NOTE / FINDING:
-- Store-level performance highlights meaningful differences in
-- revenue, transaction volume, AOV and profitability across the
-- 30-store network.


/* ------------------------------------------------------------
   QUERY 17 — Store sales YoY change
   ------------------------------------------------------------ */

WITH annual_cte AS(
SELECT
location,
SUM(CASE
WHEN YEAR(transaction_date) = 2024 THEN net_sales
END) AS 2024_sales,
SUM(CASE
WHEN YEAR(transaction_date) = 2025 THEN net_sales
END) AS 2025_sales
FROM
transactions
GROUP BY location
)
SELECT
location,
2024_sales,
2025_sales,
2025_sales - 2024_sales AS YoY_change,
ROUND(100 * (2025_sales - 2024_sales) / 2024_sales,
2) AS Percentage_YoY_change
FROM
annual_cte;

-- NOTE / FINDING:
-- Store-level YoY analysis identifies which locations expanded
-- and which locations experienced weaker growth.


/* ------------------------------------------------------------
   QUERY 18 — Store sales, transactions and AOV YoY
   ------------------------------------------------------------ */

WITH annual_cte AS(
SELECT
location,
SUM(CASE
WHEN YEAR(transaction_date) = 2024 THEN net_sales
END) AS 2024_sales,
SUM(CASE
WHEN YEAR(transaction_date) = 2025 THEN net_sales
END) AS 2025_sales,
COUNT(DISTINCT CASE
WHEN
YEAR(transaction_date) = 2024
AND event_type = 'Payment'
THEN
transaction_id
END) AS 2024_transactions,
COUNT(DISTINCT CASE
WHEN
YEAR(transaction_date) = 2025
AND event_type = 'Payment'
THEN
transaction_id
END) AS 2025_transactions
FROM
transactions
GROUP BY location
)
SELECT
location,
2024_sales,
2025_sales,
2025_sales - 2024_sales AS YoY_change,
ROUND(100 * (2025_sales - 2024_sales) / 2024_sales,
2) AS Percentage_YoY_change,
2024_transactions,
2025_transactions,
2024_sales / 2024_transactions AS 2024_AOV,
2025_sales / 2025_transactions AS 2025_AOV
FROM
annual_cte;

-- NOTE / FINDING:
-- This separates store growth into transaction growth and
-- customer-spend/AOV changes.


/* ------------------------------------------------------------
   QUERY 19 — Store growth decomposition
   ------------------------------------------------------------ */

WITH annual_cte AS(
SELECT
location,
SUM(CASE
WHEN YEAR(transaction_date) = 2024 THEN net_sales
END) AS 2024_sales,
SUM(CASE
WHEN YEAR(transaction_date) = 2025 THEN net_sales
END) AS 2025_sales,
COUNT(DISTINCT CASE
WHEN
YEAR(transaction_date) = 2024
AND event_type = 'Payment'
THEN
transaction_id
END) AS 2024_transactions,
COUNT(DISTINCT CASE
WHEN
YEAR(transaction_date) = 2025
AND event_type = 'Payment'
THEN
transaction_id
END) AS 2025_transactions
FROM
transactions
GROUP BY location
)
SELECT
location,
ROUND(100 * (2025_sales - 2024_sales) / 2024_sales,
2) AS sales_growth,
ROUND(100 * (2025_transactions - 2024_transactions) / 2024_transactions,
2) AS transaction_growth,
ROUND(100 * ((2025_sales / 2025_transactions) - (2024_sales / 2024_transactions)) / (2024_sales / 2024_transactions),
2) AS AOV_growth
FROM
annual_cte;

-- NOTE / FINDING:
-- Store growth is decomposed into sales growth, transaction
-- growth and AOV growth.
--
-- Strong examples:
-- Store 23 - Baltimore: 9.82% sales growth and 3.28% AOV growth.
-- Store 20 - New York: 9.09% sales growth and 2.58% AOV growth.
-- Store 07 - Seattle: 7.12% sales growth and 1.92% AOV growth.
--
-- Store 13 - Miami is notable because sales declined by 0.10%
-- despite transaction growth of 3.23%, driven by a 3.23% decline
-- in AOV.


/* ============================================================
   4. CATEGORY ANALYSIS
   ============================================================ */


/* ------------------------------------------------------------
   QUERY 20 — Category performance
   ------------------------------------------------------------ */

WITH category_cte AS(
SELECT
category,
SUM(net_sales) AS net_sales,
SUM(quantity) AS units,
SUM(gross_profit) AS gross_profit,
ROUND(100 * SUM(gross_profit) / SUM(net_sales),
2) AS gross_profit_margin,
COUNT(DISTINCT CASE
WHEN event_type = 'Payment' THEN transaction_id
END) AS transactions
FROM
transactions
GROUP BY category
)
SELECT
category,
net_sales,
units,
transactions,
net_sales / units AS avg_selling_price,
units / transactions AS units_per_transactoins,
gross_profit_margin
FROM
category_cte;

-- NOTE / FINDING:
-- Apparel is the largest category by sales at $17.91M.
-- Footwear is second at $14.32M.
-- Beauty has the highest gross margin at 68.22%.
-- Footwear has the lowest gross margin at 48.68%.
-- Apparel also has the highest units per transaction at 1.4879.


/* ------------------------------------------------------------
   QUERY 21 — Category cost and discount structure
   ------------------------------------------------------------ */

SELECT
category,
AVG(unit_cost) AS avg_unit_cost,
ROUND(100 * - SUM(discount) / SUM(gross_sales),
2) AS discount_rate,
ROUND(100 * SUM(unit_cost * quantity) / SUM(net_sales),
2) AS cost_percentage
FROM
transactions
GROUP BY category;

-- NOTE / FINDING:
-- Footwear has the highest cost percentage at 51.32%.
-- Beauty has the lowest cost percentage at 31.78%.
-- Discount rates are relatively consistent across categories,
-- ranging from approximately 5.38% to 5.61%.


/* ============================================================
   5. PRODUCT ANALYSIS
   ============================================================ */


/* ------------------------------------------------------------
   QUERY 22 — Product performance
   ------------------------------------------------------------ */

-- Product transaction count uses PAYMENT transactions only.
SELECT
item,
SUM(net_sales) AS net_sales,
SUM(quantity) AS net_units_sold,
SUM(gross_profit) AS gross_profit,
ROUND(100 * SUM(gross_profit) / SUM(net_sales),
2) AS gross_margin_percent,
COUNT(DISTINCT CASE
WHEN event_type = 'Payment' THEN transaction_id
END) AS number_of_transactions
FROM
transactions
GROUP BY item;

-- NOTE / FINDING:
-- Running Shoes is the highest-selling product at $4.88M.
-- Canvas Sneakers follows at $4.39M.
-- Running Shoes also generates the highest gross profit
-- at $2.30M.
-- Polarized Sunglasses has a particularly strong 70.39% margin.


/* ------------------------------------------------------------
   QUERY 23 — Product sales ranking and cumulative contribution
   ------------------------------------------------------------ */

WITH product_summary AS (
SELECT
item, SUM(net_sales) AS sales
FROM
transactions
GROUP BY item
)
SELECT
item,
sales,
RANK() OVER(ORDER BY sales DESC) AS sales_rank,
sum(sales) over(order by sales desc) as running_total,
ROUND(100 * sum(sales) over(order by sales desc) / SUM(sales) OVER(), 2) AS percent_of_total_sales
FROM product_summary;

-- NOTE / FINDING:
-- The top 5 products generate approximately 43.86% of total
-- net sales.
-- The top 10 products generate approximately 68.92%.
-- Running Shoes alone contributes 10.46% of total net sales.


/* ------------------------------------------------------------
   QUERY 24 — Product sales vs gross-profit ranking
   ------------------------------------------------------------ */

WITH profitability_cte AS(
SELECT
item,
SUM(net_sales) AS net_sales,
SUM(gross_profit) AS gross_profit,
ROUND(100 * SUM(gross_profit) / SUM(net_sales),
2) AS gross_margin
FROM
transactions
GROUP BY item
)
select item, net_sales, gross_profit, gross_margin,
rank() over(order by net_sales desc) as sales_rank,
rank() over(order by gross_profit desc) as gross_profit_rank
from profitability_cte;

-- NOTE / FINDING:
-- The highest-sales products also tend to generate the most gross
-- profit, but their rankings differ.
-- Hooded Sweatshirt ranks #4 in sales but #3 in gross profit.
-- Leather Boots ranks #3 in sales but #5 in gross profit,
-- reflecting its lower 45.06% gross margin.


/* ------------------------------------------------------------
   QUERY 25 — Cumulative gross-profit contribution
   ------------------------------------------------------------ */

WITH gross_profit_cte AS(
SELECT
item, SUM(gross_profit) AS gross_profit
FROM
transactions
GROUP BY item
)
select item,
gross_profit,
rank() over(order by gross_profit desc) as gross_profit_rank,
sum(gross_profit) over(order by gross_profit desc) as running_total,
round(100* sum(gross_profit) over(order by gross_profit desc)/sum(gross_profit) over(), 2) as cumulative_percent
from gross_profit_cte;

-- NOTE / FINDING:
-- The top 5 products generate 39.65% of total gross profit.
-- The top 10 products generate 64.55%.
-- Running Shoes alone contributes 8.92% of total gross profit.


/* ------------------------------------------------------------
   QUERY 26 — Product profitability summary
   ------------------------------------------------------------ */

SELECT
item,
SUM(net_sales) AS net_sales,
SUM(gross_profit) AS gross_profit,
ROUND(100 * SUM(gross_profit) / SUM(net_sales),
2) AS gross_profit_margin,
SUM(quantity) AS units_sold
FROM
transactions
GROUP BY item;

-- NOTE / FINDING:
-- Product-level profitability reveals which products combine
-- meaningful sales volume with strong margins.
-- High-margin products include Lip Balm Set (70.44%),
-- Polarized Sunglasses (70.39%) and Ceramic Coffee Mug (70.37%).


/* ============================================================
   6. CUSTOMER ANALYSIS
   ============================================================ */


/* ------------------------------------------------------------
   QUERY 27 — Identified vs unidentified customers
   ------------------------------------------------------------ */

SELECT
CASE
WHEN customer_id IS NULL THEN 'Unidentified'
ELSE 'Identified'
END AS customer_status,
COUNT(DISTINCT CASE
WHEN event_type = 'Payment' THEN transaction_id
END) AS transactions,
COUNT(DISTINCT customer_id) AS customer_count,
SUM(net_sales) AS net_sales,
SUM(gross_profit) AS gross_profit,
SUM(quantity) AS net_units,
COUNT(line_item_id) AS line_items
FROM
transactions
GROUP BY customer_status;

-- NOTE / FINDING:
-- Identified customers account for 201,667 transactions and
-- $16.46M in net sales.
-- Unidentified transactions account for $30.13M in net sales.
-- Only 19,999 customers are identified, highlighting a major
-- customer-identification/data-capture opportunity.


/* ------------------------------------------------------------
   QUERY 28 — Sales contribution by customer identification
   ------------------------------------------------------------ */

WITH sales_cte AS (
SELECT
CASE
WHEN customer_id IS NOT NULL THEN 'Identified'
ELSE 'Unidentified'
END AS customer_status,
SUM(net_sales) AS net_sales
FROM
transactions
GROUP BY 1
)
SELECT
customer_status,
net_sales,
ROUND(100.0 * net_sales / SUM(net_sales) OVER (), 2) AS sales_contribution
FROM sales_cte;

-- NOTE / FINDING:
-- Unidentified customers contribute 64.67% of net sales.
-- Identified customers contribute only 35.33%.
-- This means the majority of sales cannot currently be tied to
-- an identifiable customer.


/* ------------------------------------------------------------
   QUERY 29 — Average transaction frequency of identified customers
   ------------------------------------------------------------ */

WITH cust_cte AS(
SELECT
customer_id,
COUNT(DISTINCT CASE
WHEN event_type = 'Payment' THEN transaction_id
END) AS number_of_transactions,
SUM(net_sales) AS customer_revenue,
SUM(gross_profit) AS customer_gross_profit,
SUM(quantity) AS net_units
FROM
transactions
WHERE
customer_id IS NOT NULL
GROUP BY customer_id
)
SELECT
ROUND(AVG(number_of_transactions), 2) AS avg_number_of_transactions
FROM
cust_cte;

-- NOTE / FINDING:
-- Identified customers average 10.08 transactions over the
-- analysis period.


/* ------------------------------------------------------------
   QUERY 30 — AOV by customer identification status
   ------------------------------------------------------------ */

SELECT
CASE
WHEN customer_id IS NULL THEN 'Unidentified'
ELSE 'Identified'
END AS customer_type,
COUNT(DISTINCT CASE
WHEN event_type = 'Payment' THEN transaction_id
END) AS transactions,
SUM(net_sales) AS net_sales,
ROUND(SUM(net_sales) / COUNT(DISTINCT CASE
WHEN event_type = 'Payment' THEN transaction_id
END),
2) AS AOV
FROM
transactions
GROUP BY customer_type;

-- NOTE / FINDING:
-- Identified customers have an AOV of $81.62 compared with
-- $80.45 for unidentified customers.
-- The difference is modest, but identified customers spend
-- slightly more per transaction.


/* ------------------------------------------------------------
   QUERY 31 — One-time vs repeat customers
   ------------------------------------------------------------ */

WITH frequency_cte AS (
SELECT
customer_id,
COUNT(DISTINCT CASE
WHEN event_type = 'Payment' THEN transaction_id
END) AS transactions
FROM
transactions
WHERE
customer_id IS NOT NULL
GROUP BY customer_id
),
repetition_cte AS (
SELECT
customer_id,
CASE
WHEN transactions < 2 THEN 'One-time customer'
ELSE 'Repeat customer'
END AS customer_type
FROM
frequency_cte
)
SELECT
customer_type, COUNT(*) AS customer_count
FROM
repetition_cte
GROUP BY customer_type;

-- NOTE / FINDING:
-- 19,993 identified customers are repeat customers.
-- Only 6 identified customers are one-time customers.
-- Among customers who can be identified, repeat purchasing is
-- overwhelmingly dominant.


/* ------------------------------------------------------------
   QUERY 32 — Average customer sales and gross profit
   ------------------------------------------------------------ */

WITH sales_matrix AS(
SELECT
customer_id,
CASE
WHEN customer_id IS NOT NULL THEN 'Identified'
END AS customer_type,
SUM(net_sales) AS net_sales,
SUM(gross_profit) AS gross_profit
FROM
transactions
WHERE
customer_id IS NOT NULL
GROUP BY customer_id , customer_type
)
SELECT
customer_type,
ROUND(AVG(net_sales), 2) AS avg_net_sales,
ROUND(AVG(gross_profit), 2) AS avg_gross_profit
FROM
sales_matrix
GROUP BY customer_type;

-- NOTE / FINDING:
-- The average identified customer generates $823.07 in net sales
-- and $455.59 in gross profit over the analysis period.


/* ------------------------------------------------------------
   QUERY 33 — Median customer sales
   ------------------------------------------------------------ */

WITH cust_sales AS (
SELECT
customer_id, SUM(net_sales) AS net_sales
FROM
transactions
WHERE
customer_id IS NOT NULL
GROUP BY customer_id
),
ranked_customers AS (
SELECT
net_sales,
ROW_NUMBER() OVER (ORDER BY net_sales) AS row_num,
COUNT(*) OVER () AS total_rows
FROM cust_sales
)
SELECT
AVG(net_sales) AS median_customer_sales
FROM ranked_customers
WHERE row_num IN (
FLOOR((total_rows + 1) / 2.0),
CEIL((total_rows + 1) / 2.0)
);

-- NOTE / FINDING:
-- Median identified-customer sales = $794.15.
-- The median being below the average ($823.07) indicates that
-- some higher-value customers pull the average upward.


/* ------------------------------------------------------------
   QUERY 34 — Minimum and maximum customer sales
   ------------------------------------------------------------ */

WITH cust_summary AS(
SELECT
customer_id, SUM(net_sales) AS net_sales
FROM
transactions
WHERE
customer_id IS NOT NULL
GROUP BY customer_id
)
SELECT
MIN(net_sales) AS min_cust_sales,
MAX(net_sales) AS max_cust_sales
FROM
cust_summary;

-- NOTE / FINDING:
-- Identified customer sales range from $28.20 to $2,428.10,
-- demonstrating meaningful variation in customer value.


/* ------------------------------------------------------------
   QUERY 35 — Customer frequency segmentation
   ------------------------------------------------------------ */

WITH cust_frequency AS(
SELECT
customer_id,
COUNT(DISTINCT CASE
WHEN event_type = 'Payment' THEN transaction_id
END) AS transactions,
CASE
WHEN
COUNT(DISTINCT CASE
WHEN event_type = 'Payment' THEN transaction_id
END) > 15
THEN
'Very High Frequency'
WHEN
COUNT(DISTINCT CASE
WHEN event_type = 'Payment' THEN transaction_id
END) > 10
THEN
'High frequency'
WHEN
COUNT(DISTINCT CASE
WHEN event_type = 'Payment' THEN transaction_id
END) > 5
THEN
'Medium frequency'
ELSE 'Low frequency'
END AS frequency,
SUM(net_sales) AS net_sales
FROM
transactions
WHERE
customer_id IS NOT NULL
GROUP BY customer_id
)
select
frequency,
count(customer_id) as total_customers,
sum(net_sales) as total_sales,
sum(net_sales)/count(customer_id) as avg_sales_per_customer,
sum(transactions)/count(customer_id) as avg_transaction_per_customer,
ROUND(
100 * SUM(net_sales) / SUM(SUM(net_sales)) OVER(),
2
) AS sales_contribution
from cust_frequency
group by frequency;

-- NOTE / FINDING:
-- Medium-frequency customers are the largest segment:
-- 10,195 customers and $6.93M in sales.
--
-- High-frequency customers:
-- 7,522 customers
-- $7.64M sales
-- $1,015.78 average sales/customer
-- 12.45% sales contribution
--
-- Very-high-frequency customers:
-- 1,036 customers
-- $1.43M sales
-- $1,385.01 average sales/customer
-- 17.03 average transactions/customer.
--
-- Frequency is strongly associated with customer value.


/* ------------------------------------------------------------
   QUERY 36 — Category preferences of high-frequency customers
   ------------------------------------------------------------ */

WITH freq_Summary AS(
SELECT
customer_id,
CASE
WHEN
COUNT(DISTINCT CASE
WHEN event_type = 'Payment' THEN transaction_id
END) > 15
THEN
'Very High Frequency'
WHEN
COUNT(DISTINCT CASE
WHEN event_type = 'Payment' THEN transaction_id
END) > 10
THEN
'High frequency'
WHEN
COUNT(DISTINCT CASE
WHEN event_type = 'Payment' THEN transaction_id
END) > 5
THEN
'Medium frequency'
ELSE 'Low frequency'
END AS frequency
FROM
transactions
WHERE
customer_id IS NOT NULL
GROUP BY customer_id
)
SELECT
f.frequency, t.category, SUM(t.net_sales) AS net_sales
FROM
freq_Summary f
JOIN
transactions t ON f.customer_id = t.customer_id
WHERE
f.frequency = 'High frequency'
GROUP BY f.frequency , t.category;

-- NOTE / FINDING:
-- Among high-frequency customers, Apparel is the largest
-- category at $2.93M, followed by Footwear at $2.35M.
-- These categories are particularly important for retaining
-- high-frequency customers.


/* ============================================================
   7. RETURNS & REFUNDS
   ============================================================ */


/* ------------------------------------------------------------
   QUERY 37 — Category return and refund rates
   ------------------------------------------------------------ */

WITH category_returns AS(
SELECT
category,
SUM(quantity * -1) AS quantity_returned,
SUM(net_sales * -1) AS amount_refunded
FROM
transactions
WHERE
event_type = 'Refund'
GROUP BY category
),
category_sales AS(
SELECT
category,
SUM(quantity) AS quantity_sold,
SUM(net_sales) AS sales_amount
FROM
transactions
WHERE
event_type = 'Payment'
GROUP BY category
)
SELECT
cs.category,
cs.quantity_sold,
cr.quantity_returned,
cs.sales_amount,
cr.amount_refunded,
ROUND(100 * cr.quantity_returned / cs.quantity_sold,
2) AS quantity_return_rate,
ROUND(100 * cr.Amount_refunded / cs.sales_amount,
2) AS refund_value_rate
FROM
category_sales cs
JOIN
category_returns cr ON cs.category = cr.category;

-- NOTE / FINDING:
-- Return rates are relatively low across all categories.
-- Apparel has the lowest quantity return rate at 0.78%.
-- Home Goods and Footwear have the highest quantity return rate
-- at 0.82%.
-- Apparel also has the lowest refund-value rate at 0.82%.


/* ============================================================
   8. PAYMENT METHOD ANALYSIS
   ============================================================ */


/* ------------------------------------------------------------
   QUERY 38 — Payment method performance
   ------------------------------------------------------------ */

WITH payment_cte AS(
SELECT
payment_method,
COUNT(DISTINCT CASE
WHEN event_type = 'Payment' THEN transaction_id
END) AS transactions,
SUM(net_sales) AS net_sales
FROM
transactions
GROUP BY payment_method
)
SELECT
payment_method,
transactions,
net_sales,
ROUND(100 * net_sales / SUM(net_sales) OVER(), 2) AS percent_of_total_net_sales,
ROUND(net_sales / transactions, 2) AS avg_transaction_value
FROM
payment_cte;

-- NOTE / FINDING:
-- Card is the dominant payment method:
-- 409,143 transactions
-- $33.05M net sales
-- 70.93% of total net sales
-- $80.78 average transaction value.
--
-- Cash represents 24.04% of net sales.
-- Other payment methods represent 5.03%.
--
-- Average transaction value is very similar across payment
-- methods, ranging from $80.78 to $81.40.
