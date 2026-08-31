-- Data Quality

-- What is the size of the cleaned dataset?

SELECT
    COUNT(*) AS total_rows
FROM transactions;


-- What is the overall scale of the business?

SELECT
    SUM(Revenue) AS total_revenue,
    SUM(Quantity) AS total_units,
    COUNT(DISTINCT InvoiceNo) AS unique_invoices,
    COUNT(DISTINCT CustomerID) AS unique_customers
FROM transactions;


-- How much revenue comes from known versus missing customer IDs?

SELECT
    CASE
        WHEN CustomerID IS NULL OR CustomerID = '' THEN 'Missing'
        ELSE 'Known'
    END AS customer_status,
    SUM(Revenue) AS total_revenue
FROM transactions
GROUP BY customer_status;


-- How many customers have identifiable customer IDs?

SELECT
    COUNT(DISTINCT CustomerID) AS known_customers
FROM transactions
WHERE CustomerID IS NOT NULL
    AND CustomerID <> '';


-- Customer Analysis

-- How much revenue does each known customer contribute?

WITH customer_revenue AS (
    SELECT
        CustomerID,
        SUM(Revenue) AS total_revenue
    FROM transactions
    WHERE CustomerID IS NOT NULL
    AND CustomerID <> ''
    GROUP BY CustomerID
)
SELECT
    CustomerID,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS customer_rank
FROM customer_revenue
ORDER BY total_revenue DESC
LIMIT 30;


-- What proportion of identifiable customer revenue
-- comes from the top 10% of customers?
-- Note: The number 587 represents the top 10% of 5,866 identifiable customers

WITH customer_revenue AS (
    SELECT
        CustomerID,
        SUM(Revenue) AS total_revenue
    FROM transactions
    WHERE CustomerID IS NOT NULL
    AND CustomerID <> ''
    GROUP BY CustomerID
),
top_customers AS (
    SELECT
        CustomerID,
        total_revenue
    FROM customer_revenue
    ORDER BY total_revenue DESC
    LIMIT 587
)
SELECT
    SUM(total_revenue) AS top_10_customer_revenue,
    (
        SUM(total_revenue) /
        (SELECT SUM(total_revenue) FROM customer_revenue)
    ) * 100 AS percentage_of_known_revenue
FROM top_customers;


-- Product Data Quality

-- Before analysing product performance, assess whether each
-- StockCode consistently corresponds to a single description.

-- How many different descriptions are associated with each StockCode?

SELECT
    StockCode,
    COUNT(DISTINCT Description) AS description_count
FROM transactions
GROUP BY StockCode
HAVING COUNT(DISTINCT Description) > 1
ORDER BY description_count DESC;


-- How many StockCodes have multiple descriptions?

SELECT
    COUNT(*) AS problematic_stockcodes
FROM (
    SELECT
        StockCode,
        COUNT(DISTINCT Description) AS description_count
    FROM transactions
    GROUP BY StockCode
    HAVING COUNT(DISTINCT Description) > 1
) AS problematic_products;


-- Which descriptions are associated with StockCodes
-- that have multiple descriptions?

SELECT DISTINCT
    StockCode,
    Description
FROM transactions
WHERE StockCode IN (
    SELECT
        StockCode
    FROM transactions
    GROUP BY StockCode
    HAVING COUNT(DISTINCT Description) > 1
)
ORDER BY StockCode, Description;


-- Product Performance

-- Which products generate the most demand?

SELECT
    StockCode,
    MAX(Description) AS Description,
    SUM(Quantity) AS total_quantity
FROM transactions
WHERE Quantity > 0
    AND StockCode NOT IN ('ADJUST', 'ADJUST2', 'BANK CHARGES')
GROUP BY StockCode
ORDER BY total_quantity DESC
LIMIT 20;


-- Which products generate the most revenue?

SELECT
    StockCode,
    MAX(Description) AS Description,
    SUM(Quantity) AS total_quantity,
    ROUND(SUM(Revenue), 2) AS total_revenue
