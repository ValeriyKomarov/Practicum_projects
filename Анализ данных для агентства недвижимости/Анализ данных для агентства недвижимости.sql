-- Задача 1: Время активности объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. Какие сегменты рынка недвижимости Санкт-Петербурга и городов Ленинградской области 
--    имеют наиболее короткие или длинные сроки активности объявлений?
-- 2. Какие характеристики недвижимости, включая площадь недвижимости, среднюю стоимость квадратного метра, 
--    количество комнат и балконов и другие параметры, влияют на время активности объявлений? 
--    Как эти зависимости варьируют между регионами?
-- 3. Есть ли различия между недвижимостью Санкт-Петербурга и Ленинградской области по полученным результатам?

WITH limits AS (SELECT
	PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_area) AS perc_total_area,
	PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS perc_rooms,
	PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS perc_balcony,
	PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS perc_ceiling_height,
	PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS perc_ceiling_height_1
FROM real_estate.flats),
filtered_id AS (
	SELECT id
	FROM real_estate.flats
	WHERE
		total_area < (SELECT perc_total_area FROM limits)
		AND (rooms < (SELECT perc_rooms FROM limits) OR rooms IS NULL)
		AND (balcony < (SELECT perc_balcony FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT perc_ceiling_height FROM limits)
            AND ceiling_height > (SELECT perc_ceiling_height_1 FROM limits)) OR ceiling_height IS NULL)
	),
base_flats AS (SELECT *
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id)
),
base_flats_filter AS (SELECT
	base_flats.id,
	total_area,
	rooms,
	balcony,
	ceiling_height,
	floor,
	CASE
		WHEN city = 'Санкт-Петербург'
		THEN 'Санкт-Петербург'
		WHEN city != 'Санкт-Петербург'
		THEN 'ЛенОбл'
	END AS "Город",
		CASE
		WHEN days_exposition >=1 AND days_exposition <=30
		THEN 'месяц'
		WHEN days_exposition >=31 AND days_exposition <=90
		THEN 'квартал'
		WHEN days_exposition >=91 AND days_exposition <=180
		THEN 'полгода'
		WHEN days_exposition >=181
		THEN 'больше полугода'
		WHEN days_exposition IS NULL
		THEN 'не проданные объекты'
	END AS "Сегмент активности",
	last_price / total_area AS price_for_1_meter
FROM base_flats
LEFT JOIN real_estate.city ON base_flats.city_id = city.city_id
LEFT JOIN real_estate.advertisement ON base_flats.id = advertisement.id
LEFT JOIN real_estate.type ON base_flats.type_id = type.type_id
WHERE type.type = 'город'
)
SELECT
	"Город",
	"Сегмент активности",
	COUNT (base_flats_filter.id) AS "Количество объявлений",
	ROUND (COUNT (base_flats_filter.id)::numeric / (WITH limits AS (SELECT
	PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_area) AS perc_total_area,
	PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS perc_rooms,
	PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS perc_balcony,
	PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS perc_ceiling_height,
	PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS perc_ceiling_height_1
FROM real_estate.flats),
filtered_id AS (
	SELECT id
	FROM real_estate.flats
	WHERE
		total_area < (SELECT perc_total_area FROM limits)
		AND (rooms < (SELECT perc_rooms FROM limits) OR rooms IS NULL)
		AND (balcony < (SELECT perc_balcony FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT perc_ceiling_height FROM limits)
            AND ceiling_height > (SELECT perc_ceiling_height_1 FROM limits)) OR ceiling_height IS NULL)
	) SELECT COUNT (real_estate.flats.id)
	FROM real_estate.flats
	LEFT JOIN real_estate.city ON real_estate.flats.city_id = city.city_id
