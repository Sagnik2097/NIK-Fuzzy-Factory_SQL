-- -----------------------------------------------------------ANALYZING WEBSITE PERFORMANCE---------------------------------------------------------------------
select 
	pageview_url,
    count(distinct website_session_id) as pageviewes
from website_pageviews
group by pageview_url
order by pageviewes desc;


create temporary table first_pageview
select 
	website_session_id,
    min(website_pageview_id) as min_pv_id
from website_pageviews
group by website_session_id
order by min_pv_id desc;


select 
	website_pageviews.pageview_url as landing_page,
    count(distinct first_pageview.website_session_id) as seassion_hittinng_this_lander
from first_pageview
	left join website_pageviews
		on first_pageview.min_pv_id = website_pageviews.website_pageview_id 
group by website_pageviews.pageview_url
order by seassion_hittinng_this_lander desc;
        

-- IDENTIFYING TOP WEBSITE PAGES
select 
	pageview_url,
    count(distinct website_pageview_id) as no_of_pvs
from website_pageviews
where created_at < '2012-06-09'
group by pageview_url
order by no_of_pvs desc;


-- IDENTIFYING TOP ENTRY PAGES
-- create temporary table first_pageviewes
select
	website_session_id,
    min(website_pageview_id) as min_pageview_id
from website_pageviews
where created_at < '2012-06-12'
group by website_session_id;


select 
	website_pageviews.pageview_url as landing_page,
    count(first_pageviewes.website_session_id) as sessions_hitting_this_landing_page
from first_pageviewes
	left join website_pageviews
			on website_pageviews.website_pageview_id = first_pageviewes.min_pageview_id
group by landing_page
order by sessions_hitting_this_landing_page;



--                                                BC: Landing page performance for a certain time period

-- step 1: Find the first pageview id for relivent seassion
create temporary table first_pageviews_demo
select 
	website_pageviews.website_session_id ,
    min(website_pageviews.website_pageview_id) as min_pageview_id
from website_pageviews
	left join website_sessions
		on website_sessions.website_session_id = website_pageviews.website_session_id
group by website_pageviews.website_session_id;

-- step 2: Identify the landing page of each session
create temporary table sessions_w_landing_page_demo
select 
	first_pageviews_demo.website_session_id,
    website_pageviews.pageview_url as landing_page
from website_pageviews
	left join first_pageviews_demo
			on website_pageviews.website_pageview_id = first_pageviews_demo.min_pageview_id;

-- step 3: counting pageviewes for each session, to identify "bounces"
create temporary table bounced_sessions_only
select
	sessions_w_landing_page_demo.landing_page,
	sessions_w_landing_page_demo.website_session_id,
    count(website_pageviews.website_pageview_id) as count_of_page_viewes
from  website_pageviews
	left join sessions_w_landing_page_demo
			on sessions_w_landing_page_demo.website_session_id = website_pageviews.website_session_id
group by 
		sessions_w_landing_page_demo.website_session_id,
		sessions_w_landing_page_demo.landing_page
having count_of_page_viewes = 1;

-- summarizing by counting total sessions and bounced sessions
select
	sessions_w_landing_page_demo.landing_page,
	sessions_w_landing_page_demo.website_session_id,
    bounced_sessions_only.website_session_id as bounced_website_session_id
from sessions_w_landing_page_demo
	left join bounced_sessions_only
		on bounced_sessions_only.website_session_id = sessions_w_landing_page_demo.website_session_id
order by sessions_w_landing_page_demo.website_session_id;

-- final output
select
	sessions_w_landing_page_demo.landing_page,
	count(distinct sessions_w_landing_page_demo.website_session_id) as no_of_sessions,
    count(distinct bounced_sessions_only.website_session_id) as no_of_bounced_session,
    count(distinct bounced_sessions_only.website_session_id) / count(distinct sessions_w_landing_page_demo.website_session_id) as bounce_rate
from sessions_w_landing_page_demo
	left join bounced_sessions_only
		on bounced_sessions_only.website_session_id = sessions_w_landing_page_demo.website_session_id
group by sessions_w_landing_page_demo.landing_page;



--                                                   CALCULATING BOUNCE RATES FOR HOMEPAGE

