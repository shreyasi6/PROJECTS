select * from cust_dimen;
select * from market_fact;
select * from orders_dimen;
select * from shipping_dimen;
select * from prod_dimen;

#    Question 1: Find the top 3 customers who have the maximum number of orders
# top 3 customers having max no of orders

select * from (
select *,dense_rank()over(order by no_orders desc) as rnk from (
select customer_name,customer_segment,c.cust_id,count(ord_id)  no_orders
from cust_dimen c left join  market_fact m
on c.Cust_id=m.Cust_id
group by cust_id)temp )temp2
where rnk <=3 ;

# Question 2: Create a new column DaysTakenForDelivery that contains the date difference between Order_Date and Ship_Date.
desc shipping_dimen;
select *,datediff(str_to_date(ship_date,'%d-%m-%Y'),str_to_date(order_date,'%d-%m-%Y')) daystakenfordelivery from (
select o.order_id,order_date,ship_date 
from  orders_dimen o
join shipping_dimen s on o.order_id=s.Order_ID)temp
order by daystakenfordelivery desc;

#Question 3: Find the customer whose order took the maximum time to get delivere

select c.customer_name,order_id,c.cust_id,max(daystakenfordelivery)  total_dayfordelivery
from cust_dimen c join (
select *,datediff(str_to_date(ship_date,'%d-%m-%Y'),str_to_date(order_date,'%d-%m-%Y')) daystakenfordelivery from (
select cust_id,  o.order_id,order_date,ship_date from market_fact m join orders_dimen o using(ord_id)
join shipping_dimen s on o.order_id=s.Order_ID)temp)temp2
on c.cust_id=temp2.cust_id
group by cust_id,Customer_Name 
order by total_dayfordelivery desc
limit 1;

# Question 4: Retrieve total sales made by each product from the data (use Windows function

select distinct prod_id,sum(sales) over(partition by prod_id ) tot_sales from market_fact
order by tot_sales desc;

#       Question 5: Retrieve the total profit made from each product from the data (use windows function)
select * from market_fact;
select *,if(tot_profit>0,'profit','loss') as status from(
select distinct prod_id,sum(profit) over(partition by prod_id ) tot_profit from market_fact
order by tot_profit desc)t;

# Question 6: Count the total number of unique customers in January and how many of them came back every month 
#             over the entire year in 2011.

# count of unique customers.
select count(distinct cust_id) from market_fact m join orders_dimen o  using(ord_id)
where year(str_to_date(order_date,'%d-%m-%Y'))=2011 and  month(str_to_date(order_date,'%d-%m-%Y'))= 1;

# how many of them came back in the entire year 2011.
select t.cust_id,count(t.cust_id) over()  as count_of_customers from 
(select distinct cust_id from market_fact m join orders_dimen o  using(ord_id)
where year(str_to_date(order_date,'%d-%m-%Y'))=2011 and  month(str_to_date(order_date,'%d-%m-%Y'))= 1)t
join 
(select distinct cust_id from market_fact m join orders_dimen o  using(ord_id)
where year(str_to_date(order_date,'%d-%m-%Y'))=2011 and  month(str_to_date(order_date,'%d-%m-%Y'))<> 1 )t1
on t.cust_id=t1.cust_id;


# Part 2 – Restaurant:

#Question 1: - We need to find out the total visits to all restaurants under all alcohol categories available.
select * from  geoplaces2;
select * from userprofile;
select * from chefmozaccepts;
select * from rating_final;
select * from usercuisine;

select alcohol,count(*) as total_visits from rating_final join geoplaces2
using(placeid)
group by alcohol;

#Question 2: -Let's find out the average rating according to alcohol and price so that 
# we can understand the rating in respective price categories as well.

select * from userpayment;
select avg(rating),alcohol,price from geoplaces2 g join rating_final r
on g.placeid=r.placeid
group by alcohol,price
order by alcohol;

#Question 3:  Let’s write a query to quantify that what are the parking availability as well in different alcohol categories
#  along with the total number of restaurants.

select parking_lot,alcohol, count(placeid ) total_no_of_restaurants from
(select  alcohol,g.placeid,parking_lot from 
geoplaces2 g
join 
chefmozparking  c
on g.placeid=c.placeid)t
group by parking_lot,alcohol
order by parking_lot;

# Question 4: -Also take out the percentage of different cuisine in each alcohol type.

 select * from
 (select *,(no_rcuisine/no_alcohol) * 100 as percentage_cuisine from (
select alcohol,rcuisine,count(rcuisine)over(partition by alcohol,rcuisine) no_rcuisine,
 count(alcohol)over(partition by alcohol) no_alcohol
 from geoplaces2 g join chefmozcuisine c on g.placeID=c.placeID)t)t1
 group  by alcohol,rcuisine;
 