FROM transactions
WHERE Quantity > 0
    AND StockCode NOT IN ('ADJUST', 'ADJUST2', 'BANK CHARGES')
GROUP BY StockCode
ORDER BY total_revenue DESC
LIMIT 20;


-- How many transactions contain negative quantities?
-- Negative quantities are treated separately from positive product
-- demand because they generally represent returns or reductions.

SELECT
    COUNT(*) AS negative_quantity_rows,
    SUM(Quantity) AS negative_units
FROM transactions
WHERE Quantity < 0;


-- Monthly Product Demand

-- Create a temporary table containing monthly demand for each product.
-- Positive sales are aggregated by product and month, while zero-demand
-- months are retained so that demand variability can be measured across
-- the full observation period.

DROP TEMPORARY TABLE IF EXISTS monthly_product_demand;

CREATE TEMPORARY TABLE monthly_product_demand AS

WITH months AS (
    SELECT DISTINCT
        YearMonth
    FROM transactions
),
products AS (
    SELECT DISTINCT
        StockCode
    FROM transactions
    WHERE StockCode NOT IN ('ADJUST', 'ADJUST2', 'BANK CHARGES')
),
monthly_sales AS (
    SELECT
        StockCode,
        YearMonth,
        SUM(Quantity) AS monthly_quantity
    FROM transactions
    WHERE Quantity > 0
        AND Revenue > 0
        AND StockCode NOT IN ('ADJUST', 'ADJUST2', 'BANK CHARGES')
    GROUP BY
        StockCode,
        YearMonth
)
SELECT
    p.StockCode,
    m.YearMonth,
    COALESCE(s.monthly_quantity, 0) AS monthly_quantity
FROM products p
CROSS JOIN months m
LEFT JOIN monthly_sales s
    ON p.StockCode = s.StockCode
    AND m.YearMonth = s.YearMonth;


-- Add an index to improve the performance of subsequent
-- product and month-level analyses.

CREATE INDEX idx_monthly_product
ON monthly_product_demand (StockCode, YearMonth);


-- Basic Monthly Demand

-- How frequently are products active across the dataset?

SELECT
    StockCode,
    COUNT(
        CASE
            WHEN monthly_quantity > 0 THEN 1
        END
    ) AS active_months
FROM monthly_product_demand
GROUP BY StockCode
ORDER BY active_months DESC;


-- How many products have each number of active months?

SELECT
    active_months,
    COUNT(*) AS number_of_products
FROM (
    SELECT
        StockCode,
        COUNT(
            CASE
                WHEN monthly_quantity > 0 THEN 1
            END
        ) AS active_months
    FROM monthly_product_demand
    GROUP BY StockCode
) AS product_activity
GROUP BY active_months
ORDER BY active_months DESC;


-- Demand Variability

-- Which products have the most variable monthly demand?

SELECT
    StockCode,
    ROUND(AVG(monthly_quantity), 1) AS avg_monthly_quantity,
    ROUND(STDDEV(monthly_quantity), 1) AS demand_stddev,
    COUNT(*) AS months_observed
FROM monthly_product_demand
GROUP BY StockCode
ORDER BY demand_stddev DESC
LIMIT 100;


-- Overall Demand Benchmarks

-- What are the average monthly demand and average demand
-- variability across all products?

SELECT
    ROUND(AVG(avg_monthly_quantity), 1)
        AS overall_avg_monthly_demand,
    ROUND(AVG(demand_stddev), 1)
        AS overall_avg_demand_stddev
FROM (
    SELECT
        StockCode,
        AVG(monthly_quantity) AS avg_monthly_quantity,
        STDDEV(monthly_quantity) AS demand_stddev
    FROM monthly_product_demand
    GROUP BY StockCode
) AS product_stats;


-- High Demand and High Variability

-- Which products have both substantial demand and substantial
-- demand variability?
-- Notes: 96.3/120.7 thresholds represent the median monthly demand and median demand
-- variability calculated across products.

