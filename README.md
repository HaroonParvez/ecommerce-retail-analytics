# Retail Sales, Demand & Product Risk Analysis

An end-to-end data analytics project using the UCI Online Retail II dataset to investigate sales performance, product demand patterns, demand volatility and potential inventory-planning challenges.

The project uses Python for data cleaning and preparation, MySQL/SQL for analytical analysis, and Power BI for interactive reporting and visualisation. The analysis concludes with evidence-based business recommendations focused on demand and inventory planning.

---

## Business Question

Which product categories and products present the greatest challenges for demand and inventory planning, when does demand become more difficult to predict, and where should the business focus its attention?

The analysis examines:

- Overall sales and revenue performance
- Product and category demand
- Seasonal demand patterns
- Demand volatility
- High-demand, high-variability products
- Revenue concentration across customers and products
- Geographic sales distribution

---

## Dataset

**UCI Online Retail II**

The dataset contains approximately 1 million transaction line items from a UK-based online retailer covering **December 2009 to December 2011**.

Each row represents a product line within a customer invoice.

The original dataset contains information including:

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
| **MySQL / SQL** | Data analysis, demand benchmarking and risk identification |
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
Demand analysis
Product risk analysis
Category analysis
Customer analysis
      │
      ▼
Power BI
Interactive dashboards
      │
      ▼
Key Findings
      │
      ▼
