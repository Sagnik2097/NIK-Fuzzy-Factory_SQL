-- -----------------------------------------------------ANALYSIS FOR CHANNEL MANAGEMENT----------------------------------------------------------------------------
select 
	utm_content,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id) / count(distinct website_sessions.website_session_id) as session_to_order_convertion_rt
from website_sessions
	left join orders
		on orders.website_session_id = website_sessions.website_session_id
group by utm_content
order by session_to_order_convertion_rt desc;


--                                                              ANALYZING CHANNEL PORTFOLIOS
SELECT 
    min(date(created_at)) as week_start_date, 
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct case when utm_source = 'gsearch' then website_session_id else null end) as gsearch_session,
    count(distinct case when utm_source = 'bsearch' then website_session_id else null end) as bsearch_session
FROM website_sessions
WHERE created_at BETWEEN '2012-08-22' AND '2012-11-29'
	and utm_campaign = 'nonbrand'
GROUP BY yearweek(created_at);


--                                           COMPARING CHANNEL CHARACTERISTICS 
SELECT 
    utm_source, 
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct case when device_type = 'mobile' then website_session_id else null end) as mobile_session,
    count(distinct case when device_type = 'mobile' then website_session_id else null end) / 
      count(distinct website_sessions.website_session_id) as percent_of_mobile_sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-08-22' AND '2012-11-30'
    and utm_campaign = 'nonbrand'
GROUP BY utm_source;

-- CROSS CHANNEL BID OPTIMIZATION
SELECT 
	device_type,
    utm_source, 
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id) / count(distinct website_sessions.website_session_id) as orders_convertion_rate
FROM website_sessions
	left join orders
		on orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at between '2012-08-22' AND '2012-09-19'
    and utm_campaign = 'nonbrand'
GROUP BY device_type, utm_source;

-- CHANNEL PORTFOLIO TRENDS
SELECT 
	min(date(created_at)) as min_start_date,
    count(distinct case when utm_source = 'gsearch' and device_type = 'desktop' then website_session_id else null end) as g_desktop_session_id,
    count(distinct case when utm_source = 'bsearch' and device_type = 'desktop' then website_session_id else null end) as b_desktop_session_id,
    count(distinct case when utm_source = 'bsearch' and device_type = 'desktop' then website_session_id else null end) / 
			count(distinct case when utm_source = 'gsearch' and device_type = 'desktop' then website_session_id else null end) as b_pct_of_g_dtop,
            
	count(distinct case when utm_source = 'gsearch' and device_type = 'mobile' then website_session_id else null end) as g_mobile_session_id,
    count(distinct case when utm_source = 'bsearch' and device_type = 'mobile' then website_session_id else null end) as b_mobile_session_id,
    count(distinct case when utm_source = 'bsearch' and device_type = 'mobile' then website_session_id else null end) / 
			count(distinct case when utm_source = 'gsearch' and device_type = 'mobile' then website_session_id else null end) as b_pct_of_g_mob
FROM website_sessions
WHERE website_sessions.created_at between '2012-11-04' AND '2012-12-22'
    and utm_campaign = 'nonbrand'
GROUP BY yearweek(created_at);


-- -----------------------------------------------------------ANALYZING DIRECT TRAFFIC-----------------------------------------------------------------
select 
	case
		when http_referer is null then 'direct_trafic'
        when http_referer = 'https://www.gsearch.com' and utm_source is null then 'gsearch_organic_trafic'
        when http_referer = 'https://www.bsearch.com' and utm_source is null then 'bsearch_organic_trafic'
		else 'other'
    end as type_of_trafic,
    count(distinct website_session_id) as sessions
from website_sessions
group by 1
order by sessions desc;

-- ANALYZING FREE CHANNELS
select distinct
	case
		when utm_source is null and http_referer in ('https://www.gsearch.com', 'https://www.bsearch.com')  then 'organic_search_trafic'
        when utm_campaign = 'nonbrand' then 'paid_nonbrand'
        when utm_campaign = 'brand' then 'paid_brand'
        when utm_source is null	and http_referer is null then 'direct_type_in'
		else 'other'
    end as type_of_trafic,
    utm_source,
    utm_campaign,
    utm_content
from website_sessions
where created_at < '2012-12-23';

select
	year(created_at) as yr,
    month(created_at) as mon,
    count(distinct case when type_of_trafic = 'paid_nonbrand' then website_session_id else null end) as nonbrand,
    count(distinct case when type_of_trafic = 'paid_brand' then website_session_id else null end) as brand,
    count(distinct case when type_of_trafic = 'paid_brand' then website_session_id else null end) /
			count(distinct case when type_of_trafic = 'paid_nonbrand' then website_session_id else null end) as brand_percent_of_nonbrand,
	count(distinct case when type_of_trafic = 'direct_type_in' then website_session_id else null end) as direct,
    count(distinct case when type_of_trafic = 'direct_type_in' then website_session_id else null end) /
			count(distinct case when type_of_trafic = 'paid_nonbrand' then website_session_id else null end) as direct_percent_of_nonbrand,
	count(distinct case when type_of_trafic = 'organic_search_trafic' then website_session_id else null end) as organic,
    count(distinct case when type_of_trafic = 'organic_search_trafic' then website_session_id else null end) / 
			count(distinct case when type_of_trafic = 'paid_nonbrand' then website_session_id else null end) as organic_percent_of_nonbrand
from(
select distinct
	website_session_id,
    created_at,
    case
		when utm_source is null and http_referer in ('https://www.gsearch.com', 'https://www.bsearch.com')  then 'organic_search_trafic'
        when utm_campaign = 'nonbrand' then 'paid_nonbrand'
        when utm_campaign = 'brand' then 'paid_brand'
        when utm_source is null	and http_referer is null then 'direct_type_in'
		else 'other'
    end as type_of_trafic
from website_sessions
where created_at < '2012-12-23'
) as session_w_channel_group
group by 1,2


































































