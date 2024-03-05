/*
Question #1:

Write a query to find the customer(s) with the most orders. 
Return only the preferred name.

Expected column names: preferred_name
*/

-- q1 solution:

SELECT c.preferred_name
FROM customers c
INNER JOIN (
  SELECT customer_id, COUNT(*) AS num_orders
  FROM orders
  GROUP BY customer_id
  ORDER BY num_orders DESC
  LIMIT 2
) o ON o.customer_id = c.customer_id;; -- replace this with your query


/*
Question #2: 
RevRoll does not install every part that is purchased. 
Some customers prefer to install parts themselves. 
This is a valuable line of business 
RevRoll wants to encourage by finding valuable self-install customers and sending them offers.

Return the customer_id and preferred name of customers 
who have made at least $2000 of purchases in parts that RevRoll did not install. 

Expected column names: customer_id, preferred_name

*/

-- q2 solution:

SELECT c.customer_id, c.preferred_name
FROM customers c

JOIN orders o ON c.customer_id = o.customer_id
JOIN parts p ON o.part_id = p.part_id

LEFT JOIN installs i ON o.order_id = i.order_id
WHERE i.order_id IS NULL

GROUP BY c.customer_id, c.preferred_name
HAVING SUM(p.price * o.quantity) >= 2000;; -- replace this with your query

/*
Question #3: 
Report the id and preferred name of customers who bought an Oil Filter and Engine Oil 
but did not buy an Air Filter since we want to recommend these customers buy an Air Filter.
Return the result table ordered by `customer_id`.

Expected column names: customer_id, preferred_name

*/

-- q3 solution:

-- Select customers who have ordered 'Oil Filter' or 'Engine Oil'
-- and have not ordered 'Air Filter'
SELECT
    c.customer_id,
    c.preferred_name
FROM
    customers c
JOIN
    orders o ON c.customer_id = o.customer_id
JOIN
    parts p ON o.part_id = p.part_id
WHERE
    p.name IN ('Oil Filter', 'Engine Oil')
    AND c.customer_id NOT IN (
        -- Subquery to identify customers who have ordered 'Air Filter'
        SELECT
            c2.customer_id
        FROM
            customers c2
        JOIN
            orders o2 ON c2.customer_id = o2.customer_id
        JOIN
            parts p2 ON o2.part_id = p2.part_id
        WHERE
            p2.name = 'Air Filter'
    )
GROUP BY
    c.customer_id, c.preferred_name
ORDER BY
    c.customer_id;; -- replace this with your query

/*
Question #4: 

Write a solution to calculate the cumulative part summary for every part that 
the RevRoll team has installed.

The cumulative part summary for an part can be calculated as follows:

- For each month that the part was installed, 
sum up the price*quantity in **that month** and the **previous two months**. 
This is the **3-month sum** for that month. 
If a part was not installed in previous months, 
the effective price*quantity for those months is 0.
- Do **not** include the 3-month sum for the **most recent month** that the part was installed.
- Do **not** include the 3-month sum for any month the part was not installed.

Return the result table ordered by `part_id` in ascending order. In case of a tie, order it by `month` in descending order. Limit the output to the first 10 rows.

Expected column names: part_id, month, part_summary
*/

-- q4 solution:

WITH InstallationsWithDates AS (
    SELECT
        i.install_id,
        i.order_id,
        i.installer_id,
        i.install_date,
        o.part_id,
        o.quantity,
        p.price
    FROM
        installs i
    JOIN orders o ON i.order_id = o.order_id
    JOIN parts p ON o.part_id = p.part_id
),
MonthlyTotals AS (
    SELECT
        part_id,
        EXTRACT(MONTH FROM install_date) AS month,
        ROUND(SUM(price * quantity), 2) AS monthly_total
    FROM
        InstallationsWithDates
    GROUP BY
        part_id, month
),
ThreeMonthSums AS (
    SELECT
        part_id,
        month,
        SUM(monthly_total) OVER (PARTITION BY part_id ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS three_month_sum
    FROM
        MonthlyTotals
)
SELECT
    t.part_id,
    t.month,
    COALESCE(t.three_month_sum, 0) AS part_summary
FROM
    ThreeMonthSums t
ORDER BY
    t.part_id ASC, t.month DESC
LIMIT 10;; -- replace this with your query

