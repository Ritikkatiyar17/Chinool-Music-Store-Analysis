USE chinook;
select * from album;
                   -- OBECTIVE QUESTIONS 
-- (Q1)Objective 1: Does any table have missing values or duplicates? If yes how would you handle it ?

-- This query checks missing values (NULL) in different columns across multiple tables.
SELECT 'customer' AS table_name, 'company' AS column_name, COUNT(*) AS null_count
FROM customer
WHERE company IS NULL
UNION ALL
SELECT 'customer', 'state', COUNT(*)
FROM customer
WHERE state IS NULL
UNION ALL
SELECT 'customer', 'postal_code', COUNT(*)
FROM customer
WHERE postal_code IS NULL
UNION ALL
SELECT 'customer', 'phone', COUNT(*)
FROM customer
WHERE phone IS NULL
UNION ALL
SELECT 'customer', 'fax', COUNT(*)
FROM customer
WHERE fax IS NULL
UNION ALL
SELECT 'employee', 'reports_to', COUNT(*)
FROM employee
WHERE reports_to IS NULL
UNION ALL
SELECT 'track', 'composer', COUNT(*)
FROM track
WHERE composer IS NULL;
select * from employee;

-- Update meaningful categorical missing values
SET SQL_SAFE_UPDATES = 0;

UPDATE customer SET company='Unknown' WHERE company is NULL;
UPDATE customer SET state='Unknown' WHERE state IS NULL;
UPDATE customer SET postal_code='Unknown' WHERE postal_code IS NULL;
UPDATE customer SET phone='Unknown' WHERE phone IS NULL;
UPDATE customer SET fax='Unknown' WHERE fax IS NULL;
UPDATE track SET composer='Unknown' WHERE composer is NULL;

SET SQL_SAFE_UPDATES = 1;

-- checking Duplicates
SELECT title, artist_id, COUNT(*) AS count_of_duplicates
FROM album
GROUP BY title, artist_id
HAVING COUNT(*)>1;

SELECT email, COUNT(*) AS count_of_duplicates
FROM employee
GROUP BY phone, email
HAVING COUNT(*)>1;

SELECT name, COUNT(*) AS count_of_duplicates
FROM genre
GROUP BY name
HAVING COUNT(*)>1;

SELECT invoice_id, track_id, unit_price, quantity, COUNT(*) AS count_of_duplicates
FROM invoice_line
GROUP BY invoice_id, track_id, unit_price, quantity
HAVING COUNT(*) > 1;

SELECT name, COUNT(*) AS duplicates
FROM media_type
GROUP BY name
HAVING COUNT(*) > 1;

SELECT name, COUNT(*) AS count_of_duplicates
FROM playlist
GROUP BY name
HAVING COUNT(*) > 1;

SELECT name, album_id,
media_type_id, genre_id,
composer, milliseconds, bytes,
unit_price, COUNT(*) AS count_of_duplicates
FROM track
GROUP BY name, album_id,
media_type_id, genre_id,
composer, milliseconds,
bytes,unit_price
HAVING COUNT(*) > 1;

-- Removing duplicates

WITH remove_duplicates AS (

    SELECT
        playlist_id,

        ROW_NUMBER() OVER (
            PARTITION BY name
            ORDER BY playlist_id
        ) AS cnt_duplicates

    FROM playlist
)

DELETE FROM playlist
WHERE playlist_id IN (

    SELECT playlist_id
    FROM remove_duplicates
    WHERE cnt_duplicates > 1
);


WITH remove_duplicates AS (

    SELECT
        invoice_line_id,

        ROW_NUMBER() OVER (
            PARTITION BY invoice_id,
                         track_id,
                         unit_price,
                         quantity
            ORDER BY invoice_line_id
        ) AS cnt_duplicates

    FROM invoice_line
)

DELETE FROM invoice_line
WHERE invoice_line_id IN (

    SELECT invoice_line_id
    FROM remove_duplicates
    WHERE cnt_duplicates > 1
);

-- Rechecking duplicates to validate the cleanup.
SELECT name,COUNT(*) AS duplicate_count
FROM playlist
GROUP BY name
HAVING COUNT(*) > 1;

SELECT invoice_id,track_id,unit_price,quantity,
COUNT(*) AS duplicate_count
FROM invoice_line
GROUP BY invoice_id,track_id,unit_price,quantity
HAVING COUNT(*) > 1;


