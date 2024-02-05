-- ------------------------------------------------------------------USER ANALYSIS-------------------------------------------------------------------------

--                                                IDENTIFYING REPEAT VISITORS

create temporary table session_w_repeats
select 
	new_sessions.user_id,
    new_sessions.website_session_id as new_session_id,
    website_sessions.website_session_id as repeat_session_id
from (
select 
	user_id,
    website_session_id
from website_sessions
where created_at < '2014-11-01'      -- from
	and created_at >= '2014-01-01'   -- asked date
    and is_repeat_session = 0        -- new sessions only
) as new_sessions
	left join website_sessions
		on  website_sessions.user_id = new_sessions.user_id
        and website_sessions.is_repeat_session = 1            -- was a repeat session 
        and website_sessions.website_session_id > new_sessions.website_session_id  -- session was leater then new sessions
        and website_sessions.created_at < '2014-11-01'      
	    and website_sessions.created_at >= '2014-01-01';


select
	repeat_session,
    count(distinct user_id) as users
from (
	select 
		user_id,
		count(distinct new_session_id) as new_session,
		count(distinct repeat_session_id) as repeat_session
	from session_w_repeats
	group by 1
	order by 3 desc 
	) as user_lavel
group by 1;


--                                                ANALYZING REPEAT BEHAVIOR

-- step-1: Identify the relevent new session and use the userID values to find any repited sessions those user has
create temporary table session_w_repeats_for_time_difference
select 
	new_sessions.user_id,
    new_sessions.website_session_id as new_session_id,
    new_sessions.created_at as new_session_created_at,
    website_sessions.website_session_id as repeat_session_id,
    website_sessions.created_at as repeat_session_created_at
from (
select 
	user_id,
    website_session_id,
    created_at
from website_sessions
where created_at < '2014-11-03'      -- from
	and created_at >= '2014-01-01'   -- asked date
    and is_repeat_session = 0        -- new sessions only
) as new_sessions
	left join website_sessions
		on  website_sessions.user_id = new_sessions.user_id
        and website_sessions.is_repeat_session = 1            -- was a repeat session 
        and website_sessions.website_session_id > new_sessions.website_session_id  -- session was leater then new sessions
        and website_sessions.created_at < '2014-11-03'      
	    and website_sessions.created_at >= '2014-01-01';

-- step-2: find the created at time for the first and second sessions and find the difference between first and second sessions at a ser level
create temporary table user_first_to_second
select
	user_id,
    datediff(second_session_created_at, new_session_created_at) as day_first_to_second_session
from(
	select 
		user_id,
		new_session_id,
		new_session_created_at,
		min(repeat_session_id) as second_session_id,
		min(repeat_session_created_at) as second_session_created_at
	from session_w_repeats_for_time_difference
	where repeat_session_id is not null
	group by 1,2,3
	) as first_second;

-- step-3: aggrigate the user lavel data to find the avarage, min and max
select 
	avg(day_first_to_second_session) as avg_day_first_to_second_session,
    min(day_first_to_second_session) as min_day_first_to_second_session,
    max(day_first_to_second_session) as max_day_first_to_second_session
from user_first_to_second;



--                                                             NEW VS REPEAT CHANNEL PATTERNS

select 
	utm_source,
    utm_campaign,
    http_referer,
    count(case when is_repeat_session = 0 then website_session_id else null end) as new_session,
    count(case when is_repeat_session = 1 then website_session_id else null end) as repeat_session
from website_sessions
where created_at < '2014-11-05'
	and created_at >= '2014-01-01'
group by 1,2,3
order by 5 desc;


select
	case 
		when utm_source is null and http_referer in ('https://www.gsearch.com','https://www.bsearch.com') then 'organic search'
        when utm_campaign = 'nonbrand' then 'paid nonbrand'
        when utm_campaign = 'brand' then 'paid brand'
        when utm_source is null and http_referer is null then 'direct_type_in'
        when utm_source = 'socialbook' then 'paid social'
	end as channel_group,
		-- utm_source,
		-- utm_campaign,
		-- http_referer,
		count(case when is_repeat_session = 0 then website_session_id else null end) as new_session,
		count(case when is_repeat_session = 1 then website_session_id else null end) as repeat_session
from website_sessions
where created_at < '2014-11-05'
	and created_at >= '2014-01-01'
group by 1
order by repeat_session desc;


--                                                     NEW VS REPEAT PERFORMANCE

select 
	is_repeat_session,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) / count(distinct website_sessions.website_session_id) as convertion_rt,
    sum(price_usd) / count(distinct website_sessions.website_session_id) as ravinue_per_session
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at < '2014-11-08'
	and website_sessions.created_at >= '2014-01-01'
group by 1;
























