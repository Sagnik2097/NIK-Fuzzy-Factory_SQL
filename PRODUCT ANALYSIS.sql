-- ------------------------------------------------------------------PRODUCT ANALYSIS---------------------------------------------------------------------------

--                                                            PRODUCT LEVEL SALES ANALYSIS
select
	year(created_at) as yr,
    month(created_at) as mo,
    count(distinct order_id) as no_of_sales,
    sum(price_usd) as total_ravinue,
    sum(price_usd - cogs_usd) as total_margin
from orders
where created_at < '2013-01-04'
group by
	yr,
    mo;

--  PRODUCT LAUNCH SALES ANALYSIS
select
	year(website_sessions.created_at) as yr,
    month(website_sessions.created_at) as mo,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id) / count(distinct website_sessions.website_session_id) as convertion_rate,
    sum(price_usd) / count(distinct website_sessions.website_session_id) as revinue_per_session,
    count(distinct case when primary_product_id = 1 then order_id else null end) as product_one_order,
    count(distinct case when primary_product_id = 2 then order_id else null end) as product_two_order
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at < '2013-04-01'
	and website_sessions.created_at > '2012-04-01'
group by
	yr,
    mo;


--                                                            PRODUCT LEVEL WEBSITE ANALYSIS

select
	website_pageviews.pageview_url,
    count(distinct website_pageviews.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id) / count(distinct website_pageviews.website_session_id) as website_product_to_order_rate
from website_pageviews
	left join orders
		on website_pageviews.website_session_id = orders.website_session_id
where website_pageviews.created_at between '2012-02-01' and '2013-03-01'   -- arbitary 
	and website_pageviews.pageview_url in ('/the-forever-love-bear', '/the-original-mr-fuzzy')
group by
	1;

--                                                                  PRODUCT PATHING ANALYSIS

-- step-1: find the relivent /product pageview 
create temporary table products_pageview
select 
	website_session_id,
    website_pageview_id,
    created_at,
    case
		when created_at < '2013-01-06' then 'A.Pre_Product_2'
        when created_at >= '2013-01-06' then 'B.Post_Product_2'
        else 'check_logic'
	end as time_period
from website_pageviews
where created_at < '2013-04-06'
	and created_at >= '2012-10-06' -- start of 3 month before product 2 launch
    and pageview_url = '/products';

-- step-2: finding the next pageview id that occurs AFTER the product pageview
create temporary table session_w_next_pageview_id
select 
	products_pageview.time_period,
    products_pageview.website_session_id,
    min(website_pageviews.website_pageview_id) as min_next_pageview_id
from products_pageview
	left join website_pageviews
		on website_pageviews.website_session_id = products_pageview.website_session_id
        and website_pageviews.website_pageview_id > products_pageview.website_pageview_id
group by 1,2;

-- step-3: find the pageview_url associeted with any applicable next pageview id
create temporary table session_w_next_pageview_url
select 
	session_w_next_pageview_id.time_period,
    session_w_next_pageview_id.website_session_id,
    website_pageviews.pageview_url as next_pageview_url
from session_w_next_pageview_id
	left join website_pageviews
		on website_pageviews.website_pageview_id = session_w_next_pageview_id.min_next_pageview_id;

-- step-4: summarizing the data and analizing Pre vs. Post Pageviews
select 
	time_period,
    count(distinct website_session_id) as sessions,
    count(distinct case when next_pageview_url is not null then website_session_id else not null end) as w_next_pg,
    count(distinct case when next_pageview_url is not null then website_session_id else not null end) / 
      count(distinct website_session_id) as pct_w_next_pg,
    count(distinct case when next_pageview_url = '/the-original-mr-fuzzy' then website_session_id else not null end) as to_mrfuzzy,
    count(distinct case when next_pageview_url = '/the-original-mr-fuzzy' then website_session_id else not null end) / 
      count(distinct website_session_id)as pct_to_mrfuzzy,
    count(distinct case when next_pageview_url = '/the-forever-love-bear' then website_session_id else not null end) as to_lovebear,
    count(distinct case when next_pageview_url = '/the-forever-love-bear' then website_session_id else not null end) /  
      count(distinct website_session_id) as pct_to_lovebear
from session_w_next_pageview_url
group by time_period;


--                                                               PRODUCT CONVERISON FUNNELS

-- step-1: select all the pageview for relivent session
-- create temporary table session_seeing_products_pages
select 
	website_session_id,
    website_pageview_id,
    pageview_url as product_page_seen