-- (Q2)Find the top-selling tracks and top artist in the USA and identify their most famous genres.

-- Top-selling tracks in the USA.
SELECT
    t.name,
    COUNT(*) as track_count
FROM invoice_line il
JOIN invoice i on il.invoice_id=i.invoice_id
JOIN customer c on c.customer_id=i.customer_id
JOIN track t on t.track_id=il.track_id
WHERE c.country='USA'
GROUP BY t.name
ORDER BY track_count DESC
LIMIT 10;

-- Top Artist in the USA.
SELECT 
    ar.name AS artist_name,
    COUNT(*) AS total_sales
FROM invoice_line il
JOIN invoice i ON il.invoice_id = i.invoice_id
JOIN customer c ON c.customer_id = i.customer_id
JOIN track t ON t.track_id = il.track_id
JOIN album al ON al.album_id = t.album_id
JOIN artist ar ON ar.artist_id = al.artist_id
WHERE c.country = 'USA'
GROUP BY ar.name
ORDER BY total_sales DESC
LIMIT 10;

-- Most famous genre in the usa based on total sales.
SELECT 
g.name AS genre,
COUNT(*) AS total_sales
FROM invoice_line il
JOIN invoice i ON il.invoice_id = i.invoice_id
JOIN customer c ON c.customer_id = i.customer_id
JOIN track t ON t.track_id = il.track_id
JOIN genre g ON g.genre_id = t.genre_id
WHERE c.country = 'USA'
GROUP BY g.name
ORDER BY total_sales DESC
Limit 10;


-- (Q3)What is the customer demographic breakdown (age, gender, location) of Chinook's customer base?

-- total customers per city
SELECT
    city,
    COUNT(*) AS total_customers
FROM customer
GROUP BY city
ORDER BY total_customers DESC;

-- total customers per country
SELECT
    country,
    COUNT(*) AS total_customers
FROM customer
GROUP BY country
ORDER BY total_customers DESC;

-- total customers per city per country
SELECT
    country,
    city,
    COUNT(*) AS total_customers
FROM customer
GROUP BY country, city
ORDER BY total_customers DESC;

-- (Q4) Calculate the total revenue and number of invoices for each country, state, and city.

--      countrywise total revenue and no of invoices
SELECT
c.country,
SUM(il.unit_price * il.quantity) AS total_revenue,
COUNT(DISTINCT i.invoice_id) AS total_invoices
FROM invoice i
JOIN invoice_line il
ON il.invoice_id = i.invoice_id
JOIN customer c
ON c.customer_id = i.customer_id
GROUP BY c.country
ORDER BY total_revenue DESC,total_invoices DESC;

-- citywise total revenue and total invoices.
SELECT
c.city,
SUM(il.unit_price * il.quantity) AS total_revenue,
COUNT(DISTINCT i.invoice_id) AS total_invoices
FROM invoice i
JOIN invoice_line il
ON il.invoice_id = i.invoice_id
JOIN customer c
ON c.customer_id = i.customer_id
GROUP BY c.city
ORDER BY total_revenue DESC,total_invoices DESC;

-- statewise total revenue and total invoices.
SELECT
c.state,
SUM(il.unit_price * il.quantity) AS total_revenue,
COUNT(DISTINCT i.invoice_id) AS total_invoices
FROM invoice i
JOIN invoice_line il
ON il.invoice_id = i.invoice_id
JOIN customer c
ON c.customer_id = i.customer_id
GROUP BY c.state
ORDER BY total_revenue DESC,total_invoices DESC;

-- (Q5)Find the top 5 customers by total revenue in each country.

WITH customer_revenue AS ( SELECT
c.customer_id,
CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
c.country,
SUM(il.unit_price * il.quantity) AS total_revenue
FROM invoice i
JOIN invoice_line il
ON i.invoice_id = il.invoice_id
JOIN customer c
ON i.customer_id = c.customer_id
GROUP BY c.customer_id,c.first_name,c.last_name,c.country
),
ranked_customers AS (
SELECT *,
DENSE_RANK() OVER (PARTITION BY country ORDER BY total_revenue DESC) AS rnk
FROM customer_revenue
)
SELECT *
FROM ranked_customers
WHERE rnk <= 5
ORDER BY total_revenue DESC,country;

-- (Q6)Identify the top-selling track for each customer.

