--Tìm kiếm xem có bao nhiêu nút khác nhau
select count (*) as [Số nút khách nhau]
from (
	select distinct c.node_id from customer_nodes as c ) as s 
--Xem sự phân bố khách hàng từng khu vực
select r.region_name as [Khu vực] ,count (c.customer_id) as [tổng khach hang] from regions as r
inner join customer_nodes as c on c.region_id=r.region_id 
group by r.region_name
--Tổng số tiền của từng loại giao dịch
select c.txn_type as [Loại giao dịch],sum (c.txn_amount) as [ tong so tien ] from customer_transactions as c 
group by c.txn_type 
--Thống kê mỗi tháng có bao nhiêu khách hàng của Data Bank thực hiện nhiều hơn 1 lần gửi tiền 
--và 1 lần mua hàng hoặc 1 lần rút tiền trong một tháng 
with giaodich as (
select c.customer_id,year(c.txn_date) as [năm],month (c.txn_date) as [tháng],
	sum (case when c.txn_type = N'deposit' then 1 else 0 end) as lan_gui,
	sum (case when c.txn_type =N'withdrawal' then 1 else 0 end) as lan_rut,
	sum (case when c.txn_type =N'purchase' then 1 else 0 end) as lan_mua
	from customer_transactions as c  
	group by c.customer_id,year(txn_date) ,month (txn_date)
	)
select [năm],[tháng], count (*) as [só khách hàng]
from giaodich 
where lan_gui > 1 and (lan_mua >=1 or lan_rut >1)
group by [năm],[tháng]
 --Tổng số tiền gửi và số lượng tiền gửi trung bình trong lịch sử 
 --của tất cả khách hàng là bao nhiêu?
 select sum (c.txn_amount) as [tong tien],avg (c.txn_amount) as [so tien trung binh]
 from customer_transactions as c 
 where c.txn_type = N'deposit'
--Biến động số dư khách hàng sau mỗi giao dịch 
select customer_id as [mã khách hàng],txn_date as [ngày giao dịch],
txn_type as [loại giao dịch],txn_amount as [số tiền],
sum(case 
when txn_type = 'deposit' then txn_amount
when txn_type in ('withdrawal', 'purchase') then -txn_amount
else 0
end) over (partition by customer_id order by txn_date) AS [biến động số dư] 
from customer_transactions


--Số dư khách hàng vào cuối tháng 
-- Tạo một bảng mới "giao dịch"
select customer_id,txn_date,txn_type,txn_amount,
sum(case 
when txn_type = 'deposit' then txn_amount
when txn_type in ('withdrawal', 'purchase') then -txn_amount
else 0 end) over (partition by customer_id order by txn_date) as giao_dich
into giaodich
from customer_transactions;
--Tính số dư 
with giao_dich_cuoi as (
select customer_id,year (txn_date) as [năm],month (txn_date) as [tháng],max(txn_date) as ngaycuoi 
from giaodich
group by customer_id,year (txn_date),month (txn_date)
)
select r.customer_id as [mã khách hàng], l.[tháng], l.[năm], r.giao_dich as [số dư cuối tháng]
from giaodich r
inner join giao_dich_cuoi as l on r.customer_id = l.customer_id 
and r.txn_date=l.ngaycuoi
--trung bình số dư trong 30 ngày
select a.customer_id as [mã khách hàng], month(a.txn_date) as[tháng], year(a.txn_date) as [năm],
avg(a.giao_dich) as [trung binh tháng] 
from giao_dich as a 
group by a.customer_id,month(a.txn_date) ,year(a.txn_date)

--Thống kê số dư và số lần giao dịch của khách hàng
select a.customer_id, month(a.txn_date) as [tháng],min(a.giao_dich)as [số dư thấp nhất],
max(a.giao_dich) as[số dư cao nhất],count(a.txn_date) as [số lần giao dịch]
from giaodich as a
group by a.customer_id,month (a.txn_date)