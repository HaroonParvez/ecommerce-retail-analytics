# Retail Sales, Demand & Revenue Risk Analysis

An end-to-end data analytics project using the UCI Online Retail II dataset to investigate where a retail business's revenue is most exposed to risk, focusing on sales performance, product demand, demand volatility and revenue concentration.

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
- [SQL Analysis](#sql-analysis)
- [Key Findings](#key-findings)
- [Business Recommendations](#business-recommendations)
- [Power BI Dashboard](#power-bi-dashboard)
- [Limitations](#limitations)
- [Author](#author)

---

## Business Question

**Where is this business's revenue most exposed to risk, and which product categories, products, and customer segments should be prioritised to manage that risk?**

The analysis focuses on three main areas:

1. **Sales and category performance:** understanding where revenue and unit demand are concentrated.
2. **Demand risk:** identifying categories and products with high demand and high variability, where demand may be more difficult to plan for.
3. **Revenue concentration:** assessing how dependent revenue is on a relatively small number of customers and products.

---

## Dataset

**UCI Online Retail II**

The dataset contains approximately **1 million transaction line items** from a UK-based online retailer covering **December 2009 to December 2011**.

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
| **Python (pandas)** | Data cleaning, quality checks and product categorisation |
| **MySQL / SQL** | Sales analysis, demand analysis, product risk analysis and customer revenue analysis |
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
      │
      ▼
Cleaned Sales Dataset
      │
      ▼
MySQL / SQL
Sales & category analysis
Demand analysis
Product risk analysis
Customer revenue analysis
      │
      ▼
Power BI
Interactive dashboards
      │
      ▼
Key Findings → Business Recommendations

## Repository Structure

```text
├── data_cleaning.ipynb
├── retail_analysis.sql
├── retail_dashboards.pbix
├── images/
│   ├── dashboard_1.png
│   ├── dashboard_2.png
│   └── dashboard_3.png
└── README.md
```

## Data Cleaning & Preparation

The raw dataset contained several data-quality issues. Each was investigated before deciding how it should be handled:

| Issue | Finding | Decision |
|---|---|---|
| **Missing Customer ID** | A substantial proportion of records had no customer identifier | Retained because the main analysis can be performed at category and revenue level. This remains a limitation for customer-level analysis |
| **Missing descriptions** | 4,382 records had no product description | Removed because they could not be reliably used for product-level analysis or categorisation |
| **Negative quantities** | 768 non-cancelled rows had negative quantities. These had no Customer ID and included descriptions such as "damages", "missing", "thrown away" and "unsaleable, destroyed" | Treated as internal stock/operational adjustments rather than normal sales and removed |
| **Zero-price records** | 1,820 records had a price of zero. 1,749 had no Customer ID while 71 were associated with known customers | Zero-price records without a Customer ID were removed as adjustment-style records. Records associated with known customers were retained |
| **Duplicate line items** | 66,100 records matched on invoice, stock code, quantity, invoice date and price | Retained because examples indicated genuine repeated purchases could not be distinguished from duplicates using the available fields |
| **Non-product transactions** | Administrative entries such as postage, manual adjustments, checks and fees were identified | Removed from the sales analysis |

After cleaning, the final sales dataset contained **1,037,526 records**.

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

Keywords were developed by reviewing high-revenue product descriptions and common product-description patterns. The resulting classification was implemented as a reproducible rule-based approach in Python.

The categorisation covers approximately **93.6% of total revenue**, with **6.4%** remaining in the **Other** category rather than being force-assigned to an unsuitable category.

* **Limitation:** Keyword-based classification can produce occasional edge-case misclassifications.

---

## SQL Analysis

The SQL analysis moves from overall sales performance into demand, product, and customer-level analysis.

**Key areas covered:**
- Overall revenue and unit sales
- Revenue and units by product category
- Monthly demand patterns and seasonality
- Product-level average monthly demand
- Product-level demand variability
- Identification of products with both high demand and high demand variability
- Category-level concentration of higher-risk products
- Customer revenue concentration
- Product revenue concentration
- Customer purchase frequency and activity

### Demand Risk Definition
A product is classified as **higher demand risk** when it meets both of the following conditions:
1. **Average monthly demand** > 96.3 units
2. **Monthly demand standard deviation** > 120.7 units

*The 96.3 and 120.7 thresholds are the median values of the corresponding product-level distributions and are therefore derived from the dataset rather than chosen arbitrarily. This classification is an analytical indicator of demand-planning difficulty. It does not directly measure stockout or overstock risk because the dataset does not contain stock-on-hand, supplier, or lead-time information.*

---

## Key Findings

1. **Kitchen & Baking is the largest revenue-generating category**  
   Kitchen & Baking generated approximately **£5.29 million**, representing **26.25% of total revenue**, substantially ahead of Home Decor & Storage at approximately **£3.38 million**. Its large revenue contribution means that demand-planning or operational issues within this category could have a comparatively large effect on overall sales.

2. **Revenue is strongly seasonal**  
   Across the two years combined, the highest-revenue months were:
   - **November:** £2.90 million
   - **December:** £2.61 million
   - **October:** £2.21 million  
   This indicates a clear increase in sales towards the final quarter of the year.

3. **Some categories contain a much higher proportion of higher-risk products**  
   The proportion of products meeting the high-demand/high-variability definition was highest in:
   - **Craft & Art:** 38.0%
   - **Bags & Totes:** 35.4%
   - **Gift Wrap & Party:** 32.7%
   - **Christmas & Seasonal:** 27.4%
   - **Kitchen & Baking:** 19.7%  
   This shows that the category generating the most revenue is not necessarily the category containing the greatest proportion of difficult-to-plan products.

4. **Christmas & Seasonal has the highest demand volatility**  
   Christmas & Seasonal recorded the highest category-level coefficient of variation at **1.04**, indicating substantial variation in monthly demand relative to its average. This reinforces the importance of treating seasonal demand differently from categories with more stable purchasing patterns.

5. **Individual products can show extreme demand variability**  
   `PAPER CRAFT, LITTLE BIRDIE` generated approximately **£168,470** in revenue while averaging around **3,240 units per month**. Its monthly demand standard deviation was approximately **15,872 units**, giving it a volatility ratio of approximately **4.9** relative to its average monthly demand. This demonstrates that product-level demand behaviour can be considerably more volatile than category-level averages suggest.

6. **Revenue is more concentrated among customers than products**  
   The **top 10 customers account for 26.54% of total revenue**, compared with **7.83% for the top 10 products**. This indicates that revenue exposure is more concentrated among the largest customers than among individual products.

---

## Business Recommendations

1. **Prioritise Kitchen & Baking for operational and demand-planning review**  
   Kitchen & Baking represents **26.25% of total revenue**, making it the most financially significant category. Demand-planning and fulfilment processes in this category should therefore receive particular attention because improvements or problems can have a relatively large effect on overall revenue.

2. **Use differentiated demand planning across categories**  
   Craft & Art, Bags & Totes, and Gift Wrap & Party have the highest proportions of products classified as higher demand risk. These categories should receive more frequent demand reviews and more tailored planning assumptions rather than applying a uniform approach across the entire product range.

3. **Prepare for stronger demand during Q4**  
   Revenue increases substantially during October–December. Purchasing and fulfilment planning should therefore be reviewed ahead of this period, with particular attention given to Christmas & Seasonal due to its high demand volatility.

4. **Monitor high-value customer accounts**  
   The top 10 customers account for **26.54% of total revenue**, representing a significant concentration of revenue. These customers should therefore receive closer retention and account-health monitoring because losing a major account could have a material effect on revenue.

5. **Manually review products with extreme demand variability**  
   Products meeting both the high-demand and high-variability thresholds should receive additional review rather than being treated as stable-demand products. Products such as `PAPER CRAFT, LITTLE BIRDIE` demonstrate why product-level demand behaviour can require more attention than category-level averages alone would suggest.

---

## Power BI Dashboard

* **Dashboard 1: Sales Performance**  
  Provides an overview of sales performance, including total revenue, units sold, average order value, order volume, monthly revenue trends and revenue by product category.

![Dashboard 1 - Sales Performance](images/dashboard_1.png)

* **Dashboard 2: Product & Demand Analysis**  
  Examines product and demand patterns using total products, average monthly units, average units per product, average revenue per product, average unit price by category and monthly unit demand across the dataset.

![Dashboard 2 - Product & Demand Analysis](images/dashboard_2.png)

* **Dashboard 3: Demand Risk & Product Volatility**  
  Focuses on demand volatility and revenue concentration, including category-level demand volatility, customer revenue concentration and a product-level demand risk table highlighting products with high demand and high variability.

![Dashboard 3 - Demand Risk & Product Volatility](images/dashboard_3.png)

---

## Limitations

- **Rule-Based Categorisation:** Product categorisation uses keyword matching rather than a dedicated machine-learning or NLP classification model. Approximately **6.4% of revenue** remains in the `Other` category to avoid force-fitting ambiguous products.
- **Missing Customer IDs:** Approximately **23% of final cleaned records** have no Customer ID, limiting the completeness of customer-level analysis.
- **Lack of Demographics:** The dataset does not contain customer demographic information.
- **Scope & Generalisability:** The dataset represents a single UK-based retailer over a fixed period from **December 2009 to December 2011**, meaning findings should not be generalized beyond this dataset.
- **Supply Chain Data Absence:** The analysis identifies potential demand-planning difficulty from historical transaction patterns but does not contain stock-on-hand, supplier, or lead-time information. It therefore cannot directly measure actual stockouts, overstock, or inventory levels.
- **Analytical Risk Framework:** The higher demand-risk classification is a dataset-derived analytical measure based on relative median thresholds rather than a direct measure of operational inventory risk.

---

## Author

**Haroon Parvez**  
[LinkedIn Profile](https://www.linkedin.com/in/haroon-parvez)
