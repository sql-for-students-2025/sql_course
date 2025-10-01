--1 Найти уникальные идентификаторы городов, в которых уникальное количество покупателей 
--за последние 5 месяцев без последних двух месяцев составляет от 30 тыс и больше.
select city_id from (
select s.city_id , count(distinct customer_id) uniq_cus
from public.transactions t
join public.stores s
	on t.store_id = s.id
where t.dt::date between now()::date - interval '5' month and now()::date - interval '2' month
group by 1
having count(distinct customer_id) >= 30000
)


select
	s.city_id
from
	public.transactions t 
join public.stores s on
	s.id = t.store_id 
where
	t.dt >= current_date - interval '5' month
	and t.dt < current_date - interval '2' month
group by
	s.city_id
having 
	count(distinct t.customer_id) >= 30000
	

--2
select 
	c."name" ,
	count(*)
from products p
join categories c 
	on p.category_id = c.id
where 1=1
	and p.unit = 'кг'
	and p.price <= 40
group by 1


--3
select c."name", count(distinct td.id)
from transactions_details td 
join products p
	on p.id = td.art_id
join categories c 
	on p.category_id = c.id
where td.qnty = 1
group by 1

select
	c."name" ,
	count(distinct td.id)
from
	public.products p 
join public.transactions_details td on
	td.art_id = p.id
	and td.qnty = 1
join public.categories c on
	c.id = p.category_id 
group by
	c."name"
	
--4
select 
	b.name
from brands b 
join products p 
	on b.id = p.brand_id 
group by 1
order by max(p.price) 
limit 10

--5
select 
	c.gender,
	1.0*count(distinct t.id)/count(distinct c.id)
from transactions t  
join customers c
	on t.customer_id = c.id 
where t.dt::date between '2025-02-01' and '2025-03-14'
group by 1

select
	c.gender,
	(count(distinct t.id)::float) / count(distinct c.id)
from
	public.customers c 
join public.transactions t on
	t.customer_id = c.id
	and t.dt >= '2025-02-01'
	and t.dt < '2025-03-15'
group by
	c.gender
	
--6

select 
	s.city_id,
	1.0*count(t.id)/count(distinct s.id)
from stores s 
left join transactions t
	on t.store_id = s.id 
	and t.dt::date >= '2025-04-01'
where 1=1
	and s.close_dt is null
group by 1

--7

select
	c."name" ,
	1.0*sum(td.qnty ) / max(sq.all_qnty)
from
	public.categories c 
join public.products p on
	p.category_id = c.id 
join public.transactions_details td on
	td.art_id = p.id 
join (
		select
			sum(qnty) as all_qnty
		from
			public.transactions
		where dt >= '2025-03-01'
	) sq on 1 = 1
where 1=1
	and td.dt >= '2025-03-01'
group by 1


--8

select 
	extract(year from s.open_dt),
	avg(s.square) avg_sqr,
	min(s.open_dt) open_dt,
	count(distinct s.city_id)
from  stores s
join store_frmt sf 
	on sf.id = s.frmt 
where 1=1
	and sf."name" = 'hypermarket'
	and (s.close_dt::date >= '2025-07-01' or s.close_dt is null)
group by 1

--9

select 
	s.city_id,
	count(distinct td.art_id),
	sum(td.qnty) / count(distinct td.store_id) asdas
from transactions_details td
join stores s 
	on td.store_id = s.id
where dt::date between '2025-04-01' and '2025-05-31'
group by 1
order by asdas desc
limit 5


--10

select distinct
	b."name" 
from products p
join brands b 
	on p.brand_id = b.id
left join transactions_details td
	on p.id = td.art_id 
	and dt::date between '2025-03-01' and '2025-03-15'
where td.id is null

--11

select 
	s.city_id,
	c."name",
	sum(td.qnty)
from transactions_details td 
join stores s
	on s.id = td.store_id 
join products p 
	on p.id = td.art_id 
join categories c
	on c.id = p.category_id 
where 1=1
	and dt::date between '2025-04-01' and '2025-04-20'
group by 1,2
order by 3 desc
limit 10;