WITH customer_track_sales AS (
SELECT
c.customer_id,
CONCAT(c.first_name, ' ', c.last_name) AS full_name,
t.track_id,
t.name AS track_name,
SUM(il.quantity) AS total_sales
FROM track t
JOIN invoice_line il 
ON t.track_id = il.track_id
JOIN invoice i 
ON il.invoice_id = i.invoice_id
JOIN customer c 
ON i.customer_id = c.customer_id
GROUP BY c.customer_id, full_name, t.track_id, t.name
),

ranked_tracks AS (
SELECT *,
DENSE_RANK() OVER (
    PARTITION BY customer_id 
    ORDER BY total_sales DESC, track_id
) AS rnk
FROM customer_track_sales
)

SELECT
customer_id,
full_name,
track_id,
track_name,
total_sales
FROM ranked_tracks
WHERE rnk = 1
ORDER BY total_sales DESC;

-- (Q7) Are there any patterns or trends in customer purchasing behavior
-- (e.g., frequency of purchases, preferred payment methods, average order value)?

-- total frequency(count invoices) per customer over year.
SELECT
c.customer_id,
CONCAT(c.first_name, ' ', c.last_name) AS full_name,
YEAR(i.invoice_date) AS purchase_year,
COUNT(i.invoice_id) AS purchase_count
FROM customer c
JOIN invoice i
ON c.customer_id = i.customer_id
GROUP BY
c.customer_id,
c.first_name,
c.last_name,
YEAR(i.invoice_date)
ORDER BY c.customer_id,purchase_year;

-- average order value and total invoices per customer.
SELECT
customer_id,
AVG(total) AS avg_order_value,
COUNT(invoice_id) AS total_purchase_count
FROM invoice
GROUP BY customer_id
ORDER BY customer_id, avg_order_value DESC;

-- (Q8)What is the customer churn rate?

WITH latest_date AS (
SELECT MAX(invoice_date) AS max_date
FROM invoice
),
customer_last_purchase AS (
SELECT 
customer_id,
MAX(invoice_date) AS last_purchase
FROM invoice
GROUP BY customer_id
)
SELECT 
COUNT(CASE 
          WHEN last_purchase < DATE_SUB(
                 (SELECT max_date FROM latest_date),
                 INTERVAL 3 MONTH
            ) THEN 1 END) AS churned_customers,
         
COUNT(*) AS total_customers,    
ROUND(
	  COUNT(CASE 
                WHEN last_purchase < DATE_SUB(
                     (SELECT max_date FROM latest_date),
                     INTERVAL 3 MONTH
                ) 
             THEN 1 END) * 100.0 / COUNT(*),
        2) AS churn_rate_percentage
FROM customer_last_purchase;

-- (Q9)Calculate the percentage of total sales contributed by each genre in the USA and identify the best-selling genres and artists.

-- Percentage Contribution of Sales by Genre in the USA
SELECT
g.name AS genre,
ROUND(SUM(il.unit_price * il.quantity),2) AS genre_revenue,
ROUND(
          100 * SUM(il.unit_price * il.quantity)/( 
				SELECT
				SUM(il2.unit_price * il2.quantity)
                FROM invoice_line il2
                JOIN invoice i2
                ON il2.invoice_id = i2.invoice_id
				WHERE i2.billing_country = 'USA'),
                2) AS pct_of_total_sales
FROM invoice_line il
JOIN invoice i
ON il.invoice_id = i.invoice_id
JOIN track t
ON il.track_id = t.track_id
JOIN genre g
ON t.genre_id = g.genre_id
WHERE i.billing_country = 'USA'
GROUP BY g.name
ORDER BY genre_revenue DESC;
-- Best Selling Genres in the USA.
SELECT
g.name AS genre,
ROUND(SUM(il.unit_price * il.quantity),2) AS total_revenue
FROM invoice_line il
JOIN invoice i
ON il.invoice_id = i.invoice_id
JOIN track t
ON il.track_id = t.track_id
JOIN genre g
ON t.genre_id = g.genre_id
WHERE i.billing_country = 'USA'
GROUP BY g.name
ORDER BY total_revenue DESC;

-- Best Selling Artists in the USA 
SELECT
a.name AS artist,
ROUND(SUM(il.unit_price * il.quantity),2) AS total_revenue
FROM invoice_line il
JOIN invoice i
ON il.invoice_id = i.invoice_id
JOIN track t
ON il.track_id = t.track_id
JOIN album al
ON t.album_id = al.album_id
JOIN artist a
ON al.artist_id = a.artist_id
WHERE i.billing_country = 'USA'
GROUP BY a.name
ORDER BY total_revenue DESC;

