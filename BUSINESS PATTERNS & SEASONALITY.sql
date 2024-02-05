-- ------------------------------------------------------BUSINESS PATTERNS & SEASONALITY--------------------------------------------------------------------------------

-- ANALYZING SEASONALITY
select 
	year(website_sessions.created_at) as years,
    month(website_sessions.created_at) as months,
    week(website_sessions.created_at) as weeks,
    day(website_sessions.created_at) as dates,
    min(date(website_sessions.created_at)) as start_of_week,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders
from website_sessions
	left join orders
		on orders.website_session_id = website_sessions.website_session_id
where website_sessions.created_at < '2013-01-01'
group by 1,2,3,4;


--  ANALYZING BUSINESS PATTERNS
SELECT
    hr,
    ROUND(AVG(CASE WHEN week_of_day = 0 THEN sessions ELSE NULL END), 1) AS Monday,
    ROUND(AVG(CASE WHEN week_of_day = 1 THEN sessions ELSE NULL END), 1) AS Tuesday,
    ROUND(AVG(CASE WHEN week_of_day = 2 THEN sessions ELSE NULL END), 1) AS Wednesday,
    ROUND(AVG(CASE WHEN week_of_day = 3 THEN sessions ELSE NULL END), 1) AS Thursday,
    ROUND(AVG(CASE WHEN week_of_day = 4 THEN sessions ELSE NULL END), 1) AS Friday,
    ROUND(AVG(CASE WHEN week_of_day = 5 THEN sessions ELSE NULL END), 1) AS Saturday,
    ROUND(AVG(CASE WHEN week_of_day = 6 THEN sessions ELSE NULL END), 1) AS Sunday
FROM (
    SELECT
        DATE(created_at) AS created_date,
        WEEKDAY(created_at) AS week_of_day,
        HOUR(created_at) AS hr,
        COUNT(DISTINCT website_session_id) AS sessions
    FROM website_sessions
    WHERE created_at BETWEEN '2012-09-15' AND '2012-11-15'
    GROUP BY 1, 2, 3
) AS daily_hourly_session
GROUP BY hr;







































