WITH product_stats AS (
    SELECT
        StockCode,
        AVG(monthly_quantity) AS avg_monthly_quantity,
        STDDEV(monthly_quantity) AS demand_stddev
    FROM monthly_product_demand
    GROUP BY StockCode
)
SELECT
    StockCode,
    ROUND(avg_monthly_quantity, 1) AS avg_monthly_quantity,
    ROUND(demand_stddev, 1) AS demand_stddev
FROM product_stats
WHERE avg_monthly_quantity > 96.3
    AND demand_stddev > 120.7
ORDER BY demand_stddev DESC;


-- How many products have both above-average demand
-- and above-average demand variability?

WITH product_stats AS (
    SELECT
        StockCode,
        AVG(monthly_quantity) AS avg_monthly_quantity,
        STDDEV(monthly_quantity) AS demand_stddev
    FROM monthly_product_demand
    GROUP BY StockCode
)
SELECT
    COUNT(*) AS high_demand_high_variability_products
FROM product_stats
WHERE avg_monthly_quantity > 96.3
    AND demand_stddev > 120.7;


-- Monthly Product Performance

-- Which product had the highest demand in each month?

SELECT
    StockCode,
    YearMonth,
    monthly_quantity
FROM (
    SELECT
        StockCode,
        YearMonth,
        monthly_quantity,
        RANK() OVER (
            PARTITION BY YearMonth
            ORDER BY monthly_quantity DESC
        ) AS monthly_rank
    FROM monthly_product_demand
    WHERE monthly_quantity > 0
) AS ranked_products
WHERE monthly_rank = 1
ORDER BY YearMonth;


-- Category Analysis

-- Which product categories generate the most demand and revenue?

SELECT
    Category,
    SUM(Quantity) AS total_units,
    ROUND(SUM(Revenue), 2) AS total_revenue
FROM transactions
WHERE Quantity > 0
GROUP BY Category
ORDER BY total_revenue DESC;


-- How many unique products are in each category?

SELECT
    Category,
    COUNT(DISTINCT StockCode) AS unique_products,
    SUM(Quantity) AS total_units,
    ROUND(SUM(Revenue), 2) AS total_revenue
FROM transactions
WHERE Quantity > 0
GROUP BY Category
ORDER BY unique_products DESC;


-- How much revenue does each product generate on average
-- within each category?

SELECT
    Category,
    COUNT(DISTINCT StockCode) AS unique_products,
    ROUND(SUM(Revenue), 2) AS total_revenue,
    ROUND(
        SUM(Revenue) / COUNT(DISTINCT StockCode),
        2
    ) AS revenue_per_product
FROM transactions
WHERE Quantity > 0
GROUP BY Category
ORDER BY revenue_per_product DESC;


-- Which categories have the highest average demand per product?

WITH product_demand AS (
    SELECT
        Category,
        StockCode,
        SUM(Quantity) AS total_units
    FROM transactions
    WHERE Quantity > 0
    GROUP BY Category, StockCode
)
SELECT
    Category,
    COUNT(*) AS unique_products,
    ROUND(AVG(total_units), 1) AS avg_units_per_product,
    SUM(total_units) AS total_units
FROM product_demand
GROUP BY Category
ORDER BY avg_units_per_product DESC;


-- What percentage of total revenue comes from each category?

SELECT
    Category,
    ROUND(SUM(Revenue), 2) AS total_revenue,
    ROUND(
        SUM(Revenue) /
        (
            SELECT SUM(Revenue)
            FROM transactions
            WHERE Quantity > 0
        ) * 100,
        2
    ) AS revenue_percentage
FROM transactions
WHERE Quantity > 0
GROUP BY Category
ORDER BY total_revenue DESC;


-- Category Seasonality

-- Which months generate the most revenue overall?

SELECT
    MONTH(InvoiceDate) AS month_number,
    MONTHNAME(InvoiceDate) AS month_name,
    ROUND(SUM(Revenue), 2) AS total_revenue,
    SUM(Quantity) AS total_units
FROM transactions
WHERE Quantity > 0
GROUP BY
    MONTH(InvoiceDate),
    MONTHNAME(InvoiceDate)
ORDER BY month_number;


-- Which categories generate the most revenue in each month?