LEFT JOIN real_estate.advertisement ON real_estate.flats.id = advertisement.id
LEFT JOIN real_estate.type ON real_estate.flats.type_id = type.type_id
	WHERE city != 'Санкт-Петербург' AND type.type = 'город' AND real_estate.flats.id IN (SELECT * FROM filtered_id)), 3)*100 AS "Доля объявлений в процентах",
	ROUND ((AVG(price_for_1_meter)::NUMERIC), 2) AS "Средняя стоимость кв.метра",
	ROUND ((AVG(total_area)::NUMERIC), 2) AS "Средняя площадь",
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rooms) AS "Медиана количества комнат",
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY balcony) AS "Медиана количества балконов",
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY floor) AS "Медиана этажности"
FROM base_flats_filter
WHERE "Город" != 'Санкт-Петербург'
GROUP BY "Город", "Сегмент активности"
UNION ALL
SELECT
	"Город",
	"Сегмент активности",
	COUNT (base_flats_filter.id) AS "Количество объявлений",
	ROUND (COUNT (base_flats_filter.id)::numeric / (WITH limits AS (SELECT
	PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_area) AS perc_total_area,
	PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS perc_rooms,
	PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS perc_balcony,
	PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS perc_ceiling_height,
	PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS perc_ceiling_height_1
FROM real_estate.flats),
filtered_id AS (
	SELECT id
	FROM real_estate.flats
	WHERE
		total_area < (SELECT perc_total_area FROM limits)
		AND (rooms < (SELECT perc_rooms FROM limits) OR rooms IS NULL)
		AND (balcony < (SELECT perc_balcony FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT perc_ceiling_height FROM limits)
            AND ceiling_height > (SELECT perc_ceiling_height_1 FROM limits)) OR ceiling_height IS NULL)
	) SELECT COUNT (real_estate.flats.id)
	FROM real_estate.flats
	LEFT JOIN real_estate.city ON real_estate.flats.city_id = city.city_id
LEFT JOIN real_estate.advertisement ON real_estate.flats.id = advertisement.id
LEFT JOIN real_estate.type ON real_estate.flats.type_id = type.type_id
	WHERE city = 'Санкт-Петербург' AND type.type = 'город' AND real_estate.flats.id IN (SELECT * FROM filtered_id)), 3)*100 AS "Доля объявлений в процентах",
	ROUND ((AVG(price_for_1_meter)::NUMERIC), 2) AS "Средняя стоимость кв.метра",
	ROUND ((AVG(total_area)::NUMERIC), 2) AS "Средняя площадь",
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rooms) AS "Медиана количества комнат",
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY balcony) AS "Медиана количества балконов",
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY floor) AS "Медиана этажности"
FROM base_flats_filter
WHERE "Город" = 'Санкт-Петербург'
GROUP BY "Город", "Сегмент активности"
ORDER BY "Город", "Сегмент активности";

-- Выводы:
/*
Для Санкт-Петербурга:
- Наиболее короткие сроки активности объявлений (1-30 дней) имеют 2-комнатные квартиры с 1 балконом на 5 этаже, средняя площадь 54.38 кв.м, средняя стоимость 110568,88 руб./кв.м.
- Наиболее длинные сроки активности (>181 дня) имеют 2-комнатные квартиры с 1 балконом на 5 этаже, средняя площадь 66,15 кв.м, средняя стоимость 115457,22 руб./кв.м.
- Максимальная доля объявлений приходится на сегмент больше полугода – 28%, минимальная на не проданные объекты – 12,1%.

Для Ленинградской области:
- Краткосрочные объявления (1-30 дней) — 2-комнатные квартиры с 1 балконом на 4 этаже, средняя площадь 48,72 кв.м, средняя стоимость 73275,25 руб./кв.м.
- Долгосрочные объявления (>181 дня) — 2-комнатные квартиры с 1 балконом на 3 этаже, средняя площадь 55,41 кв.м, средняя стоимость 68297,22 руб./кв.м.
- Максимальная доля объявлений в сегменте квартал – 28,5%, минимальная в сегменте месяц – 12,3%.

Влияние на время активности объявлений оказывают средняя стоимость кв. метра и средняя площадь квартиры:
- В Санкт-Петербурге цена колеблется от 110568,88 до 115457,22 руб./кв.м, площадь от 54,38 до 66,15 кв.м.
- В Ленинградской области цена — от 67573,43 до 73275,25 руб./кв.м, площадь — от 48,72 до 55,41 кв.м.

Различия между недвижимостью СПб и Лен. области:
- Средняя стоимость кв. метра значительно выше в СПб в сравнении с Лен. областью.
- Средняя площадь квартир в СПб больше по сравнению с Лен. областью.
- Медиана этажности выше в СПб — 5 этаж, в Лен. области — 3 этаж.
*/