from website_pageviews
where created_at < '2013-04-10'
	and created_at >= '2013-1-06' -- product 2 lonch date
    and pageview_url in ('/the-original-mr-fuzzy' , '/the-forever-love-bear');

-- step-2: finding out which pageview urls look for
select 
	distinct website_pageviews.pageview_url
from session_seeing_products_pages
	left join website_pageviews
		on website_pageviews.website_session_id = session_seeing_products_pages.website_session_id
        and website_pageviews.website_pageview_id > session_seeing_products_pages.website_pageview_id;

-- step-3: pull all pageviews and identify the funnel step         
select 
	session_seeing_products_pages.website_session_id,
    session_seeing_products_pages.product_page_seen,
    case when pageview_url = '/cart' then 1 else 0 end as cart_page,
    case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
    case when pageview_url = '/billing-2' then 1 else 0 end as billing2_page,
    case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from session_seeing_products_pages        
    left join website_pageviews
		on website_pageviews.website_session_id = session_seeing_products_pages.website_session_id
        and website_pageviews.website_pageview_id > session_seeing_products_pages.website_pageview_id
order by 1,2;

create temporary table session_product_label_made_it_flag        
select
	website_session_id,
    case 
		when product_page_seen = '/the-original-mr-fuzzy' then 'mrfuzzy'
        when product_page_seen = '/the-forever-love-bear' then 'lovebear'
        else 'check logic'
	end as product_seen,
    max(cart_page) as cart_made_it,
    max(shipping_page) as shipping_made_it,
    max(billing2_page) as billing2_made_it,
    max(thankyou_page) as thankyou_made_it
from (
	select 
		session_seeing_products_pages.website_session_id,
		session_seeing_products_pages.product_page_seen,
		case when pageview_url = '/cart' then 1 else 0 end as cart_page,
		case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
		case when pageview_url = '/billing-2' then 1 else 0 end as billing2_page,
		case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
	from session_seeing_products_pages        
		left join website_pageviews
			on website_pageviews.website_session_id = session_seeing_products_pages.website_session_id
			and website_pageviews.website_pageview_id > session_seeing_products_pages.website_pageview_id
	order by 1,2) as pageview_label
    group by 1,2;

-- step-4: create session-level convertion funnel view
select 
	count(distinct website_session_id) as sessions,
    count(distinct case when cart_made_it = 1 then website_session_id else null end) as to_cart,
    count(distinct case when cart_made_it = 1 then website_session_id else null end) / 
      count(distinct website_session_id) as cart_click_rt,
    count(distinct case when shipping_made_it = 1 then website_session_id else null end) as to_shipping,
    count(distinct case when shipping_made_it = 1 then website_session_id else null end) / 
      count(distinct website_session_id) as shipping_click_rt,
    count(distinct case when billing2_made_it = 1 then website_session_id else null end) as to_billing2,
    count(distinct case when billing2_made_it = 1 then website_session_id else null end) / 
      count(distinct website_session_id) as billing2_click_rt,
    count(distinct case when thankyou_made_it = 1 then website_session_id else null end) as to_thankyou,
    count(distinct case when thankyou_made_it = 1 then website_session_id else null end) / 
      count(distinct website_session_id) as thankyou_click_rt
from session_product_label_made_it_flag  
group by product_seen;


--                                                          CROSS-SELLING PRODUCTS

-- CROSS-SELL ANALYSIS

-- step-1: identify the relivent /cart pageview and their sessions
create temporary table session_seeing_cart
select
	case
		when created_at < '2013-09-25' then 'A.Pre_cross_sell'
        when created_at > '2013-01-06' then 'B.Post_cross_sell'
        else 'check logic'
	end as time_period,
	website_session_id as cart_session_id,
	website_pageview_id as cart_pageview_id
from website_pageviews
where created_at between '2013-08-25' and '2013-10-25'
	and pageview_url = '/cart';

-- step-2: seeing which of the /cart session click through the sheeping page
create temporary table cart_sessions_seeing_anather_page
select 
	session_seeing_cart.time_period,
    session_seeing_cart.cart_session_id,
    min(website_pageviews.website_pageview_id) as pv_id_after_cart
from session_seeing_cart
	left join website_pageviews
		on website_pageviews.website_session_id = session_seeing_cart.cart_session_id
        and website_pageviews.website_pageview_id > session_seeing_cart.cart_session_id
group by 1,2
having 3 is not null;