-- (Q10)Find customers who have purchased tracks from at least 3 different genres.
SELECT 
	c.customer_id, 
	CONCAT(c.first_name, ' ',  c.last_name) as full_name, 
	COUNT(DISTINCT g.genre_id) AS genre_count
FROM customer c
	JOIN invoice i ON c.customer_id = i.customer_id
	JOIN invoice_line il ON i.invoice_id = il.invoice_id
	JOIN track t ON il.track_id = t.track_id
	JOIN genre g ON t.genre_id = g.genre_id
GROUP BY c.customer_id, full_name
HAVING genre_count >= 3
ORDER BY genre_count DESC, customer_id;

-- (Q11) Rank genres based on their sales performance in the USA.
WITH genre_sales AS (
SELECT
g.name AS genre,
SUM(il.unit_price * il.quantity) AS revenue
FROM invoice_line il
JOIN invoice i
ON il.invoice_id = i.invoice_id
JOIN track t
ON il.track_id = t.track_id
JOIN genre g
ON t.genre_id = g.genre_id
WHERE i.billing_country = 'USA'
GROUP BY g.name
)
SELECT
genre,
revenue,
DENSE_RANK() OVER ( ORDER BY revenue DESC) AS rnk
FROM genre_sales
ORDER BY rnk;

-- (Q12)Identify customers who have not made a purchase in the last 3 months.