Business Recommendations
```

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

> **Note:** The raw and cleaned datasets are not included in the repository due to file size.

---

## Data Cleaning & Preparation

The raw dataset contained several data-quality issues which were investigated before analysis:

| Issue | Finding | Decision |
|---|---|---|
| **Missing Customer ID** | A substantial proportion of records had no customer identifier | Retained where appropriate because the main analysis is not dependent on customer-level information |
| **Cancelled orders** | Identified using C-prefixed invoice numbers | Separated from normal sales and excluded from the final sales dataset |
| **Negative quantities outside cancellations** | Records were associated with descriptions such as damages, missing items, and unsaleable stock | Treated as internal stock write-offs and removed |
| **Zero-price records** | Many were associated with adjustment-style descriptions, while some were linked to genuine customers | Adjustment records removed; genuine customer records retained |
| **Duplicate line items** | Duplicate patterns were assessed at invoice level | Retained where the pattern was consistent with genuine repeated purchases |
| **Non-product transactions** | Postage, manual adjustments, and other administrative entries were identified | Removed from the sales analysis |
| **Product categorisation** | Products were assigned to business categories using a keyword-based approach | Categories created for downstream product and demand analysis |

The full cleaning process and reasoning are documented in `main.ipynb`.

---

## Product Categorisation

Products were grouped into 11 categories using a keyword-based classification approach:

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

The categorisation approach was designed around the highest-revenue product descriptions and covers approximately **95% of total revenue**. The remaining long-tail products were retained within the **Other** category rather than being forced into potentially unsuitable categories.

*A limitation of this approach is that keyword-based classification can produce occasional edge-case misclassifications.*

---

## SQL Analysis

The SQL analysis was used to move from descriptive sales figures towards demand and product-risk analysis.

**Key areas included:**
- Overall revenue and sales performance
- Revenue and units by product category
- Monthly demand patterns
- Average and standard deviation of monthly product demand
- Identification of high-demand, high-variability products
- Category-level concentration of high-risk products
- Seasonal revenue variability
- Customer revenue concentration
- Product revenue concentration

### Demand Risk Definition
Products were classified as **higher risk** when they demonstrated both:
1. Above-average monthly demand
2. Above-average monthly demand variability

This was used as an indicator of products that may be more difficult to manage using a simple, uniform inventory-planning approach.

---

## Key Findings

1. **Kitchen & Baking is the largest revenue-generating category**  
   Kitchen & Baking generated approximately **£5.29 million**, representing **26.25% of total revenue**. It was substantially ahead of the second-largest category, Home Decor & Storage (**£3.38 million**). This makes Kitchen & Baking an important category for inventory planning because demand-management decisions in this category have a relatively large potential impact on overall sales.

2. **Several categories contain a high proportion of high-demand, high-variability products**  
   Craft & Art had the highest proportion of products classified as high-risk at **38.0%**, followed by:
   - **Bags & Totes:** 35.4%
   - **Gift Wrap & Party:** 32.7%
   - **Christmas & Seasonal:** 27.4%
   - **Kitchen & Baking:** 19.7%  
   This indicates that the categories generating the most sales are not necessarily the categories with the greatest proportion of difficult-to-forecast products.

3. **Demand increases sharply towards the end of the year**  
   Monthly revenue increased substantially during the second half of the year. Average monthly revenue was highest in:
   - **November:** £2.90 million *(strongest month overall)*
   - **December:** £2.61 million
   - **October:** £2.21 million  
   The recurring increase towards the end of the year suggests that seasonal planning is particularly important during Q4.

4. **Christmas & Seasonal has the greatest revenue variability**  
   Christmas & Seasonal had the highest monthly revenue standard deviation at approximately **£112,049**, considerably above the other categories. This reflects the highly seasonal nature of the category and indicates that demand for these products should not necessarily be treated as stable throughout the year.

5. **Individual products can combine strong revenue with highly variable demand**  
   Several high-revenue products also demonstrated substantial demand variability. For example, `PAPER CRAFT, LITTLE BIRDIE` generated approximately **£168,470** in revenue while recording an average monthly demand of approximately **3,240 units** and a demand standard deviation of approximately **15,872 units**. This illustrates why product-level demand variability can be important alongside overall category performance.

---

## Business Recommendations

1. **Prioritise inventory planning for high-revenue categories**  
   Kitchen & Baking generated **26.25% of total revenue**, making it the largest category in the analysis. Inventory planning and forecasting efforts should therefore prioritise high-revenue categories where inaccurate demand planning could have a larger commercial impact.

2. **Use differentiated planning for high-variability products**  
   Categories such as **Craft & Art**, **Bags & Totes**, and **Gift Wrap & Party** contain relatively high proportions of products with both high demand and high variability. These products should receive greater forecasting and monitoring attention rather than applying the same replenishment assumptions across the entire product range.

3. **Increase planning attention ahead of Q4**  
   The strong increase in revenue during October, November, and December indicates that demand planning should account for the recurring Q4 increase. Inventory, purchasing, and fulfilment capacity should be reviewed ahead of the seasonal increase rather than reacting after demand has already risen.

4. **Treat highly seasonal categories differently from stable categories**  
   Christmas & Seasonal showed the highest monthly revenue variability. A seasonal forecasting approach would therefore be more appropriate for these products than relying on a simple annual or overall monthly average.

---

## Power BI Dashboard

The analysis was presented through three interactive Power BI dashboards.

## Dashboard 1 — Retail Sales & Inventory Analysis

Provides an overview of overall sales performance, including revenue, units sold, orders, customers, average order value, monthly revenue and category performance.

![Dashboard 1 - Retail Sales & Inventory Analysis](images/dashboard_1.png)

---

## Dashboard 2 — Product & Demand Analysis

Examines product-level and category-level demand, including monthly units, average unit prices, product counts and yearly demand comparisons.

![Dashboard 2 - Product & Demand Analysis](images/dashboard_2.png)

---

## Dashboard 3 — Product Risk & Demand Quality

Focuses on demand quality and potential planning difficulty, including demand volatility, product-level risk detail, customer revenue concentration and geographic sales distribution.

![Dashboard 3 - Product Risk & Demand Quality](images/dashboard_3.png)


---

## Limitations

- The product categorisation uses keyword matching rather than a dedicated machine-learning or NLP classification model.
- Approximately 5% of revenue remains in the `Other` category to avoid forcing ambiguous products into unsuitable categories.
- Customer-level demographic information is not available in the dataset.
- The dataset represents a single retailer over a fixed period from 2009–2011.
- The analysis identifies potential inventory-planning risks from historical demand patterns but does not contain actual stock-on-hand, lead-time, or supplier data. Therefore, it cannot directly measure stockouts or overstock levels.

---

## Author

**Haroon Parvez**  
[LinkedIn Profile](https://www.linkedin.com/in/haroon-parvez)
