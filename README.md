# Hospitality Analytics Data Warehouse

## Project Overview

The **Hospitality Analytics Data Warehouse** is an end-to-end data analytics project designed to analyze hotel operational performance, revenue generation, guest satisfaction, and workforce stability across multiple hotels and cities.

The project simulates hospitality business data covering a five-year period from **January 2021 to December 2025**. It implements a data pipeline involving synthetic data generation, relational database design, data validation, analytical transformations, KPI calculation, and dashboard development.

The objective is to transform raw operational data into structured analytical datasets that support business decision-making and performance monitoring.

---

## Business Objectives

The project aims to help hospitality management evaluate business performance by answering questions such as:

- How efficiently are hotel rooms being utilized?
- How does room revenue change across different seasons?
- Which hotels generate the highest revenue per available room?
- How does guest satisfaction vary over time?
- What are the seasonal trends in occupancy and pricing?
- How stable is the workforce across hotel locations?
- Which hotels demonstrate stronger overall operational performance?

---

## Project Scope

| Component | Description |
|---|---|
| Industry | Hospitality |
| Data Period | January 2021 – December 2025 |
| Number of Hotels | 10 |
| Cities | Bengaluru, Chennai, Mumbai, Delhi, Goa |
| Database | PostgreSQL |
| Programming Language | Python |
| Data Analysis | Pandas, NumPy |
| Data Generation | Faker |
| Visualization | Google Sheets |
| SQL | Data modeling, validation, aggregation, analytical queries |

---

## Architecture

The project follows a structured data pipeline:

```text
Synthetic Data Generation
        |
        v
Raw CSV Datasets
        |
        v
Data Quality Validation
        |
        v
PostgreSQL Data Warehouse
        |
        v
Relational Data Layer
        |
        v
Gold Analytical Layer
        |
        v
Unified Dashboard View
        |
        v
Business Analysis & Visualization
```

---

## Dataset Overview

The project generates synthetic hospitality datasets representing hotel operations.

### Dataset Summary

| Dataset | Records | Description |
|---|---:|---|
| Hotels | 10 | Hotel master information |
| Rooms | 1,000 | Hotel room inventory |
| Guests | 20,000 | Guest master data |
| Employees | 750 | Employee master information |
| Reservations | 443,203 | Reservation transactions |
| Stays | 385,394 | Completed hotel stays |
| Room Nights | 1,826,000 | Daily room availability and occupancy |
| Guest Feedback | 154,157 | Guest satisfaction records |
| Employee History | 768 | Employment history and transfers |

**Total Records: Approximately 2.83 million**

---

## Data Generation

Synthetic data was generated using Python libraries including:

- Pandas
- NumPy
- Faker
- Random

The generated datasets incorporate business-oriented assumptions and operational patterns.

### Seasonal Demand

Occupancy demand varies by month to simulate seasonal hotel performance.

| Month | Occupancy Target |
|---|---:|
| January | 55% |
| February | 58% |
| March | 62% |
| April | 68% |
| May | 82% |
| June | 78% |
| July | 48% |
| August | 50% |
| September | 58% |
| October | 72% |
| November | 82% |
| December | 90% |

### Seasonal Pricing

Room prices also vary depending on seasonal demand.

| Month | Price Multiplier |
|---|---:|
| January | 1.00 |
| February | 1.00 |
| March | 1.05 |
| April | 1.10 |
| May | 1.25 |
| June | 1.20 |
| July | 0.85 |
| August | 0.85 |
| September | 0.95 |
| October | 1.10 |
| November | 1.20 |
| December | 1.35 |

These assumptions allow the project to demonstrate seasonality analysis and revenue management concepts.

---

## Database Schema

The PostgreSQL database contains nine primary tables.

### 1. `hotels`

Stores hotel master information.

Key attributes:

- `hotel_id`
- `hotel_name`
- `city`
- `state`
- `hotel_category`

### 2. `rooms`

Stores room inventory and room classifications.

Key attributes:

- `room_id`
- `hotel_id`
- `room_type`
- `room_status`
- `base_price`

### 3. `guests`

Stores guest master information.

Key attributes:

- `guest_id`
- Guest demographics
- Guest information

### 4. `employees`

Stores employee master information.

Key attributes:

- `employee_id`
- `hotel_id`
- `department`
- `designation`
- `salary`

### 5. `reservations`

Stores reservation transactions.

Key attributes:

- `reservation_id`
- `guest_id`
- `room_id`
- `booking_date`
- `check_in_date`
- `check_out_date`
- `reservation_status`
- `quoted_nightly_rate`

### 6. `stays`

Stores completed hotel stays.

Key attributes:

- `stay_id`
- `reservation_id`
- `actual_check_in`
- `actual_checkout`

### 7. `room_nights`

Stores daily room-level availability, occupancy, and revenue information.

Key attributes:

- `room_id`
- `hotel_id`
- `stay_id`
- `date`
- `is_available`
- `is_occupied`
- `room_revenue`