-- step-3: find the order associated with /cart session. Analyzed product purchesed, AOV
create temporary table pre_post_session_order
select
	time_period,
    cart_session_id,
    order_id,
    items_purchased,
    price_usd
from session_seeing_cart
	inner join orders
		on session_seeing_cart.cart_session_id = orders.website_session_id;

select 
	session_seeing_cart.time_period,
    session_seeing_cart.cart_session_id,
    case when cart_sessions_seeing_anather_page.cart_session_id is null then 0 else 1 end as click_to_anather_page,
    case when pre_post_session_order.order_id is null then 0 else 1 end as place_order,
    pre_post_session_order.items_purchased,
    pre_post_session_order.price_usd
from session_seeing_cart
	left join cart_sessions_seeing_anather_page
		on session_seeing_cart.cart_session_id = cart_sessions_seeing_anather_page.cart_session_id
	left join pre_post_session_order
		on session_seeing_cart.cart_session_id = pre_post_session_order.cart_session_id
order by 2;

select
  time_period,
  count(distinct cart_session_id) as cart_sessions,
  sum(click_to_anather_page) as clickthroughs,
  sum(click_to_anather_page) / count(distinct cart_session_id) as cart_CTR,
  sum(place_order) as order_placed,
  sum(items_purchased) as product_purchased,
  sum(items_purchased) / sum(place_order) as product_pur_order,
  sum(price_usd) as revinue,
  sum(price_usd) / sum(place_order) as AOV,
  sum(price_usd) / count(distinct cart_session_id) as rev_per_cart_session
from (
select 
	session_seeing_cart.time_period,
    session_seeing_cart.cart_session_id,
    case when cart_sessions_seeing_anather_page.cart_session_id is null then 0 else 1 end as click_to_anather_page,
    case when pre_post_session_order.order_id is null then 0 else 1 end as place_order,
    pre_post_session_order.items_purchased,
    pre_post_session_order.price_usd
from session_seeing_cart
	left join cart_sessions_seeing_anather_page
		on session_seeing_cart.cart_session_id = cart_sessions_seeing_anather_page.cart_session_id
	left join pre_post_session_order
		on session_seeing_cart.cart_session_id = pre_post_session_order.cart_session_id
order by 2)as full_data
group by time_period ;




--                                                             PORTFOLIO EXPANSION ANALYSIS
SELECT
CASE
    WHEN website_sessions.created_at < '2013-12-12' THEN 'A_Pre-Birthday_Bear'
    WHEN website_sessions.created_at >= '2013-12-12' THEN 'B_Post_Birthday_Bear'
    ELSE 'uh oh...check logic'
END AS time_period,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders,
COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
SUM(orders.price_usd) AS total_revenue,
SUM(orders.price_usd)/COUNT(DISTINCT orders.order_id) as average_order_value,
SUM(orders.items_purchased)/COUNT(DISTINCT orders.order_id) as products_per_order,
SUM(orders.items_purchased)/COUNT(DISTINCT website_sessions.website_session_id)  AS revenue_per_session

FROM website_sessions

LEFT JOIN orders
ON orders.website_session_id = website_sessions.website_session_id

WHERE website_sessions.created_at BETWEEN '2013-11-12' AND '2014-01-12'

GROUP BY 1;


--                                                                 PRODUCT REFUND ANALYSIS

SELECT 
  YEAR(order_items.created_at) AS yr,
  MONTH(order_items.created_at) AS mo,
COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_items.order_item_id ELSE NULL END) AS p1_orders,
  COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_item_refunds.order_item_id ELSE NULL END) /
    COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_items.order_item_id ELSE NULL END) as P1_refund_rt,

COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_items.order_item_id ELSE NULL END) AS p2_orders,
  COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_item_refunds.order_item_id ELSE NULL END) /
    COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_items.order_item_id ELSE NULL END) as P2_refund_rt,

COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_items.order_item_id ELSE NULL END) AS p3_orders,
  COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_item_refunds.order_item_id ELSE NULL END) /
    COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_items.order_item_id ELSE NULL END) as P3_refund_rt,
  
COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_items.order_item_id ELSE NULL END) AS p4_orders,
  COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_item_refunds.order_item_id ELSE NULL END) /
    COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_items.order_item_id ELSE NULL END) as P4_refund_rt
FROM order_items
  LEFT JOIN order_item_refunds
    ON order_items.order_item_id = order_item_refunds.order_item_id
WHERE order_items.created_at < '2024-12-15'
GROUP BY 1, 2;










