WITH customer_latest_order AS (
    SELECT
        customer_id,
        MAX(invoice_date) AS latest_purchase
    FROM invoice
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    DATEDIFF(CURDATE(), clo.latest_purchase) AS inactive_days
FROM customer c
JOIN customer_latest_order clo
    ON c.customer_id = clo.customer_id
WHERE DATEDIFF(CURDATE(), clo.latest_purchase) > 90
ORDER BY inactive_days DESC;

                             -- SUBJECTIVE QUESTIONS
							
-- (Q1)Recommend the three albums from the new record label that should be prioritised for advertising and promotion in the USA based on genre sales analysis.
WITH album_revenue AS (
SELECT 
al.title AS album,
ar.name AS artist,
g.name AS genre,
SUM(il.unit_price * il.quantity) AS revenue
FROM invoice_line il
JOIN invoice i 
ON il.invoice_id = i.invoice_id
JOIN track t 
ON il.track_id = t.track_id
JOIN album al 
ON t.album_id = al.album_id
JOIN artist ar 
ON al.artist_id = ar.artist_id
JOIN genre g 
ON t.genre_id = g.genre_id
WHERE i.billing_country = 'USA'
GROUP BY al.album_id,al.title,ar.name,g.name
)
SELECT *
FROM (
    SELECT *,
           DENSE_RANK() OVER (ORDER BY revenue DESC) AS rnk 
FROM album_revenue
) rs
WHERE rnk <= 3;

-- (Q2)Determine the top-selling genres in countries other than the USA and identify any commonalities or differences.
 WITH genre_revenue AS (
SELECT 
g.name AS genre,
c.country,
SUM(il.unit_price * il.quantity) AS revenue
FROM invoice_line il
JOIN invoice i 
ON il.invoice_id = i.invoice_id
JOIN track t 
ON il.track_id = t.track_id
JOIN genre g 
ON t.genre_id = g.genre_id
JOIN customer c 
ON c.customer_id = i.customer_id
WHERE i.billing_country <> 'USA'
GROUP BY g.name, c.country
)
SELECT * FROM
(SELECT *,
       DENSE_RANK() OVER (PARTITION BY country ORDER BY revenue DESC) AS rnk
FROM genre_revenue) rs
WHERE rnk = 1
ORDER BY revenue DESC;

-- (Q3)Customer Purchasing Behavior Analysis: How do the purchasing habits (frequency, basket size, spending amount) of long-term customers differ from those of new customers? 
--     What insights can these patterns provide about customer loyalty and retention strategies?

WITH cte AS (
SELECT 
i.customer_id,
MIN(i.invoice_date) AS first_purchase_date,
MAX(i.invoice_date) AS last_purchase_date,
SUM(i.total) AS total_spent,
SUM(il.quantity) AS items_bought,
COUNT(DISTINCT i.invoice_id) AS frequency,
TIMESTAMPDIFF(DAY, MIN(i.invoice_date), MAX(i.invoice_date)) AS customer_lifetime_days
FROM invoice i
LEFT JOIN invoice_line il 
ON il.invoice_id = i.invoice_id
GROUP BY i.customer_id
),

avg_lifetime AS (SELECT AVG(customer_lifetime_days) AS avg_days
FROM cte
),

long_short_term AS (
SELECT 
cte.*,
CASE
	WHEN customer_lifetime_days > (SELECT avg_days FROM avg_lifetime)
	THEN 'Long Term'
	ELSE 'Short Term'
END AS customer_type
FROM cte
)

SELECT 
customer_type,
COUNT(*) AS number_of_customers,
ROUND(AVG(total_spent), 2) AS avg_spending,
ROUND(AVG(items_bought), 2) AS avg_basket_size,
ROUND(AVG(frequency), 2) AS avg_purchase_frequency
FROM long_short_term
GROUP BY customer_type;

-- (Q4)Product Affinity Analysis: Which music genres, artists, or albums are frequently purchased together by customers?
--     How can this information guide product recommendations and cross-selling initiatives?

-- Genres frequently purchased together
SELECT 
g1.name AS genre_1, 
g2.name AS genre_2, 
COUNT(*) AS times_bought_together
FROM invoice_line il1
JOIN invoice_line il2 
ON il1.invoice_id = il2.invoice_id 
AND il1.track_id < il2.track_id
JOIN track t1 ON il1.track_id = t1.track_id
JOIN track t2 ON il2.track_id = t2.track_id
JOIN genre g1 ON t1.genre_id = g1.genre_id
JOIN genre g2 ON t2.genre_id = g2.genre_id
WHERE g1.genre_id <> g2.genre_id
GROUP BY g1.name, g2.name
ORDER BY times_bought_together DESC
LIMIT 10;

-- Albums frequently purchased together
SELECT 
al1.title AS album_1, 
al2.title AS album_2, 
COUNT(*) AS times_bought_together
FROM invoice_line il1
JOIN invoice_line il2 
ON il1.invoice_id = il2.invoice_id 
AND il1.track_id < il2.track_id
JOIN track t1 ON il1.track_id = t1.track_id
JOIN track t2 ON il2.track_id = t2.track_id
JOIN album al1 ON t1.album_id = al1.album_id
JOIN album al2 ON t2.album_id = al2.album_id
WHERE al1.album_id <> al2.album_id
GROUP BY al1.title, al2.title
ORDER BY times_bought_together DESC
LIMIT 10;

-- Artists frequently purchased together
SELECT 
ar1.name AS artist_1, 
ar2.name AS artist_2, 
COUNT(*) AS times_bought_together
FROM invoice_line il1
JOIN invoice_line il2 
ON il1.invoice_id = il2.invoice_id 
AND il1.track_id < il2.track_id
JOIN track t1 ON il1.track_id = t1.track_id
JOIN track t2 ON il2.track_id = t2.track_id
JOIN album al1 ON t1.album_id = al1.album_id
JOIN album al2 ON t2.album_id = al2.album_id
JOIN artist ar1 ON al1.artist_id = ar1.artist_id
JOIN artist ar2 ON al2.artist_id = ar2.artist_id
GROUP BY ar1.name, ar2.name
ORDER BY times_bought_together DESC
LIMIT 10;


-- (Q5) Regional Market Analysis: Do customer purchasing behaviors and churn rates vary across different geographic regions or store locations?
--      How might these correlate with local demographic or economic factors?

WITH last_purchase AS (
SELECT
customer_id,
billing_country AS region,
MAX(invoice_date) AS last_order_date
FROM invoice
GROUP BY customer_id, billing_country
),

customer_status AS (
SELECT 
lp.*,
	CASE 
		WHEN lp.last_order_date < (SELECT DATE_SUB(MAX(invoice_date), INTERVAL 6 MONTH)
		FROM invoice) 
        THEN 1 ELSE 0
END AS is_churned
FROM last_purchase lp
)

SELECT 
region,
COUNT(*) AS total_customers,
SUM(is_churned) AS churned_customers,
ROUND(SUM(is_churned) * 100.0 / COUNT(*), 2) AS churn_rate
FROM customer_status
GROUP BY region
ORDER BY churn_rate DESC;


-- (Q6)Customer Risk Profiling: Based on customer profiles (age, gender, location, purchase history), 
--    which customer segments are more likely to churn or pose a higher risk of reduced spending?
--    What factors contribute to this risk?

WITH customer_base AS (
SELECT
customer_id,
COUNT(invoice_id) AS total_purchases,
SUM(total) AS total_spent,
MAX(invoice_date) AS last_order_date
FROM invoice
GROUP BY customer_id
),

customer_flags AS (
SELECT
customer_id,
total_purchases,
total_spent,
    CASE 
		WHEN total_purchases >= 10 THEN 'High Frequency'
		ELSE 'Low Frequency'
	END AS frequency_segment,

	CASE 
		WHEN total_spent >= 100 THEN 'High Value'
		ELSE 'Low Value'
	END AS value_segment,

	CASE 
		WHEN last_order_date < DATE_SUB('2020-12-30', INTERVAL 6 MONTH)
		THEN 1 ELSE 0
END AS churned
FROM customer_base
)
SELECT
    frequency_segment,
    value_segment,
    COUNT(*) AS customers,
    SUM(churned) AS churned_customers,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2) AS churn_rate
