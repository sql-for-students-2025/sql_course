5.6 Посчитать уникальное количество пользователей,
которые совершили покупки не менее чем на 50000 рублей за последние 4 месяца.
Подсказка: FROM, INTERVAL.

select
	*
from
	public.transactions t 
limit 10

select
	count(distinct c.id)
from
	public.customers c 
where
	c.id in (
		select
			t.customer_id 
		from
			public.transactions t 
		where
			t.dt >= now() - interval '4' month
			--and t.cheque_sum >= 50000
		group by
			t.customer_id 
		having
			sum(t.cheque_sum) >= 50000
	)
;


select current_timestamp


5.1 Найти товары (вывести id), цена которых выше средней цены в своей категории.

select
	p.id
from
	public.products p
where
	p.price > (
		select
			avg(p2.price )
		from
			public.products p2
		where
			p.category_id = p2.category_id
	)
;

5.4 Вывести 5 наибольших по сумме транзакций за последние 5 месяцев. В выводе должны присутстовать id транзакции, название магазина, в котором была совершена покупка. Подсказка: SELECT, INTERVAL.

select
	t.id,
	(
		select distinct
			"name" 
		from
			public.stores
		where
			id = t.store_id 
	)
from
	public.transactions t 
where
	t.dt >= now() - interval '5' month
order by
	t.cheque_sum desc
limit 5
;