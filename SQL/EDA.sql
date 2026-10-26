CREATE DATABASE retail_analytics;
USE retail_analytics;

CREATE TABLE transactions (
    line_item_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_date DATE,
    transaction_time TIME,
    timezone CHAR(3),
    category VARCHAR(50),
    item VARCHAR(50),
    quantity INT,
    price_point_name VARCHAR(50),
    sku VARCHAR(50),
    unit_price DECIMAL(12 , 2 ),
    gross_sales DECIMAL(12 , 2 ),
    discount DECIMAL(12 , 2 ),
    net_sales DECIMAL(12 , 2 ),
    tax DECIMAL(12 , 2 ),
    total_collected DECIMAL(12 , 2 ),
    transaction_id VARCHAR(50) NOT NULL,
    payment_method VARCHAR(50),
    device_name VARCHAR(50),
    location VARCHAR(50),
    customer_id VARCHAR(50),
    event_type VARCHAR(50),
    unit_cost DECIMAL(12 , 2 ),
    gross_profit DECIMAL(12 , 2 )
);

DESCRIBE transactions;


-- Run this code in Command line for quicker import.
-- Make sure local infile is on before running the code.

LOAD DATA LOCAL INFILE 'file_path.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
transaction_date,
transaction_time,
timezone,
category,
item,
quantity,
price_point_name,
sku,
unit_price,
gross_sales,
discount,
net_sales,
tax,
total_collected,
transaction_id,
payment_method,
device_name,
location,
customer_id,
event_type,
unit_cost,
gross_profit
);


-- Validating all rows are imported. There should 970838 rows imported.

SELECT 
    COUNT(*)
FROM
    transactions;


-- Making sure the null values in customer_id column are exactly transformed.

UPDATE transactions 
SET 
    customer_id = NULL
WHERE
    TRIM(customer_id) = '';


SELECT 
    COUNT(DISTINCT transaction_id) AS total_transactions
FROM
    transactions
WHERE
    event_type = 'Payment';


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


-- Validating all the quantity in the refund event_type are negative.

SELECT 
    quantity
FROM
    transactions
WHERE
    event_type = 'Refund'
GROUP BY quantity;


SELECT 
    SUM(gross_sales) AS gross_sales,
    SUM(discount * -1) AS dsicount,
    SUM(net_sales) AS net_sales,
    SUM(tax) AS tax,
    SUM(total_collected) AS total_collected,
    SUM(gross_profit) AS gross_profit
FROM
    transactions;


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


SELECT 
    COUNT(DISTINCT transaction_id) AS total_transactions
FROM
    transactions
WHERE
    event_type = 'Payment';


SELECT 
    SUM(quantity) AS net_units_sold
FROM
    transactions;


SELECT 
    ROUND(SUM(net_sales) / COUNT(DISTINCT CASE
                    WHEN event_type = 'Payment' THEN transaction_id
                END),
            2) AS avg_order_value
FROM
    transactions;


SELECT 
    SUM(gross_profit) AS total_gross_profit
FROM
    transactions;

SELECT 
    ROUND(100 * SUM(gross_profit) / SUM(net_sales),
            2) AS gross_profit_margin
FROM
    transactions;

SELECT 
    SUM(quantity * - 1) AS total_quantity_returned
FROM
    transactions
WHERE
    event_type = 'Refund';

SELECT 
    SUM(net_sales * - 1) AS total_amount_refunded
FROM
    transactions
WHERE
    event_type = 'Refund';


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
    freq_summary f
        JOIN
    transactions t ON f.customer_id = t.customer_id
WHERE
    f.frequency = 'High frequency'
GROUP BY f.frequency , t.category;


WITH category_returns AS(
SELECT 
    category,
    SUM(quantity * - 1) AS quantity_returned,
    SUM(net_sales * - 1) AS amount_refunded
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

SELECT 
    SUM(net_sales) AS total_net_sales,
    SUM(gross_profit) AS total_gross_profit,
    COUNT(DISTINCT CASE
            WHEN event_type = 'Payment' THEN transaction_id
        END) AS total_transactions,
    SUM(quantity) AS total_units_sold
FROM
    transactions;

