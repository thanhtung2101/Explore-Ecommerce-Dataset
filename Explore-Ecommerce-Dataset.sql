/* ==========================================================================
   E-COMMERCE DATA ANALYSIS PROJECT 
   Dataset: Google Analytics Sample (BigQuery Public Data)
   ========================================================================== */

-- --------------------------------------------------------------------------
-- Query 01: Tính toán tổng số lượt truy cập (Visits), số trang xem (Pageviews) 
-- và giao dịch (Transactions) theo từng tháng trong Quý 1 năm 2017.
-- --------------------------------------------------------------------------
SELECT 
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month, -- Chuyển đổi chuỗi ngày sang định dạng YYYYMM
    SUM(totals.visits) AS visits,
    SUM(totals.pageviews) AS pageviews,
    SUM(totals.transactions) AS transactions
FROM 
    `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` 
WHERE 
    _table_suffix BETWEEN '0101' AND '0331' -- Lọc dữ liệu từ tháng 1 đến tháng 3
GROUP BY 
    month
ORDER BY 
    month;


-- --------------------------------------------------------------------------
-- Query 02: Phân tích Tỷ lệ thoát (Bounce Rate) theo từng nguồn truy cập 
-- (Traffic Source) trong tháng 07/2017.
-- --------------------------------------------------------------------------
SELECT
    trafficSource.source, 
    SUM(totals.visits) AS total_visits,
    SUM(totals.bounces) AS total_nu_of_bounces,
    ROUND(100 * (SUM(totals.bounces) / SUM(totals.visits)), 4) AS bounce_rate
FROM 
    `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` 
GROUP BY 
    trafficSource.source
ORDER BY 
    total_visits DESC;


-- --------------------------------------------------------------------------
-- Query 03: Thống kê Doanh thu (Revenue) theo Nguồn truy cập, 
-- phân tách chi tiết theo Tháng và Tuần trong tháng 06/2017.
-- Sử dụng UNION ALL để gộp 2 cấp độ thời gian vào cùng một báo cáo.
-- --------------------------------------------------------------------------
SELECT 
    'Month' AS time_type,
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS time,
    trafficSource.source AS source,
    SUM(p.productRevenue) / 1000000 AS revenue -- Quy đổi doanh thu về đơn vị triệu
FROM 
    `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
    UNNEST(hits) AS h,
    UNNEST(h.product) AS p
WHERE 
    p.productRevenue IS NOT NULL
GROUP BY 
    1, 2, 3

UNION ALL

SELECT 
    'Week' AS time_type,
    FORMAT_DATE('%Y%W', PARSE_DATE('%Y%m%d', date)) AS time,
    trafficSource.source AS source,
    SUM(p.productRevenue) / 1000000 AS revenue
FROM 
    `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
    UNNEST(hits) AS h,
    UNNEST(h.product) AS p
WHERE 
    p.productRevenue IS NOT NULL
GROUP BY 
    1, 2, 3
ORDER BY 
    revenue DESC;


-- --------------------------------------------------------------------------
-- Query 04: Đánh giá hiệu quả của các Nguồn truy cập thông qua 
-- Tỷ lệ chuyển đổi (Conversion Rate) trong năm 2017.
-- Chỉ xét các nguồn mang lại từ 50 giao dịch trở lên để đảm bảo tính đại diện.
-- --------------------------------------------------------------------------
SELECT 
    trafficSource.source AS source,
    SUM(totals.visits) AS visits,
    SUM(totals.transactions) AS transactions,
    100 * (SUM(totals.transactions) / SUM(totals.visits)) AS conversion_rate
FROM 
    `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` 
GROUP BY 
    source
HAVING 
    transactions >= 50
ORDER BY 
    conversion_rate DESC;


-- --------------------------------------------------------------------------
-- Query 05: So sánh hành vi người dùng: Trung bình số trang xem (Pageviews) 
-- của nhóm Khách hàng đã mua hàng (Purchaser) vs Nhóm chưa mua (Non-purchaser).
-- Dữ liệu tháng 06 và 07 năm 2017.
-- --------------------------------------------------------------------------
WITH purchaser_data AS (
    -- Tập khách hàng có phát sinh giao dịch thành công
    SELECT
        FORMAT_DATE("%Y%m", PARSE_DATE("%Y%m%d", date)) AS month,
        SUM(totals.pageviews) / COUNT(DISTINCT fullVisitorId) AS avg_pageviews_purchase
    FROM
        `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
        UNNEST(hits) AS hits,
        UNNEST(hits.product) AS product
    WHERE
        _table_suffix BETWEEN '0601' AND '0731'
        AND totals.transactions >= 1
        AND product.productRevenue IS NOT NULL
    GROUP BY 
        1
),
non_purchaser_data AS (
    -- Tập khách hàng không phát sinh giao dịch
    SELECT
        FORMAT_DATE("%Y%m", PARSE_DATE("%Y%m%d", date)) AS month,
        SUM(totals.pageviews) / COUNT(DISTINCT fullVisitorId) AS avg_pageviews_non_purchase
    FROM
        `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
        UNNEST(hits) AS hits,
        UNNEST(hits.product) AS product
    WHERE
        _table_suffix BETWEEN '0601' AND '0731'
        AND totals.transactions IS NULL
        AND product.productRevenue IS NULL
    GROUP BY 
        1
)
-- Kết hợp dữ liệu 2 nhóm để so sánh trực diện theo từng tháng
SELECT
    pd.month,
    pd.avg_pageviews_purchase,
    nd.avg_pageviews_non_purchase
FROM
    purchaser_data pd
