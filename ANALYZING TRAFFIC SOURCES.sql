-- ----------------------------------------------------------Analyze trafic Source---------------------------------------------------------------------------------------
select 
	website_sessions.utm_content,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id) / count(distinct website_sessions.website_session_id) as session_to_order_conv_rte
from website_sessions
	left join orders
		on orders.website_session_id = website_sessions.website_session_id
group by website_sessions.utm_source
order by sessions;

--                                                             TRAFFIC SOURCE ANALYSIS
select 
	utm_source,
    utm_campaign,
    http_referer,
    count(distinct website_session_id) as sessions
from website_sessions
where created_at < '2012-04-12'
group by
		utm_source,
		utm_campaign,
		http_referer
order by sessions desc;



--                                                                 TRAFFIC CONVERSION RATES
select
		count(distinct website_sessions.website_session_id) as sessions,
        count(distinct orders.order_id) as orders,
        count(distinct orders.order_id) / count(distinct website_sessions.website_session_id) as session_to_order_conv_rt
from website_sessions
	left join orders
			on orders.website_session_id = website_sessions.website_session_id
where website_sessions.created_at < '2012-04-14'
	and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand';
    
    
select
	year(created_at) as created_yr,
    month(created_at) as created_month,
    week(created_at) as created_week,
    count(distinct website_session_id) as session
from website_sessions
group by
		created_yr,
        created_month,
        created_week;
        
-- single and double order items
select
	primary_product_id,
    count(distinct case when items_purchased = 1 then order_id else null end) as count_single_item_order,
    count(distinct case when items_purchased = 2 then order_id else null end) as count_two_item_order
from orders
group by primary_product_id;


-- TRAFFIC SOURCE TRENDING
select
	min(date(created_at)) as week_start_date,
    count(distinct website_session_id) as sessions
from website_sessions
where created_at < '2012-05-12'
	and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand'
group by yearweek(created_at);


--  TRAFFIC SOURCE BID OPTIMIZATION
select
	website_sessions.device_type,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.website_session_id) as orders,
    count(distinct orders.website_session_id) / count(distinct website_sessions.website_session_id) as seassion_to_order_conv_rt    
from website_sessions
	left join orders
			on orders.website_session_id = website_sessions.website_session_id
where website_sessions.created_at < '2012-05-11'
	and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand'
group by device_type;


--  TRAFFIC SOURCE SEGMENT TRENDING
select
	min(date(created_at)) as week_started_date,
    count(distinct case when device_type = 'mobile' then website_session_id else null end) as mobile_session,
    count(distinct case when device_type = 'desktop' then website_session_id else null end) as desktop_session
from website_sessions
where created_at < '2012-06-09'
	and created_at > '2012-04-15'
	and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand'
group by yearweek(created_at);