SELECT
    YearMonth,
    Category,
    ROUND(SUM(Revenue), 2) AS total_revenue
FROM transactions
WHERE Quantity > 0
GROUP BY
    YearMonth,
    Category
ORDER BY
    YearMonth,
    total_revenue DESC;


-- Which categories show the strongest seasonal variation?

WITH category_monthly AS (
    SELECT
        Category,
        MONTH(InvoiceDate) AS month_number,
        SUM(Revenue) AS monthly_revenue
    FROM transactions
    WHERE Quantity > 0
    GROUP BY
        Category,
        MONTH(InvoiceDate)
),
category_seasonality AS (
    SELECT
        Category,
        AVG(monthly_revenue) AS avg_monthly_revenue,
        STDDEV(monthly_revenue) AS revenue_stddev
    FROM category_monthly
    GROUP BY Category
)
SELECT
    Category,
    ROUND(avg_monthly_revenue, 2) AS avg_monthly_revenue,
    ROUND(revenue_stddev, 2) AS revenue_stddev
FROM category_seasonality
ORDER BY revenue_stddev DESC;


-- Which category and month combinations generate unusually
-- high revenue relative to the category's typical monthly revenue?

WITH category_monthly AS (
    SELECT
        Category,
        MONTH(InvoiceDate) AS month_number,
        MONTHNAME(InvoiceDate) AS month_name,
        SUM(Revenue) AS monthly_revenue
    FROM transactions
    WHERE Quantity > 0
    GROUP BY
        Category,
        MONTH(InvoiceDate),
        MONTHNAME(InvoiceDate)
),
category_stats AS (
    SELECT
        Category,
        AVG(monthly_revenue) AS avg_monthly_revenue,
        STDDEV(monthly_revenue) AS revenue_stddev
    FROM category_monthly
    GROUP BY Category
)
SELECT
    cm.Category,
    cm.month_name,
    ROUND(cm.monthly_revenue, 2) AS monthly_revenue,
    ROUND(cs.avg_monthly_revenue, 2)
        AS category_avg_monthly_revenue,
    ROUND(
        (
            cm.monthly_revenue - cs.avg_monthly_revenue
        ) / NULLIF(cs.revenue_stddev, 0),
        2
    ) AS revenue_z_score
FROM category_monthly cm
JOIN category_stats cs
    ON cm.Category = cs.Category
ORDER BY revenue_z_score DESC
LIMIT 30;


-- Revenue and Inventory Risk

-- Which products combine high demand, high demand variability,
-- and high revenue?

WITH product_stats AS (
    SELECT
        StockCode,
        AVG(monthly_quantity) AS avg_monthly_quantity,
        STDDEV(monthly_quantity) AS demand_stddev
    FROM monthly_product_demand
    GROUP BY StockCode
),
product_revenue AS (
    SELECT
        StockCode,
        MAX(Description) AS Description,
        SUM(Quantity) AS total_units,
        SUM(Revenue) AS total_revenue
    FROM transactions
    WHERE Quantity > 0
        AND StockCode NOT IN ('ADJUST', 'ADJUST2', 'BANK CHARGES')
    GROUP BY StockCode
)
SELECT
    r.StockCode,
    r.Description,
    ROUND(r.total_revenue, 2) AS total_revenue,
    r.total_units,
    ROUND(p.avg_monthly_quantity, 1) AS avg_monthly_quantity,
    ROUND(p.demand_stddev, 1) AS demand_stddev
FROM product_revenue r
JOIN product_stats p
    ON r.StockCode = p.StockCode
ORDER BY p.demand_stddev DESC
LIMIT 100;


-- Which products have the most consistent demand across the dataset?
-- Products are assessed by the proportion of months in which they
-- recorded positive demand.

SELECT
    StockCode,
    COUNT(
        CASE
            WHEN monthly_quantity > 0 THEN 1
        END
    ) AS active_months,
    COUNT(*) AS total_months,
    ROUND(
        COUNT(
            CASE
                WHEN monthly_quantity > 0 THEN 1
            END
        ) / COUNT(*) * 100,
        1
    ) AS active_month_percentage,
    ROUND(AVG(monthly_quantity), 1) AS avg_monthly_quantity,
    SUM(monthly_quantity) AS total_units
