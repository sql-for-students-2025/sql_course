-- Создание временной таблицы для возрастных групп покупателей
/*
 Первым делом рассмотрим оператор CASE WHEN — это условный оператор, 
 который позволяет выполнять различные действия в зависимости от условий. Он похож на конструкцию if-else в других языках программирования.
 
 Синтаксис оператора:
 CASE
    WHEN условие1 THEN результат1
    WHEN условие2 THEN результат2
    ...
    ELSE результат_по_умолчанию
END

Например: Рассмотрим зарплаты сотрудников и разобьем их на условные группы:

SELECT 
    name, --имя сотрудника
    salary, -- зп сотрудника
    CASE 
        WHEN salary < 30000 THEN 'Низкая'
        WHEN salary BETWEEN 30000 AND 60000 THEN 'Средняя'
        ELSE 'Высокая'
    END AS salary_category -- условная группа
FROM employees;

   name  | salary | salary_category |  
 ------------------------------------
   Вася  |	28000 |		Низкая      |
 ------------------------------------
   Петя  |	35000 |		Средняя     |
 ------------------------------------
   Федя  |	65000 |		Высокая     |
 ------------------------------------
В случае, когда мы не указываем значение для ветки ELSE, т.е. 
	CASE 
        WHEN salary < 30000 THEN 'Низкая'
        WHEN salary BETWEEN 30000 AND 60000 THEN 'Средняя'
    END AS salary_category -- условная группа
То условный оператор всем значениям, которые не попали ни под одно условие проставит NULL.

  name  | salary | salary_category |  
 ------------------------------------
   Вася  |	28000 |		Низкая      |
 ------------------------------------
   Петя  |	35000 |		Средняя     |
 ------------------------------------
   Федя  |	65000 |		NULL        |
 ------------------------------------
 */

--Пример на таблице transactions
select 
	case 
		when qnty < 5 then '<5'
		when qnty >= 5 and qnty <= 10 then '5-10'
		when qnty > 10 and qnty <= 15 then '11-15'
	end qnty
from transactions

--Рассмотрим пример с врЕменной таблицей.
--Создадим таблицу с помощью запроса. В запросе соберем наших покупателей и каждому проставим возрастную группу
CREATE TEMPORARY TABLE customer_age_groups AS
SELECT 
    id,
    first_name,
    last_name,
    birth_dt,
    EXTRACT(YEAR FROM AGE(birth_dt)) AS age,
    CASE 
        WHEN EXTRACT(YEAR FROM AGE(birth_dt)) < 25 THEN '18-24'
        WHEN EXTRACT(YEAR FROM AGE(birth_dt)) < 35 THEN '25-34'
        WHEN EXTRACT(YEAR FROM AGE(birth_dt)) < 45 THEN '35-44'
        WHEN EXTRACT(YEAR FROM AGE(birth_dt)) < 55 THEN '45-54'
        ELSE '55+'
    END AS age_group
FROM customers
WHERE birth_dt IS NOT NULL;

--далее посмотрим результат того, что получилось
select * from customer_age_groups;

--теперь, когда у нас есть разбиение по возрастным группам мы можем посчитать какие различные метрики с использованием данных
--временной таблицы, которая была создана ранее. Например, посчитаем несколько метрик с учетом возрастной группы:
SELECT 
    cag.age_group,
    COUNT(DISTINCT cag.id) AS total_customers,
    COUNT(t.id) AS total_transactions,
    SUM(t.cheque_sum) AS total_revenue,
    ROUND(AVG(t.cheque_sum), 2) AS avg_cheque
FROM customer_age_groups cag
LEFT JOIN transactions t ON cag.id = t.customer_id
WHERE t.dt >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY cag.age_group
ORDER BY cag.age_group;
end;

--если вам необходимо создать временную таблицу заново или он вам больше не нужна, то ее можно удалить.
--модификатор if exists проверяет есть ли такая таблица и в зависимости от результата выполняет или не выполняет удаление.
--этот модификатор можно использовать для того, чтоб избежать получения ошибки, на случай, если вы пытаетесь удалить 
--несуществующую таблицу.
 
drop table if exists customer_age_groups;


--теперь рассмотрим СТЕ. Помним, что она существует только в момент запроса. Поэтому важно, чтоб все СТЕ были указаны до запроса 
--в котором они будут использованы. Помните, что нельзя создать СТЕ и неиспользовать его хотя бы одно из них в ОСНОВНОМ запросе. 
--В противном случае, вы получите ошибку.

WITH monthly_sales AS ( --возьмем продажи по месяцам за последний год
    SELECT 
        EXTRACT(MONTH FROM dt) AS month_number,
        TO_CHAR(dt, 'Month') AS month_name, --кстати, обратите внимание на функцию, которая поможет вытащить буквенное наименование месяца.
        COUNT(*) AS transaction_count,
        SUM(cheque_sum) AS total_revenue,
        AVG(cheque_sum) AS avg_cheque
    FROM transactions
    WHERE dt >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY EXTRACT(MONTH FROM dt), TO_CHAR(dt, 'Month')
),
monthly_customers AS ( --посчитаем покупателей, которые совершали покупки за последний год
    SELECT 
        EXTRACT(MONTH FROM dt) AS month_number,
        COUNT(DISTINCT customer_id) AS unique_customers
    FROM transactions
    WHERE dt >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY EXTRACT(MONTH FROM dt)
)
SELECT --ОСНОВНОЙ ЗАПРОС. Посчитаем какое количество выручки приходится на одного покупателя в месяц.
    ms.month_name,
    ms.transaction_count,
    ms.total_revenue,
    ms.avg_cheque,
    mc.unique_customers,
    ROUND(ms.total_revenue / mc.unique_customers, 2) AS revenue_per_customer
FROM monthly_sales ms
JOIN monthly_customers mc ON ms.month_number = mc.month_number
ORDER BY ms.month_number;