# Let us now look at a different prospect of the data to check state-wise rating.

# Questions 5: - let’s take out the average rating of each state.
select state,avg(rating) avg_rating from geoplaces2 g join
rating_final r on g.placeID=r.placeID
group by state
order by avg_rating ;

# Questions 6: -' Tamaulipas' Is the lowest average rated state. Quantify the reason why it is the lowest rated by
#                     providing the summary on the basis of State, alcohol, and Cuisine.

select  t.placeid,name,alcohol,price,other_services,area,smoking_area,rcuisine,parking_lot,rating from (
select * from geoplaces2 where state='tamaulipas')t join rating_final r using(placeid) join chefmozcuisine
using(placeid) join chefmozparking using (placeid)
order by  rating;

# the state 'tamaulipas' has lowest ratings because of following reasons:-

-- almost no restrant serves Alcohol this is main reason for the lower ratings
-- and no resturant provides internet services at the place
-- moreover 30% of resturant not providing parking

# Question 7:  - Find the average weight, food rating, and service rating of the customers who have visited KFC 
#  and tried Mexican or Italian types of cuisine, and also their budget level is low. 
#   We encourage you to give it a try by not using joins.

select * from geoplaces2 order by name;

select distinct u.userid,avg(weight) over() as average_weight,name,food_rating,service_rating from userprofile u join 
rating_final r using(userid) join geoplaces2 g using(placeid)join usercuisine uc using(userid)
where name='kfc' and Rcuisine in ('mexican','italian') and budget='low';


select  avg(weight)over() from userprofile where  budget ="low" and  userid in(
select userid from usercuisine where rcuisine in ('italian', 'mexican') and  userid in(
select userID from rating_final where placeID in(
select placeID from geoplaces2 where name="kfc")));


# Part 3:  Triggers

#Question 1:
# Create two called Student_details and Student_details_backup.
#You have the above two tables Students Details and Student Details Backup. Insert some records into Student details. 

CREATE TABLE  student_details(
student_id int,
student_name varchar(50),
mail_id varchar(50),
mobile bigint
); 

insert into student_details values
(1,'ram','ram@gmail.com',988766666),
(2,'shyam','shyam@gmail.com',9883436666),
(3,'jayant','jayant@gmail.com',9887123446),
(4,'mahesh','mahesh@gmail.com',988767896),
(5,'kamal','kamal@gmail.com',956789666);

select * from student_details;

create table student_details_backup(  
student_id int ,
student_name varchar(50),
mail_id varchar(50),
mobile bigint
); 

delimiter //
create trigger delete_in
after delete on student_details
for each row
begin
insert into student_details_backup values(old.student_id,old.student_name,old.mail_id,old.mobile);
end //
 



delete from student_details where student_id = 4;

select * from  student_details;
select * from student_details_backup;
truncate student_details_backup
drop trigger delete_in;


-- 1. top 3 customers with highest order quantity 
select c.cust_id ,sum(order_quantity) total_quantity from  cust_dimen c join market_fact m using(cust_id)
group by c.cust_id
order by  total_quantity desc limit 3;

select * from cust_dimen;
select * from market_fact;
select * from orders_dimen;
select * from shipping_dimen;
select * from prod_dimen;

-- 2. total no of orders according to each ship_mode
select count(order_id),ship_mode from shipping_dimen
group by ship_mode ; 

desc shipping_dimen; 
-- 3.  total  sales  in  each year

select sum(sales) ,year(str_to_date(ship_date,'%d-%m-%Y'))
from shipping_dimen s join market_fact m
on s.ship_id=m.ship_id
group by year(str_to_date(ship_date,'%d-%m-%Y')) ;

-- 4. retrieve the count of customers who somkes and drink accoring to their weight range.
select * from  geoplaces2;
select * from userprofile;
select * from chefmozaccepts;
select * from rating_final;
select * from usercuisine;

select distinct drink_level from userprofile;

select count(userid),
case
when weight between 40 and 60 then '40-60kg'
when weight between 61 and 90 then  '61-90kg'
when weight between 91 and 120 then '91-120kg'
end
 as weight_range from userprofile
where smoker = 'true'
group by weight_range

-- 5. retrieve the rcuisine type and count under each budget type

select budget,rcuisine,count(rcuisine)over(partition by budget) as count_budget,count(rcuisine)over(partition by rcuisine) as count_rcuisine
from userprofile join usercuisine using(userid)
group by budget,rcuisine order by budget ;


