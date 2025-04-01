credit_risk_db=# -- 1. Drop existing table and its dependent objects if they exist
credit_risk_db=# DROP TABLE IF EXISTS credit_default CASCADE;
NOTICE:  drop cascades to 2 other objects
DETAIL:  drop cascades to view credit_debt_ratio
drop cascades to view credit_risk_bucket
DROP TABLE
credit_risk_db=#
credit_risk_db=# -- Create the table
credit_risk_db=# CREATE TABLE credit_default (
credit_risk_db(#     id SERIAL PRIMARY KEY,
credit_risk_db(#     limit_balance NUMERIC,
credit_risk_db(#     sex INTEGER,
credit_risk_db(#     education INTEGER,
credit_risk_db(#     marriage INTEGER,
credit_risk_db(#     age INTEGER,
credit_risk_db(#     pay_0 INTEGER,
credit_risk_db(#     pay_2 INTEGER,
credit_risk_db(#     pay_3 INTEGER,
credit_risk_db(#     pay_4 INTEGER,
credit_risk_db(#     pay_5 INTEGER,
credit_risk_db(#     pay_6 INTEGER,
credit_risk_db(#     bill_amt1 NUMERIC,
credit_risk_db(#     bill_amt2 NUMERIC,
credit_risk_db(#     bill_amt3 NUMERIC,
credit_risk_db(#     bill_amt4 NUMERIC,
credit_risk_db(#     bill_amt5 NUMERIC,
credit_risk_db(#     bill_amt6 NUMERIC,
credit_risk_db(#     pay_amt1 NUMERIC,
credit_risk_db(#     pay_amt2 NUMERIC,
credit_risk_db(#     pay_amt3 NUMERIC,
credit_risk_db(#     pay_amt4 NUMERIC,
credit_risk_db(#     pay_amt5 NUMERIC,
credit_risk_db(#     pay_amt6 NUMERIC,
credit_risk_db(#     default_payment_next_month INTEGER
credit_risk_db(# );
CREATE TABLE
credit_risk_db=#
credit_risk_db=# -- 2. Import data from CSV using \copy (client-side command in psql)
credit_risk_db=# \copy credit_default(limit_balance, sex, education, marriage, age, pay_0, pay_2, pay_3, pay_4, pay_5, pay_6, bill_amt1, bill_amt2, bill_amt3, bill_amt4, bill_amt5, bill_amt6, pay_amt1, pay_amt2, pay_amt3, pay_amt4, pay_amt5, pay_amt6, default_payment_next_month) FROM 'C:/Users/brady/Downloads/default of credit card clients.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
COPY 30000
credit_risk_db=#
credit_risk_db=# -- 3. Exploratory Analysis Queries
credit_risk_db=#
credit_risk_db=# -- Total number of clients and default rate
credit_risk_db=# SELECT
credit_risk_db-#     COUNT(*) AS total_clients,
credit_risk_db-#     SUM(default_payment_next_month) AS total_defaults,
credit_risk_db-#     ROUND(100.0 * SUM(default_payment_next_month) / COUNT(*), 2) AS default_rate_percent
credit_risk_db-# FROM credit_default;
 total_clients | total_defaults | default_rate_percent
---------------+----------------+----------------------
         30000 |           6636 |                22.12
(1 row)


credit_risk_db=#
credit_risk_db=# -- Default rate by gender
credit_risk_db=# SELECT
credit_risk_db-#     sex,
credit_risk_db-#     COUNT(*) AS total,
credit_risk_db-#     SUM(default_payment_next_month) AS defaults,
credit_risk_db-#     ROUND(100.0 * SUM(default_payment_next_month) / COUNT(*), 2) AS default_rate
credit_risk_db-# FROM credit_default
credit_risk_db-# GROUP BY sex;
 sex | total | defaults | default_rate
-----+-------+----------+--------------
   2 | 18112 |     3763 |        20.78
   1 | 11888 |     2873 |        24.17
(2 rows)


credit_risk_db=#
credit_risk_db=# -- Default rate by education
credit_risk_db=# SELECT
credit_risk_db-#     education,
credit_risk_db-#     COUNT(*) AS total,
credit_risk_db-#     SUM(default_payment_next_month) AS defaults,
credit_risk_db-#     ROUND(100.0 * SUM(default_payment_next_month) / COUNT(*), 2) AS default_rate
credit_risk_db-# FROM credit_default
credit_risk_db-# GROUP BY education
credit_risk_db-# ORDER BY default_rate DESC;
 education | total | defaults | default_rate
-----------+-------+----------+--------------
         3 |  4917 |     1237 |        25.16
         2 | 14030 |     3330 |        23.73
         1 | 10585 |     2036 |        19.23
         6 |    51 |        8 |        15.69
         5 |   280 |       18 |         6.43
         4 |   123 |        7 |         5.69
         0 |    14 |        0 |         0.00
(7 rows)


credit_risk_db=#
credit_risk_db=# -- 4. Feature Engineering: Create a view for debt ratio calculation
credit_risk_db=# CREATE OR REPLACE VIEW credit_debt_ratio AS
credit_risk_db-# SELECT
credit_risk_db-#     id,
credit_risk_db-#     age,
credit_risk_db-#     limit_balance,
credit_risk_db-#     (bill_amt1 + bill_amt2 + bill_amt3 + bill_amt4 + bill_amt5 + bill_amt6) AS total_bill,
credit_risk_db-#     (pay_amt1 + pay_amt2 + pay_amt3 + pay_amt4 + pay_amt5 + pay_amt6) AS total_payment,
credit_risk_db-#     CASE
credit_risk_db-#         WHEN limit_balance = 0 THEN NULL
credit_risk_db-#         ELSE ROUND(((bill_amt1 + bill_amt2 + bill_amt3 + bill_amt4 + bill_amt5 + bill_amt6) / limit_balance)::NUMERIC, 2)
credit_risk_db-#     END AS debt_to_limit_ratio,
credit_risk_db-#     default_payment_next_month
credit_risk_db-# FROM credit_default;
CREATE VIEW
credit_risk_db=#
credit_risk_db=# -- 5. Create a view for simple risk bucketing
credit_risk_db=# CREATE OR REPLACE VIEW credit_risk_bucket AS
credit_risk_db-# SELECT *,
credit_risk_db-#     CASE
credit_risk_db-#         WHEN default_payment_next_month = 1 THEN 'High Risk'
credit_risk_db-#         WHEN debt_to_limit_ratio > 0.9 THEN 'Medium Risk'
credit_risk_db-#         ELSE 'Low Risk'
credit_risk_db-#     END AS risk_category
credit_risk_db-# FROM credit_debt_ratio;
CREATE VIEW
credit_risk_db=#
credit_risk_db=# -- Example: View risk distribution across categories
credit_risk_db=# SELECT risk_category, COUNT(*) AS clients
credit_risk_db-# FROM credit_risk_bucket
credit_risk_db-# GROUP BY risk_category
credit_risk_db-# ORDER BY clients DESC;
 risk_category | clients
---------------+---------
 Medium Risk   |   13252
 Low Risk      |   10112
 High Risk     |    6636
(3 rows)