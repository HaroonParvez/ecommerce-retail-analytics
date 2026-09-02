# Retail Sales, Demand & Revenue Risk Analysis

An end-to-end data analytics project using the UCI Online Retail II dataset to investigate where a retail business's revenue is most exposed to risk, focusing on demand patterns, product performance, customer concentration and cancellation rates.

The project uses Python for data cleaning and preparation, MySQL/SQL for analytical analysis, and Power BI for interactive reporting and visualisation. The analysis concludes with evidence-based business recommendations tied directly to the findings.

---

## Contents

- [Business Question](#business-question)
- [Dataset](#dataset)
- [Tools & Technologies](#tools--technologies)
- [Analytical Pipeline](#analytical-pipeline)
- [Repository Structure](#repository-structure)
- [Data Cleaning & Preparation](#data-cleaning--preparation)
- [Product Categorisation](#product-categorisation)
- [Methodology Note: Cancellation Rate](#methodology-note-cancellation-rate)
- [SQL Analysis](#sql-analysis)
- [Key Findings](#key-findings)
- [Business Recommendations](#business-recommendations)
- [Power BI Dashboard](#power-bi-dashboard)
- [Limitations](#limitations)
- [Author](#author)

---

## Business Question

**Where is this business's revenue most exposed to risk, and which product categories, products, and customer segments should be prioritised to manage that risk?**

The analysis examines this from three analytical perspectives:

1. **Demand risk:** which categories and products combine high demand with high demand variability, making demand more difficult to plan around.
2. **Concentration risk:** how dependent revenue is on a relatively small number of customers or products.
3. **Cancellation rate:** how cancellation rates vary across product categories, calculated separately in Python using the full transaction dataset.

The first two perspectives form the main SQL and Power BI analysis, while cancellation rate is treated as a supplementary Python analysis because cancelled transactions are excluded from the cleaned dataset used downstream.

---

## Dataset

**UCI Online Retail II**

The dataset contains **1,067,371 transaction line items** from a UK-based online retailer covering **December 2009 to December 2011**.

Each row represents a product line within a customer invoice.

The original dataset contains:

- Invoice number
- Stock code
- Product description
- Quantity
- Invoice date
- Unit price
- Customer ID
- Country

The raw dataset is not included in this repository due to file size. It can be obtained from the [UCI Machine Learning Repository](https://archive.ics.uci.edu/dataset/502/online+retail+ii).

---

## Tools & Technologies

| Tool | Purpose |
|---|---|
| **Python (pandas)** | Data cleaning, quality checks, product categorisation, cancellation-rate analysis |
| **MySQL / SQL** | Demand analysis, product risk identification, category analysis and customer revenue analysis |
| **Power BI / DAX** | Interactive dashboards, KPIs and visual analysis |

---

## Analytical Pipeline

```text
Raw Excel Data
      │
      ▼
Python
Data cleaning & preparation
Product categorisation
Cancellation-rate analysis on full dataset
      │
      ▼
Cleaned Sales Dataset
Non-cancelled, positive-quantity sales
      │
      ▼
MySQL / SQL
Demand analysis
Product risk analysis
Category analysis
Customer revenue analysis
      │
      ▼
Power BI
Interactive dashboards
      │
      ▼
Key Findings → Business Recommendations

```

## Repository Structure

├── data_cleaning.ipynb
├── retail_analysis.sql
├── retail_dashboards.pbix
├── images/
│   ├── dashboard_1.png
│   ├── dashboard_2.png
│   └── dashboard_3.png
└── README.md

> **Note:** The full cleaning process and reasoning are documented in `data_cleaning.ipynb`.

---

## Product Categorisation

Products were grouped into 11 business-relevant categories using a rule-based keyword classification approach:

- Kitchen & Baking
- Home Decor & Storage
- Bags & Totes
- Lighting & Candles
- Novelty & Gifts
- Christmas & Seasonal
- Gift Wrap & Party
- Garden & Nature
- Home Comfort & Textiles
- Craft & Art
- Other

Keywords were developed by reviewing high-revenue product descriptions and common product-description patterns. Products that could not be confidently assigned to one of the defined categories were retained in an **Other** category.

The final categorisation accounts for approximately **93.6% of revenue**, with Other representing **6.4%**.

* **Limitation:** Keyword-based classification can occasionally misclassify products where a keyword appears as part of an unrelated description. The Other category was retained rather than forcing uncertain products into an unsuitable category.

### Methodology Note: Cancellation Rate
- **Separate Calculation:** Cancellation rate is calculated separately in Python, rather than in SQL or Power BI, because the downstream cleaned dataset intentionally excludes cancelled transactions (which would yield a 0% rate).
- **Dataset Scope:** The cancellation rate was calculated using the full transaction dataset prior to removing cancelled transactions.
- **Line-Level Metric:** The analysis measures cancelled transaction lines as a percentage of total transaction lines (a line-level cancellation rate, not a percentage of entire customer orders).
- **Result:** The overall cancellation rate was **1.83%**, with category-level rates ranging from **0.7%** (Gift Wrap & Party) to **2.7%** (Lighting & Candles).

---

## SQL Analysis

**Key areas covered:**
- Revenue and units by product category
- Monthly demand patterns and seasonality
- Average and standard deviation of monthly product demand
- Identification of products with both high demand and high demand variability
- Category-level concentration of higher-risk products
- Customer revenue concentration
- Product revenue concentration
- Customer purchase frequency and activity

### Demand Risk Definition
A product is classified as **higher demand risk** when it meets both of the following dataset-derived benchmarks:
1. **Average monthly demand** > 96.3 units
2. **Monthly demand standard deviation** > 120.7 units

*These thresholds represent the median average monthly demand and median demand variability across products. This is an analytical measure of demand-planning difficulty and does not directly measure stockout or overstock risk, as the dataset lacks stock-on-hand or supply-chain data.*

---

## Key Findings

1. **Kitchen & Baking is the largest revenue-generating category**  
   Kitchen & Baking generated approximately **£5.29 million** (26.25% of total revenue), substantially ahead of Home Decor & Storage at **£3.38 million**. Its cancellation rate was also relatively high at **2.6%**, second only to Lighting & Candles (**2.7%**).

2. **Cancellation rates remain within a narrow range across categories**  
   The overall cancellation rate was **1.83%** of transaction lines. Category-level rates ranged tightly from **0.7%** (Gift Wrap & Party) to **2.7%** (Lighting & Candles).

3. **Craft & Art has the highest proportion of higher-risk products**  
   **38.0%** of Craft & Art products meet the higher-risk definition (above-median demand and variability). This is followed by:
   - **Bags & Totes:** 35.4%
   - **Gift Wrap & Party:** 32.7%
   - **Christmas & Seasonal:** 27.4%
   - **Kitchen & Baking:** 19.7% *(despite being the largest overall revenue generator)*

4. **Revenue is strongly seasonal, peaking in Q4**  
   Across both years, the highest-revenue months were:
   - **November:** £2.90 million
   - **December:** £2.61 million
   - **October:** £2.21 million  
   This highlights a dramatic, recurring surge towards the final quarter of the year.

5. **Christmas & Seasonal has the highest demand volatility**  
   Christmas & Seasonal recorded the highest category-level coefficient of variation at **1.04**, indicating substantial variation in monthly demand relative to its average demand.

6. **Individual products can show extreme demand variability**  
   `PAPER CRAFT, LITTLE BIRDIE` generated approximately **£168,470** in revenue while averaging **~3,240 units/month**. Its monthly demand variability was **~15,872 units**, yielding a volatility ratio of **~4.9** relative to its average monthly demand.

7. **Revenue is more concentrated among customers than products**  
   The **top 10 customers account for 26.54% of revenue**, compared with **7.83% for the top 10 products**, indicating greater exposure to customer loss than product-level dependence.

---

## Business Recommendations

1. **Prioritise Kitchen & Baking for operational review**  
   Because Kitchen & Baking accounts for 26.25% of revenue and has a 2.6% line cancellation rate, it should be the focus of fulfillment and operational reviews to address root causes of cancellations.

2. **Use differentiated demand planning across categories**  
   Craft & Art, Bags & Totes, and Gift Wrap & Party carry the highest proportions of higher-risk demand SKUs. Apply more frequent demand reviews to these categories rather than using uniform planning assumptions.

3. **Prepare for stronger demand during Q4**  
   Build inventory and fulfillment capacity ahead of the October–December peak. Christmas & Seasonal requires dedicated forecasting models due to its high demand volatility.

4. **Monitor high-value customer accounts**  
   With the top 10 customers driving 26.54% of total revenue, set up account health monitoring and dedicated retention workflows to protect key customer relationships.

5. **Manually review products with extreme demand variability**  
   Isolate SKUs like `PAPER CRAFT, LITTLE BIRDIE` that exceed both high-demand and high-variability thresholds for manual demand reviews rather than relying on automated, stable-demand algorithms.

---

## Power BI Dashboard

* **Dashboard 1: Sales Performance**  
  Overview of overall sales performance, including revenue, units sold, orders, average order value, monthly revenue trends, and category revenue performance.

![Dashboard 1 - Sales Performance](images/dashboard_1.png)

* **Dashboard 2: Product & Demand Analysis**  
  Product and category demand analysis, including total product count, average monthly units, average units per product, average revenue per product, average unit price by category, and monthly demand across years.

![Dashboard 2 - Product & Demand Analysis](images/dashboard_2.png)

* **Dashboard 3: Demand Risk & Product Volatility**  
  Demand-planning analysis covering category-level demand volatility, product-level higher-risk demand detail, and customer revenue concentration.

![Dashboard 3 - Demand Risk & Product Volatility](images/dashboard_3.png)

---

## Limitations

- **Rule-Based Categorisation:** Uses keyword matching rather than ML/NLP algorithms; ~6.4% of revenue remains in the `Other` category.
- **Missing Customer IDs:** Approximately 23% of final cleaned records lack a Customer ID, limiting customer-level completeness.
- **Demographics:** Customer demographic data is absent from the dataset.
- **Scope & Generalisability:** Represents a single UK-based online retailer over a fixed period (Dec 2009–Dec 2011).
- **Supply Chain Data:** Identifies demand risk from transaction history only; lacks stock-on-hand, lead time, or supplier data, so stockouts and inventory holding levels cannot be measured directly.
- **Threshold Definition:** The higher-risk SKU classification relies on dataset-derived median thresholds rather than fixed operational parameters.
- **Cancellation Calculation:** Cancellation rates are calculated separately in Python at the transaction-line level on the raw dataset because cancelled rows are removed from the cleaned analytics model.

---

## Author

**Haroon Parvez**  
[LinkedIn Profile](https://www.linkedin.com/in/haroon-parvez)
