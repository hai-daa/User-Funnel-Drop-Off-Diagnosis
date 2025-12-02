CREATE TABLE funnel_events (
    user_id     INT,
    event_time  TIMESTAMP,
    event_type  VARCHAR(50),
    campaign    VARCHAR(50),
    device      VARCHAR(50)
);

-- how many rows
SELECT COUNT(*) FROM funnel_events;
--49304

-- distinct users
SELECT COUNT(DISTINCT user_id) AS users FROM funnel_events;
--12000

-- distribution of event types
SELECT event_type, COUNT(*) 
FROM funnel_events
GROUP BY event_type
ORDER BY COUNT(*) DESC;
/*
"install"	12000
"signup"	12000
"view_product"	10777
"add_to_cart"	8434
"checkout"	4222
"purchase"	1871
*/

/*For each user, find whether they hit each step 
(install → signup → view_product → add_to_cart → checkout → purchase), 
then compute counts & conversion.
*/

--First event time per step per user
	--Each timestamp column is NULL if the user never reached that step.
WITH user_step_time AS (
    SELECT
        user_id,
        event_type,
        MIN(event_time) AS first_time
    FROM funnel_events
    GROUP BY user_id, event_type
),

user_funnel AS (
    SELECT
        user_id,
        MIN(CASE WHEN event_type = 'install'      THEN first_time END) AS ts_install,
        MIN(CASE WHEN event_type = 'signup'       THEN first_time END) AS ts_signup,
        MIN(CASE WHEN event_type = 'view_product' THEN first_time END) AS ts_view_product,
        MIN(CASE WHEN event_type = 'add_to_cart'  THEN first_time END) AS ts_add_to_cart,
        MIN(CASE WHEN event_type = 'checkout'     THEN first_time END) AS ts_checkout,
        MIN(CASE WHEN event_type = 'purchase'     THEN first_time END) AS ts_purchase
    FROM user_step_time
    GROUP BY user_id
)

SELECT * FROM user_funnel
LIMIT 10;

--Funnel counts & conversion rates
WITH user_step_time AS (
    SELECT
        user_id,
        event_type,
        MIN(event_time) AS first_time
    FROM funnel_events
    GROUP BY user_id, event_type
),
user_funnel AS (
    SELECT
        user_id,
        MIN(CASE WHEN event_type = 'install'      THEN first_time END) AS ts_install,
        MIN(CASE WHEN event_type = 'signup'       THEN first_time END) AS ts_signup,
        MIN(CASE WHEN event_type = 'view_product' THEN first_time END) AS ts_view_product,
        MIN(CASE WHEN event_type = 'add_to_cart'  THEN first_time END) AS ts_add_to_cart,
        MIN(CASE WHEN event_type = 'checkout'     THEN first_time END) AS ts_checkout,
        MIN(CASE WHEN event_type = 'purchase'     THEN first_time END) AS ts_purchase
    FROM user_step_time
    GROUP BY user_id
),
step_counts AS (
    SELECT
        COUNT(*)                                           AS users_total,
        COUNT(ts_install)                                  AS step_install,
        COUNT(ts_signup)                                   AS step_signup,
        COUNT(ts_view_product)                             AS step_view_product,
        COUNT(ts_add_to_cart)                              AS step_add_to_cart,
        COUNT(ts_checkout)                                 AS step_checkout,
        COUNT(ts_purchase)                                 AS step_purchase
    FROM user_funnel
)

SELECT
    users_total,
    step_install,
    step_signup,
    ROUND(step_signup::NUMERIC / step_install * 100, 2)       AS cr_install_to_signup,
    step_view_product,
    ROUND(step_view_product::NUMERIC / step_signup * 100, 2)  AS cr_signup_to_view,
    step_add_to_cart,
    ROUND(step_add_to_cart::NUMERIC / step_view_product * 100, 2) AS cr_view_to_cart,
    step_checkout,
    ROUND(step_checkout::NUMERIC / step_add_to_cart * 100, 2) AS cr_cart_to_checkout,
    step_purchase,
    ROUND(step_purchase::NUMERIC / step_checkout * 100, 2)    AS cr_checkout_to_purchase
FROM step_counts;