WITH limits AS (SELECT
	PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_area) AS perc_total_area,
	PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS perc_rooms,
	PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS perc_balcony,
	PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS perc_ceiling_height,
	PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS perc_ceiling_height_1
FROM real_estate.flats),
filtered_id AS (
	SELECT id
	FROM real_estate.flats
	WHERE
		total_area < (SELECT perc_total_area FROM limits)
		AND (rooms < (SELECT perc_rooms FROM limits) OR rooms IS NULL)
		AND (balcony < (SELECT perc_balcony FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT perc_ceiling_height FROM limits)
            AND ceiling_height > (SELECT perc_ceiling_height_1 FROM limits)) OR ceiling_height IS NULL)
	),
base_flats AS (SELECT *
FROM real_estate.flats
INNER JOIN real_estate.advertisement ON flats.id = advertisement.id
INNER JOIN real_estate.type ON flats.type_id = type.type_id
WHERE flats.id IN (SELECT * FROM filtered_id) AND type.type = 'город'
),
month_base_flats AS (SELECT *,
EXTRACT (MONTH FROM first_day_exposition) AS month_first_day,
EXTRACT (MONTH FROM (first_day_exposition + (days_exposition * INTERVAL '1 day'))) AS month_close_day
FROM base_flats
WHERE (EXTRACT (YEAR FROM first_day_exposition)) >= 2015 AND (EXTRACT (YEAR FROM first_day_exposition)) <= 2018 AND
	  (EXTRACT (YEAR FROM (first_day_exposition + (days_exposition * INTERVAL '1 day')))) >= 2015 AND (EXTRACT (YEAR FROM (first_day_exposition + (days_exposition * INTERVAL '1 day')))) <= 2018
),
month_base_first AS (SELECT
AVG (last_price / total_area) AS avg_first_price,
AVG (total_area) AS avg_first_total_area,
month_first_day,
COUNT (month_first_day) AS count_month_first_day,
RANK () OVER (ORDER BY COUNT (month_first_day) DESC) AS count_month_first_day_rank
FROM month_base_flats
GROUP BY month_first_day
ORDER BY month_first_day
),
month_base_close AS (SELECT
AVG (last_price / total_area) AS avg_last_price,
AVG (total_area) AS avg_last_total_area,
month_close_day,
COUNT (month_close_day) AS count_month_close_day,
RANK () OVER (ORDER BY COUNT (month_close_day) DESC) AS count_month_close_day_rank
FROM month_base_flats
WHERE month_close_day IS NOT NULL
GROUP BY month_close_day
ORDER BY month_close_day
)
SELECT
month_first_day,
count_month_first_day,
count_month_close_day,
count_month_first_day_rank,
count_month_close_day_rank,
ROUND (avg_first_price::NUMERIC, 2) AS avg_first_price,
ROUND (avg_last_price::numeric, 2) AS avg_last_price,
ROUND (avg_first_total_area::NUMERIC, 2) AS avg_first_total_area,
ROUND (avg_last_total_area::NUMERIC, 2) AS avg_last_total_area
FROM month_base_first
INNER JOIN month_base_close ON month_base_first.month_first_day = month_base_close.month_close_day
ORDER BY month_first_day;