FROM monthly_product_demand
GROUP BY StockCode
HAVING SUM(monthly_quantity) > 0
ORDER BY
    active_month_percentage DESC,
    total_units DESC
LIMIT 100;


-- Product Demand and Inventory Risk

-- Which products have the largest absolute swings in monthly demand?

WITH product_demand_variability AS (
    SELECT
        StockCode,
        AVG(monthly_quantity) AS avg_monthly_quantity,
        STDDEV(monthly_quantity) AS demand_stddev
    FROM monthly_product_demand
    GROUP BY StockCode
),
product_summary AS (
    SELECT
        StockCode,
        MAX(Description) AS Description,
        SUM(Quantity) AS total_units
    FROM transactions
    WHERE Quantity > 0
    GROUP BY StockCode
)
SELECT
    p.StockCode,
    p.Description,
    p.total_units,
    ROUND(v.avg_monthly_quantity, 1) AS avg_monthly_quantity,
    ROUND(v.demand_stddev, 1) AS demand_stddev
FROM product_demand_variability v
JOIN product_summary p
    ON v.StockCode = p.StockCode
ORDER BY v.demand_stddev DESC
LIMIT 20;


-- Customer Revenue Concentration

-- Which customers generate the most revenue?

SELECT
    CustomerID,
    ROUND(SUM(Revenue), 2) AS total_revenue,
    COUNT(DISTINCT InvoiceNo) AS total_invoices
FROM transactions
WHERE CustomerID IS NOT NULL
    AND Revenue > 0
GROUP BY CustomerID
ORDER BY total_revenue DESC
LIMIT 20;


-- What proportion of identifiable customer revenue is
-- generated by the top 20 customers?

SELECT
    CustomerID,
    ROUND(SUM(Revenue), 2) AS total_revenue,
    COUNT(DISTINCT InvoiceNo) AS total_invoices,
    ROUND(
        SUM(Revenue) / (
            SELECT SUM(Revenue)
            FROM transactions
            WHERE CustomerID IS NOT NULL
                AND CustomerID <> ''
        ) * 100,
        2
    ) AS revenue_percentage
FROM transactions
WHERE CustomerID IS NOT NULL
    AND CustomerID <> ''
GROUP BY CustomerID
ORDER BY total_revenue DESC
LIMIT 20;


-- How dependent is the business on its largest customers?

WITH customer_revenue AS (
    SELECT
        CustomerID,
        SUM(Revenue) AS total_revenue,
        COUNT(DISTINCT InvoiceNo) AS total_invoices
    FROM transactions
    WHERE CustomerID IS NOT NULL
    AND CustomerID <> ''
    GROUP BY CustomerID
),
customer_revenue_with_percentage AS (
    SELECT
        CustomerID,
        total_revenue,
        total_invoices,
        total_revenue /
        (
            SELECT SUM(total_revenue)
            FROM customer_revenue
        ) * 100 AS revenue_percentage
    FROM customer_revenue
)
SELECT
    CASE
        WHEN revenue_percentage >= 1 THEN '1%+'
        WHEN revenue_percentage >= 0.5 THEN '0.5% - 0.99%'
        WHEN revenue_percentage >= 0.1 THEN '0.1% - 0.49%'
        ELSE '<0.1%'
    END AS customer_revenue_band,
    COUNT(*) AS customer_count,
    ROUND(SUM(total_revenue), 2) AS total_revenue,
    ROUND(SUM(revenue_percentage), 2) AS revenue_percentage
FROM customer_revenue_with_percentage
GROUP BY customer_revenue_band
ORDER BY
    CASE customer_revenue_band
        WHEN '1%+' THEN 1
        WHEN '0.5% - 0.99%' THEN 2
        WHEN '0.1% - 0.49%' THEN 3
        ELSE 4
    END;


-- Customer Behaviour

