select customer_id,
       txn_date,
       txn_type,
       txn_amount,
       sum(case 
             when txn_type = 'deposit' then txn_amount
             when txn_type IN ('withdrawal', 'purchase') then -txn_amount
             else 0
           end) over (partition by customer_id order by txn_date) AS [so du hien tai] 
from customer_transactions

with tong_tien as (
  select customer_id, txn_date,
         sum(case
               when txn_type = 'deposit' then txn_amount
               when txn_type IN ('withdrawal', 'purchase') then -txn_amount
               else 0
             end) over (partition by customer_id order by txn_date) as [so du hien tai]
  from customer_transactions
)
select customer_id,
       year(txn_date) as nam,
       month(txn_date) as thang,
       max([so du hien tai]) as [so du cuoi thang]
from tong_tien
group by customer_id, year(txn_date), month(txn_date);


with tong_tien as (
  select 
    customer_id,
    txn_date,
    txn_type,
    txn_amount,
    sum(case 
          when txn_type = 'deposit' then txn_amount
          when txn_type IN ('withdrawal', 'purchase') then -txn_amount
          else 0 
        end) over (partition by customer_id order by txn_date) as tong_tien
  from customer_transactions
),
giao_dich_cuoi as (
  select 
    customer_id,
    year (txn_date) as nam,
	month (txn_date) as thang,
    max(txn_date) as giao_dich_cuoi
  from tong_tien
  group by customer_id,year (txn_date),month (txn_date)
)
select r.customer_id, thang, nam, r.tong_tien as so_du_cuoi_thang
from tong_tien r
inner join giao_dich_cuoi l
  on r.customer_id = l.customer_id 
  and month(r.txn_date) = l.thang
  and r.txn_date = l.giao_dich_cuoi