-- Выводы:
/*
- Наибольшая активность в публикации объявлений о продаже недвижимости наблюдается в феврале – 1246 объявлений, ноябре – 1181 объявление и сентябре – 1140 объявлений.
- Наибольшая активность в снятии объявлений о продаже недвижимости наблюдается в октябре – 1360 объявлений, ноябре – 1301 объявлений и сентябре – 1238 объявлений.
- Периоды активной публикации объявлений и периоды, когда происходит повышенная продажа недвижимости совпадают в ноябре и сентябре.
- Наибольшая активность в публикации объявлений отмечается в конце зимы, когда средняя стоимость квадратного метра достигает 101789 рублей, а средняя площадь квартиры – 58.75 кв. метров.
- Также высокая активность наблюдается осенью, когда средняя стоимость квадратного метра варьируется от 102030 до 106684 рублей, а средняя площадь квартиры – от 56.99 до 59.05 кв. метров.
- Наибольшая активность в снятии объявлений отмечается также осенью, когда средняя стоимость квадратного метра варьируется от 103791 до 104317 рублей, а средняя площадь квартиры – от 56.71 до 58.86 кв. метров.
*/

-- Задача 3: Анализ рынка недвижимости Ленобласти
-- Результат запроса должен ответить на такие вопросы:
-- 1. В каких населённые пунктах Ленинградской области наиболее активно публикуют объявления о продаже недвижимости?
-- 2. В каких населённых пунктах Ленинградской области — самая высокая доля снятых с публикации объявлений? 
--    Это может указывать на высокую долю продажи недвижимости.
-- 3. Какова средняя стоимость одного квадратного метра и средняя площадь продаваемых квартир в различных населённых пунктах? 
--    Есть ли вариация значений по этим метрикам?
-- 4. Среди выделенных населённых пунктов какие пункты выделяются по продолжительности публикации объявлений? 
--    То есть где недвижимость продаётся быстрее, а где — медленнее.

WITH limits AS (SELECT
	PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_area) AS perc_total_area,
	PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS perc_rooms,
	PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS perc_balcony,
	PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS perc_ceiling_height,
	PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS perc_ceiling_height_1
FROM real_estate.flats),
filtered_id AS (
	SELECT id
	FROM real_estate.flats
	WHERE
		total_area < (SELECT perc_total_area FROM limits)
		AND (rooms < (SELECT perc_rooms FROM limits) OR rooms IS NULL)
		AND (balcony < (SELECT perc_balcony FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT perc_ceiling_height FROM limits)
            AND ceiling_height > (SELECT perc_ceiling_height_1 FROM limits)) OR ceiling_height IS NULL)
	),
base_flats AS (SELECT
	city,
	days_exposition,
	flats.id,
	last_price,
	total_area,
	rooms,
	balcony,
	ceiling_height,
	floor,
	type
FROM real_estate.flats
LEFT JOIN real_estate.city ON real_estate.flats.city_id = city.city_id
LEFT JOIN real_estate.advertisement ON real_estate.flats.id = advertisement.id
LEFT JOIN real_estate.type ON real_estate.flats.type_id = type.type_id
WHERE flats.id IN (SELECT * FROM filtered_id)),
top_city AS (SELECT
	city AS "Населённый пункт",
	ROUND (AVG (days_exposition)) AS "Продолжительность публикаций",
	COUNT (base_flats.id) AS "Количество объявлений",
	ROUND (((COUNT (days_exposition)::float / COUNT (base_flats.id)))::numeric, 2) AS "Доля снятых с публикации",
	RANK () OVER (ORDER BY COUNT (base_flats.id) DESC) AS "Топ по количеству объявлений",
	ROUND ((AVG(last_price / total_area)::NUMERIC), 2) AS "Средняя стоимость кв.метра",
	ROUND ((AVG(total_area)::NUMERIC), 2) AS "Средняя площадь",
	ROUND ((AVG(rooms)::NUMERIC)) AS "Среднее количество комнат",
	ROUND ((AVG(balcony)::NUMERIC)) AS "Среднее количество балконов",
	ROUND ((AVG(floor)::NUMERIC)) AS "Среднее количество этажей"
FROM base_flats
WHERE city != 'Санкт-Петербург'
GROUP BY "Населённый пункт")
SELECT *
FROM top_city
WHERE "Топ по количеству объявлений" <=15
ORDER BY "Топ по количеству объявлений";

