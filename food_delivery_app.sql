/*Details about gold members of the food delivery app*/

drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');


/*Details about users of the food delivery app*/

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');


/*Details about sales of the food delivery app*/

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


/*Details about products of the food delivery app*/

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




/*Q.1 What is the total amount each custiomer spent on food delivery app?*/

select a.userid ,sum(b.price) from 
sales a inner join product b 
on a.product_id = b.product_id 
group by a.userid;

/*Q.2 How many days has each customer visited the food delivery app?*/

select userid , count(distinct created_date) number_of_days from sales
group by userid;

/*Q.3 What was the first product purchased by each customer ?*/
select * from
(select *,rank() over(partition by userid order by created_date)rnk from sales)a
where rnk=1;

/*Q.4 What is the most prucahsed item on the menu and how many times was it purchased by all customers ?*/

select userid, count(product_id) from sales where product_id  =
(select  top 1 product_id from sales
group by product_id
order by count(*) desc)
group by userid;

/*Q.5 Which product is most popular by each of the customers ?*/

select * from
(select *,rank() over(partition by userid order by cnt desc)rnk from
(select userid, product_id, count(product_id) cnt from sales
group by userid, product_id)a)b
where rnk=1;

/*Q.6 Which item was purchased first by the customer after they become a memeber ?*/

select * from
(select * , rank() over(partition by userid order by created_date)rnk from
(select a.* , b.gold_signup_date from 
sales a inner join  goldusers_signup b 
on a.userid= b.userid and created_date >gold_signup_date)a)b
where rnk=1;

/*Q.7 Which item was purchased just before the customer become a memeber ?*/
select * from
(select * , rank() over(partition by userid order by created_date desc)rnk from
(select a.* , b.gold_signup_date from 
sales a inner join  goldusers_signup b 
on a.userid= b.userid and created_date <gold_signup_date)a)b
where rnk=1;

/*Q.8 What is the total orders and amount spent by each customers beforethey become a memeber ?*/

select userid , count(created_date) order_purchased, sum(price) amount_spent from
(select c.* , d.price from
(select a.* , b.gold_signup_date from 
sales a inner join  goldusers_signup b 
on a.userid= b.userid and created_date <gold_signup_date)c inner join 
product d on c.product_id= d.product_id)e
group by userid;

/*Q.9 If buying each product generates points and each product has diffrebt purchasing points
as: for p1 5rs = 1 app points , for p2 10rs = 5 app points , for p3 5rs = 1 app point.

Calculate points collected by each customers and for which product most points have been given till now. */

/*points collected by each customers*/
select userid , sum(total_points_earned) as total_cashback_earned from
(select e.* , amt/points as total_points_earned from
(select d.* ,
case 
	when product_id = 1 then 5
	when product_id = 2 then 2
	when product_id = 3 then 5
	else 0 end as points
from 
(select c.userid , c.product_id , sum(price) amt from
(select a.* , b.price from sales a 
inner join product b 
on a.product_id = b.product_id)as c
group by userid,product_id) as d)as e)as f
group by userid;

/*product most points have been given till now  */

select * from
(select * ,rank() over (order by total_cashback_earned desc)rnk from
(select product_id , sum(total_points_earned) as total_cashback_earned from
(select e.* , amt/points as total_points_earned from
(select d.* ,
case 
	when product_id = 1 then 5
	when product_id = 2 then 2
	when product_id = 3 then 5
	else 0 end as points
from 
(select c.userid , c.product_id , sum(price) amt from
(select a.* , b.price from sales a 
inner join product b 
on a.product_id = b.product_id)as c
group by userid,product_id) as d)as e)as f
group by product_id)g)h
where rnk =1;


/*Q.10 In the first one year aftr the customers joined the gold program (including their join date) irrespective 
of what type of product is purchased they earn 5 app point for every 10 rs spent.
who earned more Customer 2 or customer 3  and what was their points earnings in their first year?*/


/*5 points = 10 rs
  1 point = 2 rs
  0.5 points =1rs*/

select c.* , d.price, d.price*0.5 as points_earned from
(select a.* , b.gold_signup_date  from sales a 
inner join goldusers_signup b 
on a.userid=b.userid  and created_date>= gold_signup_date
and created_date <=DATEADD(year , 1, gold_signup_date))c
inner join product d 
on c.product_id = d.product_id;


/*Q.11 Rank all the transaction of the customers*/

select *, rank() over(partition by userid order by created_date asc)rnk from sales;

/*Q.12 Rank all the transaction of each member whenever they are a zomato gold member for 
every non gold member transaction mark as na .*/

select d.* , case when rnk= 0 then 'na' else rnk end as rnk from
(select c.*,cast(case 
	when gold_signup_date is NULL then 0 
	else rank() over(partition by userid order by created_date desc) end as varchar)as rnk 
from (select a.* , b.gold_signup_date  from sales a 
left join goldusers_signup b 
on a.userid=b.userid  and created_date>= gold_signup_date)c)d;


