--УЧТИТЕ, ЧТО ДЛЯ СОЗДАНИЯ ПРОЦЕДУРЫ ИЛИ ФУНКЦИИ ПЕРЕД ЕЕ ИМЕНЕМ ВАМ НЕОБХОДИМО УКАЗАТЬ СВОЮ СХЕМУ БД. НАПРИМЕР:
--CREATE OR REPLACE FUCTION ivanovii_sch.add_numbers(a integer, b integer)
--Удаление функции производится следующей командой drop function ivanovii_sch.add_numbers;
--Учтите тот факт, что для PostgreSQL функции ivanovii_sch.add_numbers(a integer, b integer) и ivanovii_sch.add_numbers(a integer, b integer, с integer)
--являются разными функциями, так как у них различный набор аргументов. Аналогично с процедурами.


--исполняемый блок PL/pgSQL ,который можно использовать для тестирования будущей процедуры/функции
DO $$
BEGIN
    RAISE NOTICE 'Hello, PL/pgSQL!';
END;
$$ LANGUAGE plpgsql;

--синтаксис функции
CREATE OR REPLACE FUNCTION имя_функции(параметры) 
--имя функции может быть любым, но не должно совпадать с существующими системными функциями и, желательно, пользовательскими
--в параметрах функции может быть сколько угодно аргументов, после каждого из них обязательно указывается тип данных аргумента
RETURNS тип_возвращаемого_значения AS $$
-- обязательно необходимо указать тип возвращаемого значения. Тип может быть любым, который поддерживает СУБД
-- функция может не возвращать значений, тогда тип возвращаемого значения указвыается каак VOID
DECLARE
    -- объявление переменных. Переменные указываются ИМЯ ТИП (some_variable INTEGER). Если необходимо сразу инициализировать переменную (присвоить значение),
    -- то можно использовать слеующий синтаксис some_variable INTEGER := 0;
BEGIN
    -- тело функции
    -- здесь указываются все операции, которые необходимо выполнить функции. Это могут быть операции SELECT, UPDATE, DELETE, INSERT. 
    -- каждая операция отделяется символом "точка с запятой" - ;
    RETURN значение; -- если указан тип возвращаемого значения, то необходимо в эту иструкцию передать переменную или операцию, которая вернет
    --необходимое значение. В случае, когда тип возвращаемого значения указан как VOID, то блок RETURN не указывается.
END;
$$ LANGUAGE plpgsql;


--функция, которая принимает 2 аргумента и возвращает их сумму
--drop function if exists add_numbers;
CREATE FUNCTION add_numbers(a INTEGER, b INTEGER)
RETURNS INTEGER AS $$ --тип возвращаемого значения INTEGER
BEGIN
    RETURN a + b; --инструкция, которая указывает значение, которое должна вернуть функция
END;
$$ LANGUAGE plpgsql;

--функции в PL/pgSQL могут возвращать любые значения, которые поддерживает PostgreSQL
--drop function if exists get_name();
-- Текст
CREATE OR REPLACE FUNCTION get_name() 
RETURNS TEXT AS $$
BEGIN
    RETURN 'John Doe';
END;
$$ LANGUAGE plpgsql;

select get_name();

--drop function if exists get_current_date();
-- Дата
CREATE OR REPLACE FUNCTION get_current_date() 
RETURNS DATE AS $$
BEGIN
    RETURN CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

select get_current_date();

--drop function if exists is_active();
-- Булево значение
CREATE OR REPLACE FUNCTION is_active() 
RETURNS BOOLEAN AS $$
BEGIN
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

select is_active();

--ВАЖНОЕ ЗАМЕЧАНИЕ! Если функция возвращает ОДНО значение (чило, текстовая строка, дата и т.д), то функция указывается в блоке SELECT
--Если функция возвращает строку, несколько строк, таблицу или имеет OUT- параметры, то вызов функции указывается в блоке FROM

--drop function if exists get_customer;
-- Возврат строки из таблицы
CREATE OR REPLACE FUNCTION get_customer(cus_id INTEGER) 
RETURNS public.customers AS $$ -- в случае, когда возвращается строка, то необходимо указывать в типе возвращаемого значение таблицу, из которой будет возвращаться строка
DECLARE
    cus_record public.customers%ROWTYPE; --переменной, в которую будет записана строка необходимо указать тип <таблица из которой возвращаем строку>%ROWTYPE
BEGIN
    SELECT * --забираем все столбцы
    INTO cus_record --и записываем в переменную, которую создали
    FROM public.customers --из таблицы, которую указывали ранее
    WHERE id = cus_id; --фильтруем, в нашем случае, по идентификатору покупателя, так как  cus_id - входной параметр функции
    RETURN cus_record; -- возвращаем значение переменной, в которую записали нашу строку
END;
$$ LANGUAGE plpgsql;