--Funnel by campaign
WITH user_first_campaign AS (
    SELECT DISTINCT ON (user_id)
        user_id,
        campaign
    FROM funnel_events
    ORDER BY user_id, event_time
),
user_step_time AS (
    SELECT
        e.user_id,
        c.campaign,
        e.event_type,
        MIN(e.event_time) AS first_time
    FROM funnel_events e
    JOIN user_first_campaign c USING (user_id)
    GROUP BY e.user_id, c.campaign, e.event_type
),
user_funnel AS (
    SELECT
        user_id,
        campaign,
        MIN(CASE WHEN event_type = 'install'      THEN first_time END) AS ts_install,
        MIN(CASE WHEN event_type = 'signup'       THEN first_time END) AS ts_signup,
        MIN(CASE WHEN event_type = 'view_product' THEN first_time END) AS ts_view_product,
        MIN(CASE WHEN event_type = 'add_to_cart'  THEN first_time END) AS ts_add_to_cart,
        MIN(CASE WHEN event_type = 'checkout'     THEN first_time END) AS ts_checkout,
        MIN(CASE WHEN event_type = 'purchase'     THEN first_time END) AS ts_purchase
    FROM user_step_time
    GROUP BY user_id, campaign
)

SELECT
    campaign,
    COUNT(*)                                      AS users_total,
    COUNT(ts_install)                             AS step_install,
    COUNT(ts_signup)                              AS step_signup,
    ROUND(COUNT(ts_signup)::NUMERIC / NULLIF(COUNT(ts_install),0) * 100, 2)
        AS cr_install_to_signup,
    COUNT(ts_view_product)                        AS step_view_product,
    ROUND(COUNT(ts_view_product)::NUMERIC / NULLIF(COUNT(ts_signup),0) * 100, 2)
        AS cr_signup_to_view,
    COUNT(ts_add_to_cart)                         AS step_add_to_cart,
    ROUND(COUNT(ts_add_to_cart)::NUMERIC / NULLIF(COUNT(ts_view_product),0) * 100, 2)
        AS cr_view_to_cart,
    COUNT(ts_checkout)                            AS step_checkout,
    ROUND(COUNT(ts_checkout)::NUMERIC / NULLIF(COUNT(ts_add_to_cart),0) * 100, 2)
        AS cr_cart_to_checkout,
    COUNT(ts_purchase)                            AS step_purchase,
    ROUND(COUNT(ts_purchase)::NUMERIC / NULLIF(COUNT(ts_checkout),0) * 100, 2)
        AS cr_checkout_to_purchase
FROM user_funnel
GROUP BY campaign
ORDER BY users_total DESC;

--Funnel by Device
WITH user_first_device AS (
    SELECT DISTINCT ON (user_id)
        user_id,
        device
    FROM funnel_events
    ORDER BY user_id, event_time
),
user_step_time AS (
    SELECT
        e.user_id,
        d.device,
        e.event_type,
        MIN(e.event_time) AS first_time
    FROM funnel_events e
    JOIN user_first_device d USING (user_id)
    GROUP BY e.user_id, d.device, e.event_type
),
user_funnel AS (
    SELECT
        user_id,
        device,
        MIN(CASE WHEN event_type = 'install'      THEN first_time END) AS ts_install,
        MIN(CASE WHEN event_type = 'signup'       THEN first_time END) AS ts_signup,
        MIN(CASE WHEN event_type = 'view_product' THEN first_time END) AS ts_view_product,
        MIN(CASE WHEN event_type = 'add_to_cart'  THEN first_time END) AS ts_add_to_cart,
        MIN(CASE WHEN event_type = 'checkout'     THEN first_time END) AS ts_checkout,
        MIN(CASE WHEN event_type = 'purchase'     THEN first_time END) AS ts_purchase
    FROM user_step_time
    GROUP BY user_id, device
)

SELECT
    device,
    COUNT(*) AS users_total,
    COUNT(ts_signup) AS signup_users,
    ROUND(COUNT(ts_signup)::NUMERIC / COUNT(ts_install) * 100, 2) AS cr_install_to_signup,
    COUNT(ts_view_product) AS view_users,
    ROUND(COUNT(ts_view_product)::NUMERIC / NULLIF(COUNT(ts_signup),0) * 100, 2)
        AS cr_signup_to_view,
    COUNT(ts_add_to_cart) AS cart_users,
    ROUND(COUNT(ts_add_to_cart)::NUMERIC / NULLIF(COUNT(ts_view_product),0) * 100, 2)
        AS cr_view_to_cart,
    COUNT(ts_checkout) AS checkout_users,
    ROUND(COUNT(ts_checkout)::NUMERIC / NULLIF(COUNT(ts_add_to_cart),0) * 100, 2)
        AS cr_cart_to_checkout,
    COUNT(ts_purchase) AS purchase_users,
    ROUND(COUNT(ts_purchase)::NUMERIC / NULLIF(COUNT(ts_checkout),0) * 100, 2)
        AS cr_checkout_to_purchase
FROM user_funnel
GROUP BY device
ORDER BY users_total DESC




