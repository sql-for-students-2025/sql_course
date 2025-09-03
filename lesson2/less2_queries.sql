select 1;

select 2+1;

select birth_dt, first_name, last_name from public.customers;

select * from public.customers where id > 1;

select * from public.customers where id between 1 and 5;

select * from public.customers where id between 7 and 0;

select * from public.customers where email like '%2025%';

select first_name from public.customers where gender != 1

select * from public.customers where last_name  like 'Шуб%';

--однострочный комментарий

/*
многострочный 
комментарий
*/