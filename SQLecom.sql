
--List all unique cities where customers are located.
select distinct(customer_city) as [distinct_city] from customers

--Count the number of orders placed in 2017.
select count(order_id) as [total_order_placed_in_2017] from orders where year(order_purchase_timestamp) = 2017

--Find the total sales per category
select round(sum(py.payment_value),2) as sales,pr.product_category as category from products as pr inner join order_items as ot
on pr.product_id = ot.product_id 
inner join payments as py
on py.order_id = ot.order_id
group by  product_category

--Calculate the percentage of orders that were paid in installments
select sum(case when payment_installments >= 1 then 1 else 0 end)*100/count(*) from payments

--Count the number of customers from each state.
select count(*) as [number_of_customer_from_each_state],customer_state as [state] from customers group by customer_state

--Calculate the number of orders per month in 2018.
select count(*) as [number_of_orders_placed_per_month],month(order_purchase_timestamp) as [months] from orders
where year(order_purchase_timestamp) = 2018 group by month(order_purchase_timestamp) order by [months]

--Find the average number of products per order, grouped by customer city.
WITH COUNT_PER_ORDER AS
(
SELECT OD.ORDER_ID,OD.CUSTOMER_ID, COUNT(OT.ORDER_ID) AS OC
FROM ORDERS AS OD JOIN ORDER_ITEMS AS OT
ON OD.ORDER_ID = OT.ORDER_ID
GROUP BY OD.ORDER_ID,OD.CUSTOMER_ID
)
SELECT CU.CUSTOMER_CITY, AVG(COUNT_PER_ORDER.OC) AS [AVG_ORD]
FROM CUSTOMERS AS CU JOIN COUNT_PER_ORDER
ON CU.CUSTOMER_ID = COUNT_PER_ORDER.CUSTOMER_ID
GROUP BY CU.CUSTOMER_CITY ORDER BY [AVG_ORD] DESC

--Calculate the percentage of total revenue contributed by each product category.
select ROUND((sum(py.payment_value)/(SELECT SUM(PAYMENT_VALUE) FROM payments))*100,2) as sales_PERCENTAGE,
pr.product_category as category 
from products as pr inner join order_items as ot
on pr.product_id = ot.product_id 
inner join payments as py
on py.order_id = ot.order_id
group by  product_category
ORDER BY sales_PERCENTAGE DESC

--Identify the correlation between product price and the number of times a product has been purchased.
select pd.product_category,count(ot.product_id) as [number_of_times_product_purchased] ,round(avg(ot.price),2) as [price]
from products as pd join order_items as ot
on pd.product_id = ot.product_id
group by pd.product_category

--Calculate the total revenue generated by each seller, and rank them by revenue
select *,dense_rank() over(order by revenue desc) as [rank] from
(select ot.seller_id,sum(py.payment_value) as [revenue]
from order_items as ot join payments as py
on ot.order_id = py.order_id
group by ot.seller_id) as a

--Calculate the moving average of order values for each customer over their order history.
select customer_id,order_purchase_timestamp,payment,
avg(payment) over(partition by customer_id order by order_purchase_timestamp
rows between 2 preceding and current row) as moving_average
from
(select od.customer_id,od.order_purchase_timestamp,
py.payment_value as payment
from payments as py join orders as od
on py.order_id = od.order_id) as a

--Calculate the cumulative sales per month for each year.
select years,months,payment, sum(payment)
over(order by years, months) as [cumulative_sales] from
(select year(od.order_purchase_timestamp) as years,
month(od.order_purchase_timestamp) as months,
sum(py.payment_value) as payment 
from orders as od join payments as py
on od.order_id = py.order_id
group by year(od.order_purchase_timestamp), month(od.order_purchase_timestamp) 
) as a
order by years,months

--Calculate the year-over-year growth rate of total sales
with a as
(
select year(orders.order_purchase_timestamp) as years,
sum(payments.payment_value) as payment
from orders join payments
on orders.order_id = payments.order_id
group by year(orders.order_purchase_timestamp)
)
select years,((payment - lag(payment,1) over(order by years))/
lag(payment,1) over(order by years))*100
as [yoy_%_growth] from a


--Identify the top 3 customers who spent the most money in each year
select years, customer_id, payment, d_rank
from
(select year(orders.order_purchase_timestamp) as years,
orders.customer_id,
sum(payments.payment_value) as payment,
dense_rank() over(partition by year(orders.order_purchase_timestamp)
order by sum(payments.payment_value) desc) as d_rank
from orders join payments 
on payments.order_id = orders.order_id
group by year(orders.order_purchase_timestamp),
orders.customer_id) as a
where d_rank <= 3



select * from customers
select * from geolocation
select * from order_items
select * from orders
select * from payments
select * from products
select * from sellers