-- Использование
SELECT * FROM public.get_customer(123);


--drop function if exists get_active_employees;
-- Возврат нескольких строк
CREATE OR REPLACE FUNCTION get_active_stores() 
RETURNS SETOF public.stores AS $$ --если необходимо вернуть несколько строк, то в типе возвращаемого значения будем указывать SETOF <таблица из которой возвращаем строку>
BEGIN
    RETURN QUERY --в блоке RETURN указываем, что необходимо вернуть результаты запроса с помощью RETURN QUERY
    SELECT * FROM stores WHERE close_dt is null; 
END;
$$ LANGUAGE plpgsql;

-- Использование
SELECT * FROM get_active_stores();

--drop function if exists get_customer_names;
--таблица
CREATE OR REPLACE FUNCTION get_customer_names() 
--иногда необходимо вернуть целую таблицу, а значит можно указать в типе возвращаемого значения ключевое слово TABLE и структуру возвращаемой таблицы
RETURNS TABLE (
    first_name varchar(100),
    last_name varchar(100),
    cnt bigint
) AS $$
BEGIN
    RETURN QUERY --возврат таблицы происходит через RETURN QUERY
    SELECT e.first_name, e.last_name, count(*) FROM customers e group by 1,2;
END;
$$ LANGUAGE plpgsql;

select * from get_customer_names(); 

--функция с OUT-параметрами
--drop function if exists calculate_stats;
CREATE OR REPLACE FUNCTION calculate_stats(
    IN cname varchar(50), --это входной параметр, который мы передаем функции
    OUT sum INT, --в данной функции мы указываем параметры, которые будут возвращены функцией, их не нужно указываеть при вызове функции
    OUT cnt INT,
    OUT average DECIMAL
) AS $$
BEGIN
    select sum(t.cheque_sum), count(*), avg(t.cheque_sum) --считаем необходимые метрики 
    into sum, cnt, average --записываем их в наши OUT -параметры, которые функция самостоятельно нам вернет
    from public.transactions t
	join customers c
		on c.id = t.customer_id
	where c.first_name = cname;
END;
$$ LANGUAGE plpgsql;

-- Использование
SELECT * FROM calculate_stats('Спартак');
SELECT * FROM calculate_stats('Ольга');
SELECT * FROM calculate_stats('Леонид');
SELECT * FROM calculate_stats('Архип3');

create table <your_schema>.logs(message text, created_at timestamp)

--пример функции, которая не возвращает значение
CREATE OR REPLACE FUNCTION log_message(message TEXT) 
RETURNS VOID AS $$
BEGIN
    --функционал функции таков, что она ничего не вычисляет, а только записывает некую строку в таблицу
    --поэтому ей нет необходимости что-либо возвращать
    INSERT INTO <your_schema>.logs(message, created_at) VALUES (message, NOW()); 
    --но мы можем просигнализировать пользователю, что функция отработала с помощью сообщения
    RAISE NOTICE 'Функция завершила свою работу!';
END;
$$ LANGUAGE plpgsql;

select log_message('Hello, world!');

select * from <your_schema>.logs;

--#####################################
--синтаксис создания процедуры
CREATE OR REPLACE PROCEDURE имя_процедуры(параметры) --в первой строке все аналогично функции
--так как процедуры не возвращают значения, то соответствующей строки нет
AS $$
BEGIN
    -- тело процедуры, в котором указывается все, что необходимо выполнить
END;
$$ LANGUAGE plpgsql;


--drop table if exists <your_schema>.customers;
create table <your_schema>.customers as
select * from customers;

--рассмотрим процедуру обновления имени пользователя
CREATE OR REPLACE PROCEDURE update_name(
    cus_id INTEGER, --входные параметры указываются аналогично функциям
    new_name varchar(50)
) AS $$
BEGIN
    UPDATE <your_schema>.customers SET first_name = new_name WHERE id = cus_id;
    COMMIT; --служит для подстверждения внесенных изменений
END;
$$ LANGUAGE plpgsql;

-- Вызов процедуры
CALL update_name(1, 'Артем');
select * from <your_schema>.customers where id = 1;

--drop table if exists  <your_schema>.grades;
create table <your_schema>.grades (
	student_id int4,
	subject varchar(50),
	final_grade varchar(2)
);

--создадим таблицу с оценками студентов и укажем в оценках пустые значения, для того, чтоб позже их заполнить
INSERT INTO <your_schema>.grades (student_id, subject, final_grade) VALUES
(1, 'Математика', null),
(1, 'Физика', null),
(2, 'Математика', null),
(2, 'История', null),
(3, 'Химия',  null),
(3, 'Биология',  null),
(4, 'Литература', null),
(4, 'Английский язык', null),
(5, 'Информатика',  null),
(5, 'Физика',  null);