This table is the primary source for occupancy and room revenue analysis.

### 8. `guest_feedback`

Stores guest satisfaction information.

Key attributes:

- `feedback_id`
- `stay_id`
- `rating`
- `feedback_date`

### 9. `employee_history`

Stores employee employment periods and historical hotel assignments.

Key attributes:

- `employee_id`
- `hotel_id`
- `start_date`
- `end_date`
- `employment_status`

This table supports workforce analysis and employee turnover calculations.

---

## Data Quality & Validation

Data quality checks were implemented to ensure consistency and reliability throughout the pipeline.

### Validation Checks

- Record count validation between generated CSV files and PostgreSQL tables
- Primary key uniqueness
- Foreign key integrity
- Reservation and stay relationship validation
- Room-night availability and occupancy validation
- Revenue consistency checks
- Guest feedback rating validation
- Employee history validation
- Employee transfer identification
- KPI calculation validation

### Referential Integrity

The following relationships were validated:

| Relationship | Validation |
|---|---|
| Rooms → Hotels | Valid |
| Reservations → Guests | Valid |
| Reservations → Rooms | Valid |
| Stays → Reservations | Valid |
| Guest Feedback → Stays | Valid |
| Employee History → Employees | Valid |

All foreign key validation checks returned zero invalid records.

---

## Gold Analytical Layer

The Gold layer contains aggregated datasets designed for business reporting and analytical consumption.

### 1. `gold_monthly_hotel_performance`

**Grain:** One record per hotel per month.

Metrics:

- Available Room Nights
- Occupied Room Nights
- Room Revenue
- Occupancy Rate
- Average Daily Rate (ADR)
- Revenue per Available Room (RevPAR)

### 2. `gold_monthly_guest_satisfaction`

**Grain:** One record per hotel per month.

Metrics:

- Total Feedback
- Average Guest Rating
- Five-Star Feedback
- Low-Rating Feedback
- Positive Feedback Percentage

### 3. `gold_monthly_employee_turnover`

**Grain:** One record per hotel per month.

Metrics:

- Opening Headcount
- Closing Headcount
- Average Headcount
- Employee Exits
- Internal Transfers
- Employee Turnover Rate

Internal employee transfers are tracked separately and excluded from organizational exits.

### 4. `vw_hotel_monthly_dashboard`

A unified analytical view combining the three Gold tables.

The view provides a consolidated monthly performance dataset containing:

- Hotel information
- Occupancy metrics
- Revenue metrics
- Guest satisfaction metrics
- Workforce metrics

The view contains **600 records**, representing:

**10 hotels × 60 months**

---

## Key Performance Indicators

### Occupancy Rate

Measures the percentage of available room nights that were occupied.

```text
Occupancy Rate =
Occupied Room Nights / Available Room Nights × 100
```

### Average Daily Rate (ADR)

Measures the average revenue earned per occupied room night.

```text
ADR =
Room Revenue / Occupied Room Nights
```

### Revenue per Available Room (RevPAR)

Measures room revenue generated per available room night.

```text
RevPAR =
Room Revenue / Available Room Nights
```

### Guest Satisfaction Score

Measures the average guest rating across submitted feedback.

```text
Guest Satisfaction =
Weighted Average of Guest Ratings
```

Ratings are measured on a scale of 1 to 5.

### Employee Turnover Rate

Measures organizational employee exits relative to the average workforce.

```text
Employee Turnover Rate =
Employee Exits / Average Headcount × 100
```

Internal transfers are excluded from organizational exits.

---

## Business Analysis

### Seasonal Analysis

Analyzed monthly occupancy, ADR, and RevPAR across the five-year reporting period.

Key observations from the synthetic dataset:

- December demonstrated the strongest occupancy and revenue performance.
- May and November also showed strong demand.
- July and August demonstrated comparatively lower occupancy.
- Seasonal patterns were more prominent than year-over-year changes.

### Year-over-Year Analysis

Compared annual hotel performance from 2021 to 2025.

Metrics analyzed:

- Occupancy Rate
- ADR
- RevPAR

The generated dataset demonstrated relatively stable annual performance, with seasonal patterns contributing more variation than year-over-year changes.

### City-Level Analysis

Analyzed seasonal performance across:

- Bengaluru
- Chennai
- Mumbai
- Delhi
- Goa

### Hotel Performance Ranking

Hotels were ranked based on average RevPAR to evaluate differences in revenue-generating performance across properties.

### Guest Satisfaction Analysis

Analyzed:

- Average guest rating
- Five-star feedback
- Low-rating feedback
- Positive feedback percentage

### Workforce Analysis

Analyzed:

- Employee exits
- Internal transfers
- Headcount
- Employee turnover trends

---

## Dashboard

The project includes a Google Sheets dashboard designed to present key business metrics and analytical findings.

### KPI Cards

- Occupancy Rate
- Average Daily Rate (ADR)
- Revenue per Available Room (RevPAR)
- Guest Satisfaction
- Employee Turnover Rate

