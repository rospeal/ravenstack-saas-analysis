-- ============================================================
-- RavenStack SaaS Business Analysis
-- Portfolio SQL Analysis
-- ============================================================
-- Purpose: Explore revenue, acquisition, product usage, customer
-- support, and churn/retention patterns.
--
-- Metric granularity:
-- * Account-level churn: customer attributes (industry/referral).
-- * Subscription-level churn: plan/upgrade/downgrade analysis.
-- ============================================================

-- 1. CUSTOMER ACQUISITION

-- Referral source: total ARR
SELECT a.referral_source, SUM(s.arr_amount) AS total_arr
FROM ravenstack_accounts AS a
LEFT JOIN ravenstack_subscriptions AS s ON a.account_id = s.account_id
GROUP BY a.referral_source
ORDER BY total_arr DESC;

-- Referral source: average ARR per subscription
SELECT a.referral_source, AVG(s.arr_amount) AS average_arr_per_subscription
FROM ravenstack_accounts AS a
LEFT JOIN ravenstack_subscriptions AS s ON a.account_id = s.account_id
GROUP BY a.referral_source
ORDER BY average_arr_per_subscription DESC;

-- Referral source: customer churn rate
SELECT referral_source,
       ROUND(100.0 * SUM(CASE WHEN churn_flag = 'TRUE' THEN 1 ELSE 0 END) / COUNT(*), 2)
       AS customer_churn_rate_percent
FROM ravenstack_accounts
GROUP BY referral_source
ORDER BY customer_churn_rate_percent DESC;

-- Industry: total ARR
SELECT a.industry, SUM(s.arr_amount) AS total_arr
FROM ravenstack_accounts AS a
LEFT JOIN ravenstack_subscriptions AS s ON a.account_id = s.account_id
GROUP BY a.industry
ORDER BY total_arr DESC;

-- Industry: average ARR per subscription
SELECT a.industry, AVG(s.arr_amount) AS average_arr_per_subscription
FROM ravenstack_accounts AS a
LEFT JOIN ravenstack_subscriptions AS s ON a.account_id = s.account_id
GROUP BY a.industry
ORDER BY average_arr_per_subscription DESC;

-- Industry: customer churn rate
SELECT industry,
       ROUND(100.0 * SUM(CASE WHEN churn_flag = 'TRUE' THEN 1 ELSE 0 END) / COUNT(*), 2)
       AS customer_churn_rate_percent
FROM ravenstack_accounts
GROUP BY industry
ORDER BY customer_churn_rate_percent DESC;

-- Country: total ARR
SELECT a.country, SUM(s.arr_amount) AS total_arr
FROM ravenstack_accounts AS a
LEFT JOIN ravenstack_subscriptions AS s ON a.account_id = s.account_id
GROUP BY a.country
ORDER BY total_arr DESC;

-- Country: average ARR per subscription
SELECT a.country, AVG(s.arr_amount) AS average_arr_per_subscription
FROM ravenstack_accounts AS a
LEFT JOIN ravenstack_subscriptions AS s ON a.account_id = s.account_id
GROUP BY a.country
ORDER BY average_arr_per_subscription DESC;


-- 2. REVENUE & SUBSCRIPTION PLANS

-- Revenue by plan
SELECT plan_tier, SUM(mrr_amount) AS total_mrr
FROM ravenstack_subscriptions
GROUP BY plan_tier
ORDER BY total_mrr DESC;

SELECT plan_tier, AVG(mrr_amount) AS average_mrr_per_subscription
FROM ravenstack_subscriptions
GROUP BY plan_tier
ORDER BY average_mrr_per_subscription DESC;

-- Subscription churn by plan
SELECT plan_tier,
       ROUND(100.0 * SUM(CASE WHEN churn_flag = 'TRUE' THEN 1 ELSE 0 END) / COUNT(*), 2)
       AS subscription_churn_rate_percent
FROM ravenstack_subscriptions
GROUP BY plan_tier
ORDER BY subscription_churn_rate_percent DESC;


-- 3. PRODUCT USAGE

-- Feature usage
SELECT feature_name, SUM(usage_count) AS total_usage
FROM ravenstack_feature_usage
GROUP BY feature_name
ORDER BY total_usage DESC;

SELECT feature_name, AVG(usage_count) AS average_usage
FROM ravenstack_feature_usage
GROUP BY feature_name
ORDER BY average_usage DESC;

-- Product usage vs customer churn:
-- aggregate usage to account level before comparing customer groups.
SELECT a.churn_flag,
       AVG(account_usage.total_usage) AS average_total_usage
FROM ravenstack_accounts AS a
LEFT JOIN (
    SELECT s.account_id, SUM(fu.usage_count) AS total_usage
    FROM ravenstack_subscriptions AS s
    LEFT JOIN ravenstack_feature_usage AS fu
        ON s.subscription_id = fu.subscription_id
    GROUP BY s.account_id
) AS account_usage ON a.account_id = account_usage.account_id
GROUP BY a.churn_flag;