-- Выводы:
/*
Наиболее активно публикуют объявления о продаже недвижимости в следующих населённых пунктах Ленинградской области: 
в Мурино – 568 объявлений, в Кудрово – 463 объявления, Шушарах – 404 объявления и Всеволжске – 356 объявлений.

Самая высокая доля снятых с публикации объявлений в Мурино – 0,94, Кудрово – 0,94, Шушарах – 0,93 и Парголово – 0,93, 
что говорит о высокой доле продажи недвижимости.

Вариация значений по средней стоимости одного квадратного метра и средней площади продаваемых квартир присутствует. 
Самые высокие показатели средней стоимости кв. метра у следующих населённых пунктов: 
Пушкин – 104 158,94 за кв. метр, при средней площади квартир 59.74 кв. метров; 
Сестрорецк – 103 848,09 за кв. метр, при средней площади квартир 62.45 кв. метров; 
Кудрово – 95 420,47 за кв. метр, при средней площади квартир 46.20 кв. метров; 
Парголово – 90 272,96 за кв. метр, при средней площади квартир 51.34 кв. метров.

Самые высокие показатели средней продолжительности публикации у следующих населённых пунктов: 
Сестрорецк – 215 дней, Красное Село – 206 дней и Пушкин с Петергоф – 197 дней, 
что говорит о медленной продаже недвижимости в данных населённых пунктах.

Самые низкие показатели средней продолжительности публикации у следующих населённых пунктов: 
Колпино – 147 дней, Мурино – 149 дней, Шушары – 152 дня и Бугры – 156 дней, 
что говорит о быстрой продаже недвижимости в данных населённых пунктах.
*/

-- Общие выводы и рекомендации исследования рынка недвижимости:
/*
- Наиболее привлекательные сегменты для работы – двухкомнатные квартиры с одним балконом, расположенные на 4-5 этажах.
- В Санкт-Петербурге самые короткие сроки активности объявлений у двухкомнатных квартир с одним балконом на 5 этаже (средняя площадь 66,15 кв.м, средняя стоимость 115457.22 руб./кв.м).
  В Ленинградской области – у аналогичных квартир на 4 этаже.
- Средняя стоимость за квадратный метр, площадь квартиры и этажность влияют на продолжительность активности объявлений.
- Отличия между Санкт-Петербургом и Ленинградской областью присутствуют по средней стоимости кв.м, средней площади и медиане этажности.
- Пиковые месяцы публикации объявлений: февраль, сентябрь и ноябрь.
- Пиковые месяцы снятия объявлений: сентябрь, октябрь и ноябрь — совпадают с пиками продаж.
- Наибольшая активность публикаций в конце зимы, снятия — осенью.
- Активнее всего публикации в Ленобласти происходят в Мурино, Кудрово, Шушарах и Всеволожске.
- Высокая доля снятых объявлений (быстрая продажа) наблюдается в Мурино, Кудрово, Шушарах и Парголово.
- Высокая средняя стоимость кв.м зафиксирована в Сестрорецке, Кудрово и Парголово.
- Длительная средняя публикация объявлений (медленная продажа) в Сестрорецке, Красном Селе, Пушкине и Петергофе.
- Короткая средняя публикация объявлений (быстрая продажа) в Колпино, Мурино, Шушарах и Буграх.

Рекомендации:
- Фокусироваться на двухкомнатных квартирах с одним балконом на 4-5 этажах.
- Уделять внимание осеннему сезону, как периоду повышенной активности продавцов и покупателей.
- Обратить особое внимание на регионы Ленобласти с быстрой продажей и высокой долей снятых объявлений, например Мурино и Шушары.
*/