### Visualizations

1. Monthly Occupancy Rate Trend
2. Monthly ADR vs RevPAR Trend
3. Monthly Guest Satisfaction Trend
4. Hotel Performance Ranking by RevPAR
5. Monthly Employee Turnover Trend

### Dashboard Components

- KPI cards
- Summary tables
- Trend analysis
- Hotel performance comparison
- Business insights

---

## Project Structure

```text
hospitality-analytics/
│
├── dashboards/
│
├── data/
│   ├── raw/
│   └── processed/
│
├── notebooks/
│   └── data_generation.ipynb
│
├── scripts/
│   ├── generate_data.py
│   ├── generate_room_nights.py
│   ├── generate_guest_feedback.py
│   ├── generate_employee_history.py
│   └── load_data.py
│
├── sql/
│   ├── 01_create_database.sql
│   ├── 02_create_tables.sql
│   ├── 03_data_validation.sql
│   └── 04_kpi_aggregations.sql
│
├── .gitignore
├── README.md
└── requirements.txt
```

---

## Technologies Used

| Technology | Purpose |
|---|---|
| Python | Data generation and processing |
| Pandas | Data manipulation |
| NumPy | Numerical operations |
| Faker | Synthetic data generation |
| PostgreSQL | Relational data warehouse |
| SQL | Data modeling, validation, and analytics |
| SQLAlchemy | Database connectivity |
| Psycopg2 | PostgreSQL connection |
| Jupyter Notebook | Data generation and exploration |
| Google Sheets | Dashboard and visualization |

---

## Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/punithr12/Hospitality-Analytics.git
```

```bash
cd Hospitality-Analytics
```

### 2. Create a Virtual Environment

```bash
python3 -m venv .venv
```

### 3. Activate the Virtual Environment

Linux / macOS:

```bash
source .venv/bin/activate
```

### 4. Install Dependencies

```bash
pip install -r requirements.txt
```

### 5. Configure PostgreSQL

Ensure PostgreSQL is installed and running.

Create the database using the SQL script:

```bash
psql -U postgres -f sql/01_create_database.sql
```

### 6. Configure Environment Variables

Set your database credentials.

```bash
export DB_USER=postgres
export DB_PASSWORD=your_password
```

Environment variables should be configured locally and should not be committed to GitHub.

---

## Execution Workflow

### Step 1: Generate Base Data

```bash
python scripts/generate_data.py
```

### Step 2: Generate Room-Night Data

```bash
python scripts/generate_room_nights.py
```

### Step 3: Generate Guest Feedback

```bash
python scripts/generate_guest_feedback.py
```

### Step 4: Generate Employee History

```bash
python scripts/generate_employee_history.py
```

### Step 5: Create Database Tables

```bash
psql -U postgres -d hotel_analytics -f sql/02_create_tables.sql
```

### Step 6: Load Data into PostgreSQL

```bash
python scripts/load_data.py
```

### Step 7: Run Data Validation

```bash
psql -U postgres -d hotel_analytics -f sql/03_data_validation.sql
```

### Step 8: Create Gold Analytical Tables

```bash
psql -U postgres -d hotel_analytics -f sql/04_kpi_aggregations.sql
```

---

## Key Project Outcomes

- Generated approximately **2.83 million synthetic records**.
- Designed a relational hospitality data warehouse with nine tables.
- Implemented data generation pipelines using Python.
- Loaded datasets into PostgreSQL using SQLAlchemy.
- Implemented data quality and referential integrity checks.
- Developed three Gold analytical tables.
- Created a unified monthly hotel performance view.
- Calculated five core hospitality KPIs.
- Performed seasonal, year-over-year, city-level, hotel-level, guest satisfaction, and workforce analysis.
- Developed a dashboard using Google Sheets.

---

## Limitations

- The datasets are synthetic and do not represent actual hotel business transactions.
- Seasonal demand and pricing patterns were predefined during data generation.
- Business insights demonstrate analytical techniques and should not be interpreted as actual hospitality industry findings.
- The project focuses primarily on room revenue and operational performance rather than complete hotel financial accounting.

---

## Future Enhancements

Potential improvements include:

- Automated ETL scheduling
- Incremental data loading
- Advanced anomaly detection
- Predictive occupancy forecasting
- Revenue optimization models
- Guest churn analysis
- Hotel demand forecasting
- Automated dashboard refresh
- Cloud data warehouse deployment
- BI integration with Power BI or Tableau

---

## Author

**Punith R**

Data Analytics | SQL | Python | PostgreSQL | Data Warehousing | Business Intelligence

---

## Project Purpose

This project demonstrates an end-to-end data analytics workflow, from synthetic data generation and relational data modeling to data quality validation, analytical SQL transformations, KPI development, business analysis, and dashboard visualization.

It showcases practical skills in **Python, SQL, PostgreSQL, data engineering fundamentals, analytical thinking, and business intelligence**.