-- How does customer revenue vary according to purchase frequency?

WITH customer_revenue AS (
    SELECT
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS total_invoices,
        SUM(Revenue) AS total_revenue
    FROM transactions
    WHERE CustomerID IS NOT NULL
    AND CustomerID <> ''
    GROUP BY CustomerID
)
SELECT
    CASE
        WHEN total_invoices >= 100 THEN '100+ invoices'
        WHEN total_invoices >= 50 THEN '50 - 99'
        WHEN total_invoices >= 20 THEN '20 - 49'
        WHEN total_invoices >= 10 THEN '10 - 19'
        WHEN total_invoices >= 5 THEN '5 - 9'
        ELSE '<5'
    END AS invoice_frequency_band,
    COUNT(*) AS customer_count,
    ROUND(SUM(total_revenue), 2) AS total_revenue
FROM customer_revenue
GROUP BY invoice_frequency_band
ORDER BY
    CASE invoice_frequency_band
        WHEN '100+ invoices' THEN 1
        WHEN '50 - 99' THEN 2
        WHEN '20 - 49' THEN 3
        WHEN '10 - 19' THEN 4
        WHEN '5 - 9' THEN 5
        ELSE 6
    END;


-- How dependent is revenue on customers who repeatedly return,
-- compared with customers who purchase only occasionally?

SELECT
    CustomerID,
    COUNT(DISTINCT YearMonth) AS active_months,
    ROUND(SUM(Revenue), 2) AS total_revenue
FROM transactions
WHERE CustomerID IS NOT NULL
    AND CustomerID <> ''
GROUP BY CustomerID
ORDER BY active_months DESC;


-- How is the customer base distributed according to the number
-- of months in which customers were active?

SELECT
    customer_longevity_band,
    COUNT(*) AS customer_count,
    ROUND(SUM(total_revenue), 2) AS total_revenue
FROM (
    SELECT
        CustomerID,
        COUNT(DISTINCT YearMonth) AS active_months,
        SUM(Revenue) AS total_revenue,
        CASE
            WHEN COUNT(DISTINCT YearMonth) >= 20 THEN '20+ months'
            WHEN COUNT(DISTINCT YearMonth) >= 10 THEN '10 - 19 months'
            WHEN COUNT(DISTINCT YearMonth) >= 5 THEN '5 - 9 months'
            ELSE '<5 months'
        END AS customer_longevity_band
    FROM transactions
    WHERE CustomerID IS NOT NULL
    AND CustomerID <> ''
    GROUP BY CustomerID
) AS customer_activity
GROUP BY customer_longevity_band
ORDER BY
    CASE customer_longevity_band
        WHEN '20+ months' THEN 1
        WHEN '10 - 19 months' THEN 2
        WHEN '5 - 9 months' THEN 3
        ELSE 4
    END;


-- Customer Value per Order

-- Which customers have the highest average order value?

SELECT
    CustomerID,
    COUNT(DISTINCT InvoiceNo) AS total_invoices,
    ROUND(
        SUM(Revenue) / COUNT(DISTINCT InvoiceNo),
        2
    ) AS avg_order_value,
    ROUND(SUM(Revenue), 2) AS total_revenue
FROM transactions
WHERE CustomerID IS NOT NULL
    AND CustomerID <> ''
GROUP BY CustomerID
ORDER BY avg_order_value DESC
LIMIT 20;


-- Customer Value versus Frequency

-- How does average customer revenue vary across purchase-frequency bands?

SELECT
    CASE
        WHEN total_invoices >= 20 THEN '20+ invoices'
        WHEN total_invoices >= 10 THEN '10 - 19 invoices'
        WHEN total_invoices >= 5 THEN '5 - 9 invoices'
        ELSE '<5 invoices'
    END AS invoice_frequency_band,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_revenue), 2) AS avg_customer_revenue,
    ROUND(SUM(total_revenue), 2) AS total_revenue