-- Beta feature adoption
SELECT is_beta_feature,
       SUM(usage_count) AS total_usage,
       AVG(usage_count) AS average_usage
FROM ravenstack_feature_usage
GROUP BY is_beta_feature;


-- 4. CUSTOMER SUPPORT

-- Support speed vs satisfaction
SELECT satisfaction_score,
       AVG(first_response_time_minutes) AS average_first_response_time,
       AVG(resolution_time_hours) AS average_resolution_time
FROM ravenstack_support_tickets
WHERE satisfaction_score IS NOT NULL
GROUP BY satisfaction_score
ORDER BY satisfaction_score;

-- Support patterns by priority
SELECT priority,
       AVG(resolution_time_hours) AS average_resolution_time,
       AVG(first_response_time_minutes) AS average_first_response_time,
       ROUND(100.0 * SUM(CASE WHEN escalation_flag = 'TRUE' THEN 1 ELSE 0 END) / COUNT(*), 2)
       AS escalation_rate_percent
FROM ravenstack_support_tickets
GROUP BY priority
ORDER BY average_resolution_time DESC;

-- Accounts with highest support demand
SELECT account_id, COUNT(*) AS ticket_count
FROM ravenstack_support_tickets
GROUP BY account_id
ORDER BY ticket_count DESC
LIMIT 10;


-- 5. CHURN & RETENTION

-- Stated churn reasons
SELECT reason_code,
       COUNT(*) AS churn_events,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM ravenstack_churn_events), 2)
       AS percentage_of_churn
FROM ravenstack_churn_events
GROUP BY reason_code
ORDER BY churn_events DESC;

-- Support experience vs customer churn
SELECT a.churn_flag,
       AVG(st.first_response_time_minutes) AS average_first_response_time,
       AVG(st.resolution_time_hours) AS average_resolution_time,
       AVG(st.satisfaction_score) AS average_satisfaction
FROM ravenstack_accounts AS a
LEFT JOIN ravenstack_support_tickets AS st ON a.account_id = st.account_id
GROUP BY a.churn_flag;

-- Escalation rate by customer churn status
SELECT a.churn_flag,
       ROUND(100.0 * SUM(CASE WHEN st.escalation_flag = 'TRUE' THEN 1 ELSE 0 END)
             / COUNT(st.ticket_id), 2) AS escalation_rate_percent
FROM ravenstack_accounts AS a
LEFT JOIN ravenstack_support_tickets AS st ON a.account_id = st.account_id
GROUP BY a.churn_flag;

-- Downgrade status vs subscription churn
SELECT downgrade_flag,
       COUNT(*) AS total_subscriptions,
       SUM(CASE WHEN churn_flag = 'TRUE' THEN 1 ELSE 0 END) AS churned_subscriptions,
       ROUND(100.0 * SUM(CASE WHEN churn_flag = 'TRUE' THEN 1 ELSE 0 END) / COUNT(*), 2)
       AS subscription_churn_rate_percent
FROM ravenstack_subscriptions
GROUP BY downgrade_flag;

-- Upgrade status vs subscription churn
SELECT upgrade_flag,
       COUNT(*) AS total_subscriptions,
       SUM(CASE WHEN churn_flag = 'TRUE' THEN 1 ELSE 0 END) AS churned_subscriptions,
       ROUND(100.0 * SUM(CASE WHEN churn_flag = 'TRUE' THEN 1 ELSE 0 END) / COUNT(*), 2)
       AS subscription_churn_rate_percent
FROM ravenstack_subscriptions
GROUP BY upgrade_flag;


-- 6. DEVTOOLS FOLLOW-UP INVESTIGATION
-- DevTools showed the highest customer churn rate (~30.97%).

-- Churn reasons within DevTools
SELECT ce.reason_code, COUNT(*) AS churn_events
FROM ravenstack_churn_events AS ce
LEFT JOIN ravenstack_accounts AS a ON ce.account_id = a.account_id
WHERE a.industry = 'DevTools'
GROUP BY ce.reason_code
ORDER BY churn_events DESC;

-- Support performance by industry
SELECT a.industry,
       AVG(st.first_response_time_minutes) AS average_first_response_time,
       AVG(st.resolution_time_hours) AS average_resolution_time,
       AVG(st.satisfaction_score) AS average_satisfaction
FROM ravenstack_accounts AS a
LEFT JOIN ravenstack_support_tickets AS st ON a.account_id = st.account_id
GROUP BY a.industry
ORDER BY average_satisfaction;

-- Product usage by industry
SELECT a.industry,
       AVG(account_usage.total_usage) AS average_total_usage
FROM ravenstack_accounts AS a
LEFT JOIN (
    SELECT s.account_id, SUM(fu.usage_count) AS total_usage
    FROM ravenstack_subscriptions AS s
    LEFT JOIN ravenstack_feature_usage AS fu
        ON s.subscription_id = fu.subscription_id
    GROUP BY s.account_id
) AS account_usage ON a.account_id = account_usage.account_id
GROUP BY a.industry
ORDER BY average_total_usage DESC;

-- END OF ANALYSIS