-- step 1: Find the first pageview id for relivent seassion
create temporary table first_pageviews
select 
	website_pageviews.website_session_id ,
    min(website_pageviews.website_pageview_id) as min_pageview_id
from website_pageviews
	left join website_sessions
		on website_sessions.website_session_id = website_pageviews.website_session_id
where website_pageviews.created_at < '2012-06-14'
group by website_pageviews.website_session_id;

-- step 2: Identify the landing page of each session
create temporary table sessions_w_landing_page
select 
	first_pageviews.website_session_id,
    website_pageviews.pageview_url as landing_page
from website_pageviews
	left join first_pageviews
			on website_pageviews.website_pageview_id = first_pageviews.min_pageview_id
where website_pageviews.pageview_url = '/home';

-- step 3: counting pageviewes for each session, to identify "bounces"
create temporary table bounced_sessions
select
	sessions_w_landing_page.landing_page,
	sessions_w_landing_page.website_session_id,
    count(website_pageviews.website_pageview_id) as count_of_page_viewes
from  website_pageviews
	left join sessions_w_landing_page
			on sessions_w_landing_page.website_session_id = website_pageviews.website_session_id
group by 
		sessions_w_landing_page.website_session_id,
		sessions_w_landing_page.landing_page
having count_of_page_viewes = 1;

-- summarizing by counting total sessions and bounced sessions (final output)
select
	count(distinct sessions_w_landing_page.landing_page) as sesion,
	count(distinct bounced_sessions.website_session_id) as bounced_session,
    count(distinct bounced_sessions.website_session_id) / count(distinct sessions_w_landing_page.website_session_id) as bounced_rate
from sessions_w_landing_page
	left join bounced_sessions
		on bounced_sessions.website_session_id = sessions_w_landing_page.website_session_id;



--                                      ANALYZING LANDING PAGE TESTS FOR HOMEPAGE FOR HOME AND LANDER-1 Page 

-- Step 0: Findout when the lander-1 page first created
select
	min(created_at) as first_created_at,                  --  2012-06-19 00:35:54
    min(website_pageview_id) as first_pageview_id         --  23504
from website_pageviews
where pageview_url = '/lander-1'
	and created_at is not null;

-- step 1: Find the first pageview id for relivent seassion
create temporary table first_test_pageviews
select 
	website_pageviews.website_session_id ,
    min(website_pageviews.website_pageview_id) as min_pageview_id
from website_pageviews
	left join website_sessions
		on website_sessions.website_session_id = website_pageviews.website_session_id
where website_pageviews.created_at < '2012-07-28'
	and website_pageviews.website_pageview_id > 23504
	and website_sessions.utm_source = 'gsearch'
    and website_sessions.utm_campaign = 'nonbrand'
group by website_pageviews.website_session_id;

-- step 2: Identify the landing page of home and lander-1 session
create temporary table nonbrand_test_sessions_w_landing_page
select 
	first_test_pageviews.website_session_id,
    website_pageviews.pageview_url as landing_page
from first_test_pageviews
	left join website_pageviews
			on website_pageviews.website_pageview_id = first_test_pageviews.min_pageview_id
where website_pageviews.pageview_url in ('/home', '/lander-1');

-- step 3: counting pageviewes for home and landing-1 session, to identify "bounces"
create temporary table nonbrand_test_bounced_sessions
select
	nonbrand_test_sessions_w_landing_page.landing_page,
	nonbrand_test_sessions_w_landing_page.website_session_id,
    count(website_pageviews.website_pageview_id) as count_of_page_viewes
from  nonbrand_test_sessions_w_landing_page
	left join website_pageviews
			on nonbrand_test_sessions_w_landing_page.website_session_id = website_pageviews.website_session_id
group by 
		nonbrand_test_sessions_w_landing_page.website_session_id,
		nonbrand_test_sessions_w_landing_page.landing_page
having count_of_page_viewes = 1;

-- summarizing by counting total sessions and bounced sessions
select
	nonbrand_test_sessions_w_landing_page.landing_page,
	nonbrand_test_sessions_w_landing_page.website_session_id,
    nonbrand_test_bounced_sessions.website_session_id as bounced_website_session_id