FROM (
    SELECT
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS total_invoices,
        SUM(Revenue) AS total_revenue
    FROM transactions
    WHERE CustomerID IS NOT NULL
    AND CustomerID <> ''
    GROUP BY CustomerID
) AS customer_summary
GROUP BY invoice_frequency_band
ORDER BY
    CASE invoice_frequency_band
        WHEN '20+ invoices' THEN 1
        WHEN '10 - 19 invoices' THEN 2
        WHEN '5 - 9 invoices' THEN 3
        ELSE 4
    END;


-- Category-Level Inventory Risk

-- Which categories contain the largest number of high-risk products?
-- High-risk products are defined as having both above-average
-- monthly demand and above-average monthly demand variability.

SELECT
    t.Category,
    COUNT(DISTINCT t.StockCode) AS high_risk_products
FROM transactions t
JOIN (
    SELECT
        StockCode
    FROM monthly_product_demand
    GROUP BY StockCode
    HAVING
        AVG(monthly_quantity) > 96.3
        AND STDDEV(monthly_quantity) > 120.7
) AS risky_products
    ON t.StockCode = risky_products.StockCode
WHERE t.Quantity > 0
GROUP BY t.Category
ORDER BY high_risk_products DESC;


-- Which categories have the highest proportion of products
-- classified as high risk?

SELECT
    category_totals.Category,
    category_totals.total_products,
    COALESCE(risky.high_risk_products, 0) AS high_risk_products,
    ROUND(
        COALESCE(risky.high_risk_products, 0)
        / category_totals.total_products * 100,
        1
    ) AS high_risk_percentage
FROM (
    SELECT
        Category,
        COUNT(DISTINCT StockCode) AS total_products
    FROM transactions
    WHERE Quantity > 0
    GROUP BY Category
) AS category_totals
LEFT JOIN (
    SELECT
        t.Category,
        COUNT(DISTINCT t.StockCode) AS high_risk_products
    FROM transactions t
    JOIN (
        SELECT
            StockCode
        FROM monthly_product_demand
        GROUP BY StockCode
        HAVING
            AVG(monthly_quantity) > 96.3
            AND STDDEV(monthly_quantity) > 120.7
    ) AS risky_products
        ON t.StockCode = risky_products.StockCode
    WHERE t.Quantity > 0
    GROUP BY t.Category
) AS risky
    ON category_totals.Category = risky.Category
ORDER BY high_risk_percentage DESC;


-- Which high-risk products generate the greatest amount of revenue?
-- This identifies products where inventory uncertainty is combined
-- with significant financial exposure.

WITH product_demand AS (
    SELECT
        StockCode,
        AVG(monthly_quantity) AS avg_monthly_quantity,
        STDDEV(monthly_quantity) AS demand_stddev
    FROM monthly_product_demand
    GROUP BY StockCode
),
product_revenue AS (
    SELECT
        StockCode,
        MAX(Description) AS Description,
        MAX(Category) AS Category,
        SUM(Quantity) AS total_units,
        SUM(Revenue) AS total_revenue
    FROM transactions
    WHERE Quantity > 0
    GROUP BY StockCode
)
SELECT
    r.StockCode,
    r.Description,
    r.Category,
    ROUND(r.total_revenue, 2) AS total_revenue,
    r.total_units,
    ROUND(d.avg_monthly_quantity, 1) AS avg_monthly_quantity,
    ROUND(d.demand_stddev, 1) AS demand_stddev
FROM product_revenue r
JOIN product_demand d
    ON r.StockCode = d.StockCode
WHERE d.avg_monthly_quantity > 96.3
    AND d.demand_stddev > 120.7
ORDER BY r.total_revenue DESC
LIMIT 30;

-- The highest-revenue high-risk products include:
-- REGENCY CAKESTAND 3 TIER (£344,563),
-- WHITE HANGING HEART T-LIGHT HOLDER (£267,102),
-- RED RETROSPOT JUMBO BAG (£185,566),
-- PAPER CRAFT, LITTLE BIRDIE (£168,470),
-- and PARTY BUNTING (£149,187).
-- This identifies products where unpredictable demand is combined with
-- substantial revenue exposure, making them particularly important
-- candidates for inventory management attention.