--Time-Based Funnel (Daily / Weekly Cohort Funnel)
	--Create weekly cohorts:
WITH users_with_install AS (
    SELECT 
        user_id,
        MIN(event_time) AS install_time
    FROM funnel_events
    WHERE event_type = 'install'
    GROUP BY user_id
),
cohorted_users AS (
    SELECT
        user_id,
        DATE_TRUNC('week', install_time)::date AS install_week
    FROM users_with_install
)
--SELECT * FROM cohorted_users;

	--Join cohort + funnel:
WITH users_with_install AS (
    SELECT 
        user_id,
        MIN(event_time) AS install_time
    FROM funnel_events
    WHERE event_type = 'install'
    GROUP BY user_id
),
cohorted_users AS (
    SELECT
        user_id,
        DATE_TRUNC('week', install_time)::date AS install_week
    FROM users_with_install
),
user_funnel AS (
    SELECT
        user_id,
        MIN(CASE WHEN event_type = 'install'      THEN event_time END) AS ts_install,
        MIN(CASE WHEN event_type = 'signup'       THEN event_time END) AS ts_signup,
        MIN(CASE WHEN event_type = 'view_product' THEN event_time END) AS ts_view_product,
        MIN(CASE WHEN event_type = 'add_to_cart'  THEN event_time END) AS ts_add_to_cart,
        MIN(CASE WHEN event_type = 'checkout'     THEN event_time END) AS ts_checkout,
        MIN(CASE WHEN event_type = 'purchase'     THEN event_time END) AS ts_purchase
    FROM funnel_events
    GROUP BY user_id
)

SELECT
    c.install_week,
    COUNT(*) AS users_total,
    COUNT(ts_signup) AS signup_users,
    ROUND(COUNT(ts_signup)::NUMERIC / COUNT(*) * 100, 2) AS install_to_signup,
    COUNT(ts_view_product) AS view_users,
    ROUND(COUNT(ts_view_product)::NUMERIC / COUNT(ts_signup) * 100, 2) AS signup_to_view,
    COUNT(ts_add_to_cart) AS cart_users,
    ROUND(COUNT(ts_add_to_cart)::NUMERIC / COUNT(ts_view_product) * 100, 2) AS view_to_cart,
    COUNT(ts_purchase) AS purchase_users,
    ROUND(COUNT(ts_purchase)::NUMERIC / COUNT(ts_checkout) * 100, 2) AS checkout_to_purchase
FROM user_funnel f
JOIN cohorted_users c USING (user_id)
GROUP BY c.install_week
ORDER BY c.install_week;

--Breakdown by Campaign × Device (Matrix Funnel)
WITH user_funnel AS (
    SELECT
        user_id,
        MIN(CASE WHEN event_type = 'install'      THEN event_time END) AS ts_install,
        MIN(CASE WHEN event_type = 'signup'       THEN event_time END) AS ts_signup,
        MIN(CASE WHEN event_type = 'view_product' THEN event_time END) AS ts_view_product,
        MIN(CASE WHEN event_type = 'add_to_cart'  THEN event_time END) AS ts_add_to_cart,
        MIN(CASE WHEN event_type = 'checkout'     THEN event_time END) AS ts_checkout,
        MIN(CASE WHEN event_type = 'purchase'     THEN event_time END) AS ts_purchase
    FROM funnel_events
    GROUP BY user_id
),
	user_first_campaign AS (
    SELECT DISTINCT ON (user_id)
        user_id,
        campaign
    FROM funnel_events
    ORDER BY user_id, event_time
),
	user_first_device AS (
    SELECT DISTINCT ON (user_id)
        user_id,
        device
    FROM funnel_events
    ORDER BY user_id, event_time
)
SELECT
    campaign,
    device,
    COUNT(*) AS users_total,
    ROUND(AVG(CASE WHEN ts_signup IS NOT NULL THEN 1 ELSE 0 END) * 100, 2) AS cr_install_to_signup,
    ROUND(AVG(CASE WHEN ts_view_product IS NOT NULL THEN 1 ELSE 0 END) * 100, 2) AS cr_signup_to_view,
    ROUND(AVG(CASE WHEN ts_add_to_cart IS NOT NULL THEN 1 ELSE 0 END) * 100, 2) AS cr_view_to_cart,
    ROUND(AVG(CASE WHEN ts_purchase IS NOT NULL THEN 1 ELSE 0 END) * 100, 2) AS cr_checkout_to_purchase
FROM user_funnel
JOIN user_first_campaign USING (user_id)
JOIN user_first_device USING (user_id)
GROUP BY campaign, device
ORDER BY campaign, device;