from nonbrand_test_sessions_w_landing_page
	left join nonbrand_test_bounced_sessions
		on nonbrand_test_bounced_sessions.website_session_id = nonbrand_test_sessions_w_landing_page.website_session_id
order by nonbrand_test_sessions_w_landing_page.website_session_id;

-- Final output
select
	nonbrand_test_sessions_w_landing_page.landing_page,
	count(distinct nonbrand_test_sessions_w_landing_page.website_session_id) as sesion,
	count(distinct nonbrand_test_bounced_sessions.website_session_id) as bounced_session,
    count(distinct nonbrand_test_bounced_sessions.website_session_id) / count(distinct nonbrand_test_sessions_w_landing_page.website_session_id) as bounced_rate
from nonbrand_test_sessions_w_landing_page
	left join nonbrand_test_bounced_sessions
		on nonbrand_test_bounced_sessions.website_session_id = nonbrand_test_sessions_w_landing_page.website_session_id
group by landing_page;



--                            LANDING PAGE TREND ANALYSIS  paid search nonbrand traffic landing on /home and /lander-1

-- Step 1: Find the first pageview id for relevant sessions
CREATE TEMPORARY TABLE session_w_first_pageview_id_and_view_counts AS
SELECT 
    website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS first_pageview_id,
    COUNT(website_pageviews.website_pageview_id) AS count_pageview_id
FROM website_pageviews
LEFT JOIN website_sessions
    ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_pageviews.created_at >= '2012-06-01'
    AND website_pageviews.created_at <= '2012-08-31'
    AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY website_pageviews.website_session_id;

-- Step 2: Identify the landing page of home and lander-1 sessions
CREATE TEMPORARY TABLE sessions_w_counts_lander_and_created_at
SELECT 
    session_w_first_pageview_id_and_view_counts.website_session_id,
    session_w_first_pageview_id_and_view_counts.first_pageview_id,
    session_w_first_pageview_id_and_view_counts.count_pageview_id,
    website_pageviews.pageview_url AS landing_page,
    website_pageviews.created_at AS session_created_at
FROM session_w_first_pageview_id_and_view_counts
LEFT JOIN website_pageviews
    ON website_pageviews.website_pageview_id = session_w_first_pageview_id_and_view_counts.first_pageview_id;

-- step 3: counting pageviewes for home and landing-1 session, to identify "bounces"
select
	-- yearweek(session_created_at) as year_week,
    min(date(session_created_at)) as week_start_date,
    -- count(distinct website_session_id) as total_sessions,
    -- count(distinct case when count_pageview_id = 1 then website_session_id else null end) as bounced_session,
    count(distinct case when count_pageview_id = 1 then website_session_id else null end)*1.0 / count(distinct website_session_id)*1.0 as bounced_rate,
    count(distinct case when landing_page = '/home' then website_session_id else null end) as home_session,
    count(distinct case when landing_page = '/lander-1' then website_session_id else null end) as landng1_session
from sessions_w_counts_lander_and_created_at
group by 
		yearweek(session_created_at);



--                                          BUILDING CONVERSION FUNNELS


-- step 1: sellect pageview for relivent session
select
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    website_pageviews.created_at as pageview_created_at,
    case when pageview_url = '/products' then 1 else 0 end as product_page,
    case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mr_fuzzy_page,
    case when pageview_url = '/cart' then 1 else 0 end as cart_page,
    case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
    case when pageview_url = '/billing' then 1 else 0 end as billing_page,
    case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id = website_pageviews.website_session_id
where website_sessions.utm_source = 'gsearch'
  and website_sessions.utm_campaign = 'nonbrand'
  and website_sessions.created_at > '2012-08-05'
  and website_sessions.created_at < '2012-09-05'
order by 
		website_sessions.website_session_id,
		website_sessions.created_at;


-- step 2: Create the session level convertation funnel view 
create temporary table session_lebel_flag_demo
select
	website_session_id,
    max(product_page) as prodect_made_it,
    max(mr_fuzzy_page) as mr_fuzzy_made_it,
    max(cart_page) as cart_made_it,
    max(shipping_page) as shipping_made_it,
    max(billing_page) as billing_made_it,
    max(thankyou_page) as thankyou_made_it