FULL JOIN
    non_purchaser_data nd USING(month)
ORDER BY
    pd.month;


-- --------------------------------------------------------------------------
-- Query 06: Tính trung bình số lượng giao dịch trên mỗi người dùng 
-- (những người có thực hiện mua hàng) trong tháng 07/2017.
-- --------------------------------------------------------------------------
SELECT
    FORMAT_DATE("%Y%m", PARSE_DATE("%Y%m%d", date)) AS month,
    SUM(totals.transactions) / COUNT(DISTINCT fullVisitorId) AS avg_total_transactions_per_user
FROM 
    `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
WHERE 
    totals.transactions >= 1
    AND product.productRevenue IS NOT NULL -- Đảm bảo tính chính xác của giao dịch
GROUP BY 
    1;


-- --------------------------------------------------------------------------
-- Query 07: Phân bổ doanh thu theo Loại thiết bị (Device Category) 
-- và tính toán tỷ trọng (%) của từng thiết bị so với tổng doanh thu.
-- --------------------------------------------------------------------------
WITH device_data AS (
    SELECT 
        device.deviceCategory AS device,
        SUM(product.productRevenue) / 1000000 AS revenue_by_device
    FROM
        `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        UNNEST(hits) AS hits,
        UNNEST(hits.product) AS product
    WHERE     
        totals.transactions IS NOT NULL
        AND product.productRevenue IS NOT NULL
    GROUP BY 
        device
)
SELECT
    device,
    revenue_by_device,
    -- Sử dụng Window Function để tính tổng doanh thu toàn hệ thống
    SUM(revenue_by_device) OVER() AS total_revenue,
    (revenue_by_device / SUM(revenue_by_device) OVER()) * 100 AS ratio
FROM
    device_data
ORDER BY
    revenue_by_device DESC;


-- --------------------------------------------------------------------------
-- Query 08: Phân tích giỏ hàng (Market Basket Analysis) - Mua chéo (Cross-sell).
-- Xác định các sản phẩm khác được mua cùng bởi những khách hàng 
-- đã mua sản phẩm "YouTube Men's Vintage Henley" trong tháng 07/2017.
-- --------------------------------------------------------------------------
SELECT
    product.v2ProductName AS other_purchased_products,
    SUM(product.productQuantity) AS quantity
FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
WHERE 
    totals.transactions >= 1
    AND product.productRevenue IS NOT NULL 
    AND product.v2ProductName != "YouTube Men's Vintage Henley" -- Loại trừ sản phẩm gốc
    AND fullVisitorId IN (
        -- Tìm tệp khách hàng đã mua áo "YouTube Men's Vintage Henley"
        SELECT 
            DISTINCT(fullVisitorId)
        FROM 
            `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
            UNNEST(hits) AS hits,
            UNNEST(hits.product) AS product
        WHERE  
            product.v2ProductName = "YouTube Men's Vintage Henley" 
            AND totals.transactions >= 1
            AND product.productRevenue IS NOT NULL 
    )
GROUP BY 
    other_purchased_products	
ORDER BY 
    quantity DESC;


-- --------------------------------------------------------------------------
-- Query 09: Xây dựng Phễu chuyển đổi (Conversion Funnel).
-- Theo dõi hành trình từ Xem sản phẩm -> Thêm vào giỏ hàng -> Thanh toán
-- trong Quý 1 năm 2017.
-- --------------------------------------------------------------------------
WITH cohort_map AS (
    SELECT 
        FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
        SUM(CASE WHEN eCommerceAction.action_type = '2' THEN 1 ELSE 0 END) AS num_product_view,
        SUM(CASE WHEN eCommerceAction.action_type = '3' THEN 1 ELSE 0 END) AS num_addtocart,
        SUM(CASE WHEN eCommerceAction.action_type = '6' AND product.productRevenue IS NOT NULL THEN 1 ELSE 0 END) AS num_purchase
    FROM 
        `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
        UNNEST(hits) AS hits,
        UNNEST(hits.product) AS product
    WHERE 
        _table_suffix BETWEEN '0101' AND '0331'
    GROUP BY 
        month
    ORDER BY 
        month
)
SELECT 
    month,
    num_product_view,
    num_addtocart,
    num_purchase,
    ROUND(100 * (num_addtocart / num_product_view), 2) AS add_to_cart_rate,
    ROUND(100 * (num_purchase / num_product_view), 2) AS purchase_rate
FROM 
    cohort_map;


-- --------------------------------------------------------------------------
-- Query 10: Phân tích xu hướng Doanh thu theo tuần (Weekly Revenue) 
-- và Doanh thu lũy kế (Cumulative Revenue) từ tháng 05 đến tháng 07 năm 2017.
-- --------------------------------------------------------------------------
WITH week_revenue AS (
    SELECT 
        FORMAT_DATE('%Y-%W', PARSE_DATE('%Y%m%d', date)) AS week,
        ROUND(SUM(product.productRevenue) / 1000000, 2) AS weekly_revenue
    FROM 
        `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
        UNNEST(hits) AS hits,
        UNNEST(hits.product) AS product
    WHERE 
        _table_suffix BETWEEN '0501' AND '0731'
        AND product.productRevenue IS NOT NULL
    GROUP BY 
        week
    ORDER BY 
        week
)
SELECT 
    week,
    weekly_revenue,
    -- Sử dụng Window Function gộp doanh thu dồn theo thứ tự tuần
    ROUND(SUM(weekly_revenue) OVER(ORDER BY week), 2) AS cumulative_revenue
FROM 
    week_revenue;