FROM customer_flags
GROUP BY frequency_segment, value_segment
ORDER BY churn_rate DESC;

-- (Q7) Customer Lifetime Value Modeling: How can you leverage customer data (tenure, purchase history, engagement) to predict the lifetime value of different customer segments?
--      This could inform targeted marketing and loyalty program strategies.
--      Can you observe any common characteristics or purchase patterns among customers who have stopped purchasing?

WITH customer_base AS
(SELECT
c.customer_id,
COUNT(i.invoice_id) AS total_orders,
SUM(i.total) AS total_spent,
MIN(i.invoice_date) AS first_purchase,
MAX(i.invoice_date) AS last_purchase,
DATEDIFF(MAX(i.invoice_date),MIN(i.invoice_date)) AS customer_tenure
FROM customer c

JOIN invoice i
ON c.customer_id = i.customer_id
GROUP BY c.customer_id
),

customer_segments AS
(SELECT
customer_id,
total_orders,
total_spent,
customer_tenure,
ROUND(total_spent / NULLIF(total_orders, 0),2) AS avg_order_value,

CASE
    WHEN total_spent >= 100
	THEN 'High Value'
	ELSE 'Low Value'
END AS value_segment,

CASE
	WHEN total_orders >= 10
	THEN 'Frequent'
	ELSE 'Infrequent'
END AS frequency_segment,

CASE
	WHEN last_purchase <
                 DATE_SUB(
                     (SELECT MAX(invoice_date) FROM invoice),INTERVAL 6 MONTH)
	THEN 'Churned'
	ELSE 'Active'
END AS churn_status
FROM customer_base
)
SELECT
churn_status,
value_segment,
frequency_segment,
COUNT(*) AS customers,
ROUND(AVG(total_spent), 2) AS avg_spent,
ROUND(AVG(avg_order_value), 2) AS avg_order_value,
ROUND(AVG(customer_tenure), 0) AS avg_tenure_days
FROM customer_segments
GROUP BY churn_status,value_segment,frequency_segment
ORDER BY
churn_status,
avg_spent DESC;

-- (Q8) & (Q9) => In DOC

-- (Q10)How can you alter the "Albums" table to add a new column named "ReleaseYear" of type INTEGER to store the release year of each album?

ALTER TABLE album
ADD COLUMN ReleaseYear INT;

-- Checking whether New column is added successfully or not.
SELECT * FROM album;
DESC album;

-- (Q11)Chinook is interested in understanding the purchasing behavior of customers based on their geographical location.
--      They want to know the average total amount spent by customers from each country,along with the number of customers and the average number of tracks purchased per customer.
--      Write an SQL query to provide this information.

WITH customer_summary AS (
SELECT 
i.customer_id,
SUM(i.total) AS total_spent,
SUM(il.quantity) AS tracks_purchased
FROM invoice i
JOIN invoice_line il 
ON i.invoice_id = il.invoice_id
GROUP BY i.customer_id
)
SELECT 
c.country,
COUNT(DISTINCT c.customer_id) AS num_customers,
ROUND(AVG(cs.total_spent), 2) AS avg_spent_per_customer,
ROUND(AVG(cs.tracks_purchased), 2) AS avg_tracks_per_customer
FROM customer c
JOIN customer_summary cs 
ON c.customer_id = cs.customer_id
GROUP BY c.country
ORDER BY avg_spent_per_customer DESC;


--                                         THANKYOU