--создадим процедуру, которая считывает количество баллов, набранных студентом и переводит их в оценку
--drop procedure if exists set_grade;
CREATE OR REPLACE PROCEDURE set_grade(score INTEGER, subject_ Varchar(50), user_id INTEGER)
AS $$
DECLARE
    grade VARCHAR(2); --создадим перемунную, в которую будем записывать оценку
BEGIN
    --с помощью условного оператора вычислим оценку, соответствующую набранным баллам
    IF score >= 90 THEN
        grade := 'A';
    ELSIF score >= 80 THEN
        grade := 'B';
    ELSIF score >= 70 THEN
        grade := 'C';
    ELSE
        grade := 'F';
    END IF; --обязяательно закрываем условный блок
    UPDATE 
		<your_schema>.grades 
	set final_grade = grade --записываем нашему студенту оценку
	where student_id = user_id
	and subject = subject_;
END;
$$ LANGUAGE plpgsql;

call set_grade(70, 'Физика', 1);
select * from <your_schema>.grades;

student_id|subject        |final_grade|
----------+---------------+-----------+
         1|Математика     |A          |
         1|Физика         |C          |

--создадим таблицу для записи в нее чисел
--drop table if exists <your_schema>.numbers_table;
create table <your_schema>.numbers_table (
	id int
);

--создадим процедуру для генерации и записи чисел в созданную таблицу
CREATE OR REPLACE PROCEDURE generate_numbers(
    start_num INTEGER, --число с которого начинается генерация
    end_num INTEGER --число на котором заканчивается генерация
    )
AS $$
DECLARE
    current_num INTEGER; --объявляем переменную, чтоб отслеживать текущее генерируемое значение 
BEGIN
    current_num := start_num; --присваиваем стартовое значение 
    LOOP --запускаем цикл
        EXIT WHEN current_num > end_num; --обязательно указываем условие, при срабатывании которого цикл должен завершиться
        -- Вставляем число в таблицу
        INSERT INTO <your_schema>.numbers_table(id) VALUES (current_num);
        RAISE NOTICE 'Добавлено число: %', current_num; --сигнализируем о вставке числа в таблицу
        current_num := current_num + 1; --увеличиваем текущее число на единицу
    END LOOP;
    RAISE NOTICE 'Генерация завершена';
END;
$$ LANGUAGE plpgsql;

call generate_numbers(10,20);

select * from <your_schema>.numbers_table ;

--создадим таблицу с лицевыми счетами некоторых людей и некоторым количеством денег
--drop table if exits <your_schema>.accounts;
create table <your_schema>.accounts (
	id int4,
	last_name varchar(50),
	balance integer
);

INSERT INTO <your_schema>.accounts (id, last_name, balance) VALUES
(1, 'Иванов', 15000),
(2, 'Петров', 23450),
(3, 'Сидоров', 8900),
(4, 'Кузнецов', 156700),
(5, 'Смирнов', 4500),
(6, 'Попов', 12800),
(7, 'Лебедев', 95000),
(8, 'Козлов', 3200),
(9, 'Новиков', 18700),
(10, 'Морозов', 54300);

--создадим функцию, которая переводит деньги со счета одного клиента на счет другого
CREATE OR REPLACE PROCEDURE transfer_funds(--перевод денег
    from_account INTEGER, --от одного клиента
    to_account INTEGER, --другому клиенту
    amount NUMERIC --сумма для перевода
    ) AS $$
DECLARE 
    cus_id INTEGER := NULL; --заранее определяем значение переменной
BEGIN
    --далее будем проводит проверку на неверные введеные данные и генерировать ошибку
    -- Проверка входных данных
    IF amount <= 0 THEN --если сумма перевода 0 или отрицательная, то перевод невозможен
        RAISE EXCEPTION 'Сумма перевода должна быть положительной';
    END IF;
    
    IF from_account = to_account THEN -- перевести самому себе мы тоже не можем
        RAISE EXCEPTION 'Нельзя переводить средства на тот же счет';
    END IF;
    
    -- Выполнение перевода
    UPDATE <your_schema>.accounts SET balance = balance - amount WHERE id = from_account;
    UPDATE <your_schema>.accounts SET balance = balance + amount WHERE id = to_account;
    
    -- Проверка отрицательного баланса
    SELECT id INTO cus_id FROM <your_schema>.accounts WHERE balance < 0 LIMIT 1; --если нашли, что у клиента недостаточно денег для перевода
    IF cus_id IS NOT NULL THEN --то генерируем ошибку, что наш клиент неплатжеспособен и откатывем перевод
        RAISE EXCEPTION 'Транзакция не может быть совершена, недостаточно денег на счету пользователя id = %', cus_id;
    END IF;
    
EXCEPTION --в случае возникновения других ошибок, которые мы не предусмотрели можем генерировать ошибку и выводить сообщение
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ошибка перевода: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;



 