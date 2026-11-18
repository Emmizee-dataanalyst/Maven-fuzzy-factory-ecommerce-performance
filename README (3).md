# E-commerce Sales Performance and Customer Behaviour Analysis

**Maven Fuzzy Factory | MySQL | Power BI**

An end-to-end analysis of an online toy retailer's sales, website traffic and refunds. Six raw CSV files were loaded into MySQL, queried with SQL to answer ten business questions, and then visualised in a two-page Power BI dashboard.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Business Questions](#2-business-questions)
3. [Dataset](#3-dataset)
4. [Tools Used](#4-tools-used)
5. [Repository Structure](#5-repository-structure)
6. [Data Preparation and Cleaning](#6-data-preparation-and-cleaning)
7. [SQL Analysis](#7-sql-analysis)
8. [Power BI Dashboard](#8-power-bi-dashboard)
9. [Key Results](#9-key-results)
10. [Findings](#10-findings)
11. [Recommendations](#11-recommendations)
12. [Limitations](#12-limitations)
13. [How to Reproduce This Project](#13-how-to-reproduce-this-project)
14. [Deliverables](#14-deliverables)
15. [Author](#15-author)

---

## 1. Project Overview

Maven Fuzzy Factory is a fictional online toy retailer. This project analyses its order, traffic and refund data to understand:

- what drives revenue and which products perform best,
- where website visitors come from and how well each source converts,
- how much money is lost to refunds, and where,
- how performance changes over time.

The final output is a set of SQL queries, an interactive Power BI dashboard, an analytical report, and a set of business insights and recommendations.

## 2. Business Questions

| # | Question |
|---|---|
| 1 | What is the total number of unique orders? |
| 2 | What is the total revenue generated? |
| 3 | Which five products generate the highest revenue? |
| 4 | Which product categories or product types perform best, where available? |
| 5 | Which marketing sources generate the most website sessions? |
| 6 | Which device type generates the most website traffic? |
| 7 | What is the website session-to-order conversion rate? |
| 8 | What is the total number and value of refunds? |
| 9 | Which months recorded the highest and lowest revenue? |
| 10 | What is the average order value? |

## 3. Dataset

The data comes from the **Maven Fuzzy Factory** e-commerce dataset (Maven Analytics), provided as six CSV files. It covers **March 2012 to March 2015**.

| Table | Grain | Primary key | Foreign keys |
|---|---|---|---|
| `website_sessions` | One row per website visit | `website_session_id` | none |
| `website_pageviews` | One row per page viewed | `website_pageview_id` | `website_session_id` |
| `orders` | One row per order | `order_id` | `website_session_id`, `primary_product_id` |
| `order_items` | One row per item in an order | `order_item_id` | `order_id`, `product_id` |
| `order_item_refunds` | One row per refunded item | `order_item_refund_id` | `order_item_id`, `order_id` |
| `products` | One row per product | `product_id` | none |

Every table also has a `created_at` timestamp.

### Data model

```
website_sessions ──< website_pageviews
        │
        └──< orders ──< order_items ──< order_item_refunds
                              │
                         products ──<┘
```

`──<` means one-to-many. The customer journey runs from session, to pageviews, to order, to order items, to refunds.

### Notes on the data

- **`utm_source`** tells you which marketing channel brought the visit: `gsearch` (Google paid search), `bsearch` (Bing paid search) and `socialbook` (paid social). A blank value means the visit was **direct or organic**.
- **Four products** are sold: The Original Mr. Fuzzy, The Forever Love Bear, The Birthday Sugar Panda and The Hudson River Mini bear. There is no separate category column, so "product type" means the product itself.
- **2012 and 2015 are partial years** (about 10 months and 3 months), so comparisons with full years are unfair. The analysis focuses on the two full years, **2013 and 2014**.

## 4. Tools Used

| Tool | Purpose |
|---|---|
| MySQL and MySQL Workbench | Storing the data and answering the business questions |
| SQL | Joins, aggregations, conversion and refund analysis |
| Power BI Desktop | Data model, DAX measures and dashboards |
| DAX | KPIs, ratios and ranking measures |

## 5. Repository Structure

```
maven-fuzzy-factory-analysis/
│
├── README.md
├── data/
│   └── raw/                          # the six original CSV files
├── sql/
│   ├── 01_create_database_and_tables.sql
│   ├── 02_load_data.sql
│   └── 03_business_questions.sql
├── powerbi/
│   └── maven_fuzzy_factory.pbix
├── images/
│   ├── product_performance.png
│   └── refunds_and_sessions.png
├── report/
│   └── Analytical_Report.pdf
└── video/
    └── dashboard_demo_link.txt
```

## 6. Data Preparation and Cleaning

The transformation steps, in order:

1. **Created the database and tables** in MySQL with explicit data types: `INT` for keys, `DATETIME` for `created_at`, `DECIMAL(10,2)` for money columns and `TINYINT` for the 1/0 flags.
2. **Loaded the CSV files.** The two largest files (`website_sessions` and `website_pageviews`) were loaded with `LOAD DATA INFILE`, because the Table Data Import Wizard was far too slow for hundreds of thousands of rows.
3. **Standardised dates.** MySQL only accepts `YYYY-MM-DD hh:mm:ss`. Dates written in other formats (for example `1/15/2014 16:32`) were converted before or during the load, either in Excel or with `STR_TO_DATE`.
4. **Validated the load.** Compared row counts with the source files, confirmed each primary key is unique, and checked that every order has exactly one primary item.
5. **Handled missing UTM values.** Blank `utm_source`, `utm_campaign` and `utm_content` values were kept, because they represent direct and organic visits. They are labelled `direct / organic` in the reporting layer instead of being deleted.
6. **Modelled the data in Power BI.** Tables were renamed with short names and linked with one-to-many, single-direction relationships (see Section 8).
7. **Resolved an ambiguous relationship path.** A direct link between `order_item_refunds` and `orders` created two competing paths (directly, and through `order_items`) and made the `orders` to `order_items` relationship inactive. Removing the direct link fixed it.

> **Tip for large files:** `website_pageviews` has more than 1.1 million rows, which is more than Excel's limit of 1,048,576 rows. Do not open and re-save it in Excel, or rows will be silently lost.

## 7. SQL Analysis

All queries are in `sql/03_business_questions.sql`. Examples:

**Total unique orders and total revenue**

```sql
SELECT COUNT(DISTINCT order_id) AS total_orders,
       SUM(price_usd)           AS total_revenue
FROM orders;
```

**Top products by revenue, with margin**

```sql
SELECT p.product_name,
       COUNT(*)                                   AS units_sold,
       SUM(oi.price_usd)                          AS revenue,
       SUM(oi.price_usd - oi.cogs_usd)            AS gross_profit,
       ROUND(SUM(oi.price_usd - oi.cogs_usd)
             / SUM(oi.price_usd) * 100, 2)        AS margin_pct
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.product_name
ORDER BY revenue DESC;
```

**Session-to-order conversion rate**

```sql
SELECT COUNT(DISTINCT s.website_session_id) AS sessions,
       COUNT(DISTINCT o.order_id)           AS orders,
       ROUND(COUNT(DISTINCT o.order_id)
             / COUNT(DISTINCT s.website_session_id) * 100, 2) AS conversion_rate_pct
FROM website_sessions s
LEFT JOIN orders o ON o.website_session_id = s.website_session_id;
```

A `LEFT JOIN` is essential here. An inner join would keep only sessions that ended in an order and push the rate to 100%.

**Sessions by marketing source**

```sql
SELECT COALESCE(utm_source, 'direct / organic') AS marketing_source,
       COUNT(*) AS sessions
FROM website_sessions
GROUP BY COALESCE(utm_source, 'direct / organic')
ORDER BY sessions DESC;
```

**Refunds by product**

```sql
SELECT p.product_name,
       COUNT(r.order_item_refund_id) AS refunds,
       SUM(r.refund_amount_usd)      AS refund_value
FROM order_item_refunds r
JOIN order_items oi ON oi.order_item_id = r.order_item_id
JOIN products p     ON p.product_id = oi.product_id
GROUP BY p.product_name
ORDER BY refund_value DESC;
```

**Revenue by month**

```sql
SELECT DATE_FORMAT(created_at, '%Y-%m') AS month,
       SUM(price_usd)                   AS revenue
FROM orders
GROUP BY DATE_FORMAT(created_at, '%Y-%m')
ORDER BY month;
```

## 8. Power BI Dashboard

### Relationships

All relationships are one-to-many with single-direction filtering.

| From (one side) | To (many side) | Column |
|---|---|---|
| `website_sessions` | `website_pageviews` | `website_session_id` |
| `website_sessions` | `orders` | `website_session_id` |
| `orders` | `order_items` | `order_id` |
| `products` | `order_items` | `product_id` |
| `order_items` | `order_item_refunds` | `order_item_id` |

### Helper columns

| Column | Table | Purpose |
|---|---|---|
| `Month` | `orders` | `yyyy-mm` label for monthly charts |
| `Marketing Source` | `website_sessions` | Replaces blank UTM values with `direct / organic` |
| `Year`, `Month Name`, `Month Num` | `website_sessions` | Slicers and correct month ordering |
| `Visitor Type` | `website_sessions` | New vs repeat visitor |
| `Refund Month` | `order_item_refunds` | Refund trend over time |

### DAX measures

```dax
Total Orders        = DISTINCTCOUNT(orders[order_id])
Total Revenue       = SUM(order_items[price_usd])
Total COGS          = SUM(order_items[cogs_usd])
Gross Profit        = [Total Revenue] - [Total COGS]
Gross Margin %      = DIVIDE([Gross Profit], [Total Revenue])
Units Sold          = COUNTROWS(order_items)
Average Order Value = DIVIDE([Total Revenue], [Total Orders])
Total Sessions      = COUNTROWS(website_sessions)
Conversion Rate     = DIVIDE([Total Orders], [Total Sessions])
Refund Count        = DISTINCTCOUNT(order_item_refunds[order_item_refund_id])
Refund Value        = SUM(order_item_refunds[refund_amount_usd])
Net Revenue         = [Total Revenue] - [Refund Value]
Refund Rate (Items) = DIVIDE([Refund Count], [Units Sold])
Refund Rate (Value) = DIVIDE([Refund Value], [Total Revenue])
Product Rank        = RANKX(ALL(products[product_name]), [Total Revenue], , DESC, DENSE)
```

### Dashboard pages

**Page 1: Product Performance**

- KPI cards: Total Revenue, Total Orders, Total COGS, Gross Profit
- Total Revenue by Products (bar chart)
- Conversion Rate by Marketing Channel (column chart)
- Products with the Highest Units Sold (column chart)
- Total Revenue by Month (line chart)
- Slicers: Products, Year, Month, Marketing Source

![Product Performance dashboard](images/product_performance.png)

**Page 2: Refunds and Session Analysis**

- KPI cards: Total Sessions, Refund Value, Average Order Value, Conversion Rate
- Refund Value by Product Name (bar chart)
- Total Sessions by Device Type (pie chart)
- Total Sessions by Marketing Channel (column chart)
- Refund Value Over Time (line chart)
- Slicers: Device Type, Year, Month, Marketing Source

![Refunds and Session Analysis dashboard](images/refunds_and_sessions.png)

### Design

White background with a teal palette: `#2A9D8F` for charts, `#264653` for titles and card values, `#4B5563` for axis labels, and a lighter-to-darker teal gradient for ranked bars. Navigation buttons switch between the two pages.

## 9. Key Results

| Metric | Value |
|---|---|
| Total revenue | $1.94M |
| Total orders | 32,313 |
| Total COGS | $722.37K |
| Gross profit | $1.22M |
| Gross margin | about 63% |
| Total sessions | 473K |
| Conversion rate | 6.83% |
| Average order value | $59.99 |
| Refund value | $85.34K (about 4.4% of revenue) |

**Revenue by product**

| Product | Revenue | Units sold |
|---|---|---|
| The Original Mr. Fuzzy | $1.21M | 24,226 |
| The Forever Love Bear | $0.35M | 5,796 |
| The Birthday Sugar Panda | $0.23M | 4,985 |
| The Hudson River Mini bear | $0.15M | 5,018 |

**Sessions and conversion by channel**

| Channel | Sessions | Conversion rate |
|---|---|---|
| gsearch | 316K | 6.75% |
| bsearch | 63K | 7.19% |
| socialbook | 11K | 3.21% |

**Sessions by device:** desktop 327K (69.16%), mobile 146K (30.84%).

## 10. Findings

*Scope:* The dataset runs from March 2012 to March 2015, so 2012 (about 10 months) and 2015 (3 months) are partial years. Comparing them with full years would be unfair, so the analysis focuses on the two full years, 2013 and 2014.

1. **2013:** The business was on an upward trend, except in March, when revenue declined from $27K to $20K. It went back up to $29K in April and kept climbing until December, when it reached $58K. The Original Mr. Fuzzy was the product with the most units sold and the most revenue.
2. **2014:** The addition of a new product helped increase revenue. The Original Mr. Fuzzy remained the top product, and the business was on an upward trend throughout the year. There was a significant spike in May that was not repeated in June, July or August, but from September the upward trend continued until December.
3. **Refunds:** In every year, refund value spikes in September (about 2x the monthly average), and nothing in the data explains why. December is the second-highest month, which is understandable given the high number of units sold that month.
4. **Marketing channels:** Google search (gsearch) remains the channel with the most sessions and sales throughout the years.
5. **Devices:** Desktop is the device most customers use for purchase, and it also brings in the most revenue.
6. **Conversion:** bsearch converts slightly better than gsearch (7.19% against 6.75%). The gap is small, but gsearch carries most of the traffic, so its user journey needs to be looked into.
7. **Socialbook:** It is the weakest channel, with only 11K sessions and a 3.21% conversion rate, less than half the rate of either search channel.

## 11. Recommendations

1. **Get the reasons behind refunds.** Capture more information in the `order_item_refunds` table, such as the reason for each return, so the business can trace why goods come back and reduce refund value. In the meantime, break September's refunds down by product and year. The Original Mr. Fuzzy accounts for about 72% of refund value, so it is the first place to look.
2. **Find what works for socialbook.** Test new creatives, audiences and landing pages. A winning socialbook campaign would increase revenue.
3. **Fix the gsearch journey and learn from bsearch.** Compare the two channels campaign by campaign to see where gsearch visitors drop off. If gsearch converted at 7.19% instead of 6.75%, it would have produced roughly 1,400 more orders, about $83K at the current average order value. bsearch has only 63K sessions, so a gradual budget increase there can also be tested while tracking cost per order.
4. **Check how mobile is performing.** Mobile is about 31% of sessions. Add conversion rate by device to the dashboard, and if mobile lags, improve the mobile experience.
5. **Learn from the swings.** Find out what caused the May 2014 spike so it can be repeated before the slow summer months, and what caused the March 2013 dip so it is not repeated.
6. **Prepare early for the end-of-year peak.** Revenue climbs from September to December, so stock and ad budgets should be ready from September, especially stock of The Original Mr. Fuzzy.
7. **Keep adding new products.** The new product helped revenue grow in 2014, while Mr. Fuzzy still carries about 62% of revenue. Testing more products would reduce the risk of depending on one.

## 12. Limitations

- Figures quoted from the dashboards are rounded, so derived percentages (gross margin, refund rates) are approximate.
- The monthly charts on the dashboard combine all years into calendar months, which mixes seasonality with business growth. Use the Year slicer to view a single year.
- The marketing channel charts show only the three paid channels. Direct and organic traffic is not shown.
- The dataset has no advertising spend, so cost per order and return on ad spend cannot be calculated.
- The dataset has no refund reasons, so the causes of refunds cannot be confirmed from the data.
- Conversion rate by device and gross margin by product are not currently shown on the dashboard.

## 13. How to Reproduce This Project

### Prerequisites

- MySQL Server 8.0 or later and MySQL Workbench
- Power BI Desktop
- The six source CSV files

### Steps

1. **Create the database and tables.** Run `sql/01_create_database_and_tables.sql`. It begins with:

   ```sql
   CREATE DATABASE maven_fuzzy_factory;
   USE maven_fuzzy_factory;
   ```

2. **Load the data.** Copy the CSV files to the folder MySQL allows for imports (check it with `SHOW VARIABLES LIKE 'secure_file_priv';`) and run `sql/02_load_data.sql`. A typical load looks like this:

   ```sql
   LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/website_sessions.csv'
   INTO TABLE website_sessions
   FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
   LINES TERMINATED BY '\r\n'
   IGNORE 1 ROWS;
   ```

   Use forward slashes in the path. If the dates in your files are not in `YYYY-MM-DD hh:mm:ss` format, convert them first or use `STR_TO_DATE`.

3. **Check the load.** Compare each table's row count with its CSV, then confirm that blank UTM values were loaded as real `NULL` values.
4. **Run the analysis.** Run `sql/03_business_questions.sql` and review the ten results.
5. **Open the dashboard.** Open `powerbi/maven_fuzzy_factory.pbix`, then go to **Home → Transform data → Data source settings** and point it at your own MySQL server and database before refreshing.

### Troubleshooting

| Problem | Fix |
|---|---|
| Error 1292, incorrect datetime value | The CSV dates are not in MySQL format. Convert them first or load with `STR_TO_DATE`. |
| Error 1411, incorrect datetime value for `str_to_date` | The dates are already in the correct format. Remove the `STR_TO_DATE` conversion. |
| Request rejected due to access restrictions | Move the CSV into the `secure_file_priv` folder and use `LOAD DATA INFILE` without `LOCAL`. |
| Import wizard takes hours | Use `LOAD DATA INFILE` instead for the large tables. |
| Power BI ambiguous paths error | Delete the direct relationship between `order_item_refunds` and `orders`. |

## 14. Deliverables

| # | Deliverable | Location |
|---|---|---|
| 1 | Documented transformation steps | [Section 6](#6-data-preparation-and-cleaning) |
| 2 | SQL scripts | `sql/` |
| 3 | Power BI dashboard | `powerbi/maven_fuzzy_factory.pbix` |
| 4 | Analytical report (PDF) | `report/Analytical_Report.pdf` |
| 5 | Business insights and recommendations | Sections [10](#10-findings) and [11](#11-recommendations) |
| 6 | Dashboard demo video (5 to 10 minutes) | `video/dashboard_demo_link.txt` |

## 15. Author

**[Your Name]**
[LinkedIn] | [Email] | [Portfolio]

---

*Dataset: Maven Fuzzy Factory, provided by Maven Analytics. The business and its data are fictional and used for learning purposes.*
