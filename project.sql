
drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

--Problem 1 : What is the total amount each customer spent on zomato???

SELECT userid,
       Sum(price) AS total_spent
FROM   sales
       INNER JOIN product
               ON sales.product_id = product.product_id
GROUP  BY userid 

--Problem 2 : How many days has each customer visited zomato??

SELECT userid,
       Count(userid) AS no_of_times_visited
FROM   sales
GROUP  BY userid; 

--Problem 3 : What was the first product purchased by each customer?

WITH cte
     AS (SELECT *,
                Rank()
                  OVER(
                    partition BY userid
                    ORDER BY created_date ASC) AS rnk
         FROM   sales)
SELECT *
FROM   cte
WHERE  rnk = 1 

--Problem 4 : What is the most purchased item on the menu and how many times was it purchased?

SELECT TOP 1 product_id,
             Count(product_id) AS cnt
FROM   sales
GROUP  BY product_id
ORDER  BY cnt DESC; 

--Problem 5 : Which item was the most popular for each customer?

SELECT *
FROM   (SELECT *,
               Rank()
                 OVER(
                   partition BY userid
                   ORDER BY cnt DESC) AS rnk
        FROM   (SELECT userid,
                       product_id,
                       Count(product_id) AS cnt
                FROM   sales
                GROUP  BY userid,
                          product_id) AS a) AS b
WHERE  rnk = 1; 

--Problem 6 : Which item was purchased first by the customer after they become a member?

WITH cte3
     AS (SELECT sales.userid,
                sales.created_date,
                sales.product_id,
                goldusers_signup.gold_signup_date
         FROM   sales
                INNER JOIN goldusers_signup
                        ON sales.userid = goldusers_signup.userid
                           AND created_date > gold_signup_date)
SELECT TOP 2 userid,
             product_id
FROM   cte3
ORDER  BY created_date,
          gold_signup_date; 

--Problem 7 : Which item was purchased just before the customer become a member?

WITH cte3
     AS (SELECT sales.userid,
                sales.created_date,
                sales.product_id,
                goldusers_signup.gold_signup_date
         FROM   sales
                INNER JOIN goldusers_signup
                        ON sales.userid = goldusers_signup.userid
                           AND created_date < gold_signup_date),
     cte4
     AS (SELECT *,
                Rank()
                  OVER(
                    partition BY userid
                    ORDER BY created_date DESC) AS rnk
         FROM   cte3)
SELECT *
FROM   cte4
WHERE  rnk = 1; 

--Problem 8 : What is the total orders and amount spent for each member before they became a member?

WITH cte5
     AS (SELECT sales.userid,
                sales.created_date,
                sales.product_id,
                goldusers_signup.gold_signup_date
         FROM   sales
                INNER JOIN goldusers_signup
                        ON sales.userid = goldusers_signup.userid
                           AND created_date < gold_signup_date),
     cte6
     AS (SELECT userid,
                cte5.product_id,
                product_name,
                price
         FROM   cte5
                INNER JOIN product
                        ON cte5.product_id = product.product_id)
SELECT userid,
       Count(product_id) AS total_orders,
       Sum(price)        AS amount_spent
FROM   cte6
GROUP  BY userid; 

--Problem 9 : If buying each product generates points for eg 5rs=2 zomato point and each product has different
              --purchasing points for eg for p1 5rs=1 zomato point,for p2 10rs=5 zomato point and p3 5rs=1
			  --zomato point,calculate points collected by each customers and for which product most points 
			  --have been given till now.

WITH cte7
     AS (SELECT userid,
                sales.product_id,
                product_name,
                price
         FROM   sales
                INNER JOIN product
                        ON sales.product_id = product.product_id),
     cte8
     AS (SELECT cte7.userid,
                cte7.product_name,
                cte7.price,
                CASE
                  WHEN cte7.product_id = 1 THEN 5
                  WHEN cte7.product_id = 2 THEN 2
                  WHEN cte7.product_id = 3 THEN 5
                END AS points
         FROM   cte7),
     cte9
     AS (SELECT userid,
                price / points AS pts
         FROM   cte8)
SELECT userid,
       Sum(pts) AS total_pts_per_user
FROM   cte9
GROUP  BY userid;

WITH cte10
     AS (SELECT sales.product_id,
                Sum(price) AS total
         FROM   sales
                INNER JOIN product
                        ON sales.product_id = product.product_id
         GROUP  BY sales.product_id),
     cte11
     AS (SELECT *,
                CASE
                  WHEN product_id = 1 THEN 5
                  WHEN product_id = 2 THEN 2
                  WHEN product_id = 3 THEN 5
                END AS ptss
         FROM   cte10),
     cte12
     AS (SELECT TOP 1 *,
                      total / ptss AS final_pts
         FROM   cte11
         ORDER  BY final_pts DESC)
SELECT product_id,
       final_pts
FROM   cte12; 

--Problem 10 : In the first one year after a customer joins the gold program(including their join date)
             --irrespective of what the customer has purchased they earn 5 zomato points for every 10 rs
			 --spent who earned more 1 or 3 and what was their points earnings in their first year?

WITH cte22
     AS (SELECT sales.userid,
                created_date,
                product_id,
                gold_signup_date
         FROM   sales
                INNER JOIN goldusers_signup
                        ON sales.userid = goldusers_signup.userid),
     cte23
     AS (SELECT *,
                CASE
                  WHEN userid = 1 THEN Dateadd(year, 1, '2017-09-22')
                  WHEN userid = 3 THEN Dateadd(year, 1, '2017-04-21')
                END AS dates
         FROM   cte22),
     cte33
     AS (SELECT userid,
                created_date,
                product_id,
                dates,
                gold_signup_date
         FROM   cte23),
     cte44
     AS (SELECT *
         FROM   cte33
         WHERE  created_date <= dates
                AND created_date >= gold_signup_date),
     cte66
     AS (SELECT userid,
                created_date,
                dates,
                cte44.product_id,
                price,
                gold_signup_date
         FROM   cte44
                INNER JOIN product
                        ON cte44.product_id = product.product_id)
SELECT userid,
       price,
       price / 2 AS ptss
FROM   cte66; 

--Problem 11 : Rank all the transactions of the customers

SELECT *,
       Rank()
         OVER(
           partition BY userid
           ORDER BY created_date) AS rnk
FROM   sales; 
