from (
	select
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    website_pageviews.created_at as pageview_created_at,
    case when pageview_url = '/products' then 1 else 0 end as product_page,
    case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mr_fuzzy_page,
    case when pageview_url = '/cart' then 1 else 0 end as cart_page,
    case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
    case when pageview_url = '/billing' then 1 else 0 end as billing_page,
    case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id = website_pageviews.website_session_id
where website_sessions.utm_source = 'gsearch'
  and website_sessions.utm_campaign = 'nonbrand'
  and website_sessions.created_at > '2012-08-05'
  and website_sessions.created_at < '2012-09-05'
order by 
		website_sessions.website_session_id,
		website_sessions.created_at ) as pagecview_label
group by website_session_id;

-- step 3: Aggrigate the data to assess final performance 
select
	count(distinct website_session_id) as sessions,
    count(distinct case when prodect_made_it = 1 then website_session_id else null end) as to_products,
    count(distinct case when mr_fuzzy_made_it = 1 then website_session_id else null end) as to_mr_fuzzy,
    count(distinct case when cart_made_it = 1 then website_session_id else null end) as to_cart,
    count(distinct case when shipping_made_it = 1 then website_session_id else null end) as to_shipping,
    count(distinct case when billing_made_it = 1 then website_session_id else null end) as to_billing,
    count(distinct case when thankyou_made_it = 1 then website_session_id else null end) as to_thankyou
from session_lebel_flag_demo;


select
    count(distinct case when prodect_made_it = 1 then website_session_id else null end) / 
      count(distinct website_session_id) as lander_click_through_rate,
      
    count(distinct case when mr_fuzzy_made_it = 1 then website_session_id else null end) /  
      count(distinct case when prodect_made_it = 1 then website_session_id else null end) as product_click_through_rate,
      
    count(distinct case when cart_made_it = 1 then website_session_id else null end) /
      count(distinct case when mr_fuzzy_made_it = 1 then website_session_id else null end) as mr_fuzzy_click_through_rate,
      
    count(distinct case when shipping_made_it = 1 then website_session_id else null end) /
      count(distinct case when cart_made_it = 1 then website_session_id else null end) as shipping_click_through_rate,
      
    count(distinct case when billing_made_it = 1 then website_session_id else null end) /
      count(distinct case when shipping_made_it = 1 then website_session_id else null end)as billing_click_through_rate,
      
    count(distinct case when thankyou_made_it = 1 then website_session_id else null end) /
      count(distinct case when billing_made_it = 1 then website_session_id else null end) as thankyou_click_through_rate
from session_lebel_flag_demo;



--                                          BC: We want to build a mini convertation funnel, from /billing to /billing-2
--                                              We want to know how many people reach each step, and also dropoff rates

-- step 0: Finding the first time /billing-2 page was seen
select
	min(created_at) as first_created_at,
	min(website_pageview_id) as first_pageview_id
from website_pageviews
where pageview_url = '/billing-2';

-- step 1: sellect pageview for relivent session
select
	website_pageviews.website_session_id,
    website_pageviews.pageview_url as billing_virtion_seen,
    orders.order_id
from website_pageviews
	left join orders
		on orders.website_session_id = website_pageviews.website_session_id
where website_pageviews.created_at < '2012-11-10'
	and website_pageviews.website_pageview_id >= 53350
	and website_pageviews.pageview_url in ('/billing','/billing-2')
order by 
		website_pageviews.website_session_id,
    website_pageviews.pageview_url;

-- step 2: Identify each pageview as spesific funnel step
select
	billing_virtion_seen,
    count(distinct website_session_id) as sessions,
    count(distinct order_id) as orders,
    count(distinct order_id) / count(distinct website_session_id) as billing_to_order_rt
from (
	select
	website_pageviews.website_session_id,
    website_pageviews.pageview_url as billing_virtion_seen,
    orders.order_id
from website_pageviews
	left join orders
		on orders.website_session_id = website_pageviews.website_session_id
where website_pageviews.created_at < '2012-11-10'
	and website_pageviews.website_pageview_id >= 53350
	and website_pageviews.pageview_url in ('/billing','/billing-2')
order by 
		website_pageviews.website_session_id,
    website_pageviews.pageview_url
	) as billing_session_w_order
group by billing_virtion_seen;