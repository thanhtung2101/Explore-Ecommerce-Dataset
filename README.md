# Explore-Ecommerce-Dataset
# [SQL] Phân Tích Dữ Liệu Thương Mại Điện Tử (E-commerce)

## I. Giới thiệu dự án 
Dự án này tập trung vào việc khai thác và phân tích tập dữ liệu Thương mại điện tử (eCommerce dataset) sử dụng ngôn ngữ truy vấn **SQL** trên nền tảng **[Google BigQuery](https://cloud.google.com/bigquery)**. 

Tập dữ liệu được trích xuất từ Google Analytics (public dataset), bao gồm các thông tin chi tiết về các phiên truy cập trang web (web sessions), hành vi người dùng, nguồn lưu lượng (traffic sources) và các giao dịch mua hàng trực tuyến thực tế. Mục tiêu của dự án là tìm ra các "insights" (sự thật ngầm hiểu) có giá trị kinh doanh, giúp tối ưu hóa tỷ lệ chuyển đổi và tăng trưởng doanh thu.

## II. Yêu cầu hệ thống 
Để thực thi và tái tạo lại các phân tích trong dự án này, bạn cần chuẩn bị:
* Tài khoản [Google Cloud Platform (GCP)](https://cloud.google.com).
* Một Project đã được khởi tạo trên Google Cloud Platform.
* Kích hoạt [Google BigQuery API](https://cloud.google.com/bigquery/docs/enable-transfer-service).
* Môi trường thực thi: [Trình chỉnh sửa truy vấn SQL của BigQuery](https://cloud.google.com/monitoring/mql/query-editor) hoặc các IDE tương đương.

## III. Truy cập tập dữ liệu 
Tập dữ liệu eCommerce được lưu trữ công khai trên Google BigQuery. Dưới đây là các bước để truy cập:
1. Đăng nhập vào Google Cloud Platform và chọn Project của bạn.
2. Điều hướng đến giao diện điều khiển (console) của BigQuery.
3. Trong bảng điều hướng bên trái, chọn **"Add Data"** (Thêm dữ liệu) -> **"Search a project"** (Tìm kiếm dự án).
4. Nhập Project ID: `bigquery-public-data.google_analytics_sample.ga_sessions` và nhấn Enter.
5. Click vào bảng `ga_sessions_*` để bắt đầu khám phá cấu trúc dữ liệu (schema) và thực hiện truy vấn.

## IV. Khám phá và Phân tích Dữ liệu 
Trong dự án này, tôi đã thiết kế và thực thi 10 truy vấn SQL nâng cao để giải quyết các bài toán kinh doanh cụ thể.

### Query 01: Tính toán tổng số lượt truy cập (Visits), số trang xem (Pageviews) và giao dịch (Transactions) theo từng tháng (Q1/2017)
* **Câu lệnh SQL:**
```sql
SELECT 
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    SUM(totals.visits) AS visits,
    SUM(totals.pageviews) AS pageviews,
    SUM(totals.transactions) AS transactions
FROM 
    `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` 
WHERE 
    _table_suffix BETWEEN '0101' AND '0331'
GROUP BY 
    month
ORDER BY 
    month;
```
* **Kết quả truy vấn:**
<img width="771" height="139" alt="image" src="https://github.com/user-attachments/assets/eb7ae1b3-be0d-4fd5-8cc2-bf8958686d5b" />

### Query 02: Phân tích Tỷ lệ thoát (Bounce Rate) theo từng nguồn truy cập (Tháng 07/2017)
* **Câu lệnh SQL:**
```sql
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
```
* **Kết quả truy vấn:**
<img width="769" height="363" alt="image" src="https://github.com/user-attachments/assets/6a6d7190-d0f5-40a6-ad8e-d512e8042f5d" />

### Query 03: Thống kê Doanh thu theo Nguồn truy cập, phân tách chi tiết theo Tháng và Tuần (Tháng 06/2017)
* **Câu lệnh SQL:**
```sql
SELECT 
    'Month' AS time_type,
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS time,
    trafficSource.source AS source,
    SUM(p.productRevenue) / 1000000 AS revenue
FROM 
    `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
    UNNEST(hits) AS h, UNNEST(h.product) AS p
WHERE 
    p.productRevenue IS NOT NULL
GROUP BY 1, 2, 3
UNION ALL
SELECT 
    'Week' AS time_type,
    FORMAT_DATE('%Y%W', PARSE_DATE('%Y%m%d', date)) AS time,
    trafficSource.source AS source,
    SUM(p.productRevenue) / 1000000 AS revenue
FROM 
    `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
    UNNEST(hits) AS h, UNNEST(h.product) AS p
WHERE 
    p.productRevenue IS NOT NULL
GROUP BY 1, 2, 3
ORDER BY revenue DESC;
```
* **Kết quả truy vấn:**
<img width="952" height="369" alt="image" src="https://github.com/user-attachments/assets/0414c901-80ea-4f3d-9cc7-daf39dbcac61" />

### Query 04: Đánh giá Tỷ lệ chuyển đổi (Conversion Rate) của các Nguồn truy cập
* **Câu lệnh SQL:**
```sql
SELECT 
    trafficSource.source AS source,
    SUM(totals.visits) AS visits,
    SUM(totals.transactions) AS transactions,
    100 * (SUM(totals.transactions) / SUM(totals.visits)) AS conversion_rate
FROM 
    `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` 
GROUP BY source
HAVING transactions >= 50
ORDER BY conversion_rate DESC;
```
* **Kết quả truy vấn:**
<img width="767" height="143" alt="image" src="https://github.com/user-attachments/assets/3c507e7f-30c3-4892-8bc0-eb394ff9b2c2" />

### Query 05: So sánh trung bình số trang xem (Pageviews) giữa nhóm Mua hàng (Purchasers) và Không mua (Non-purchasers) (Tháng 06, 07/2017)
* **Câu lệnh SQL:**
```sql
WITH purchaser_data AS (
    SELECT
        FORMAT_DATE("%Y%m", PARSE_DATE("%Y%m%d", date)) AS month,
        SUM(totals.pageviews) / COUNT(DISTINCT fullVisitorId) AS avg_pageviews_purchase
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits, UNNEST(hits.product) AS product
    WHERE _table_suffix BETWEEN '0601' AND '0731' AND totals.transactions >= 1 AND product.productRevenue IS NOT NULL
    GROUP BY 1
),
non_purchaser_data AS (
    SELECT
        FORMAT_DATE("%Y%m", PARSE_DATE("%Y%m%d", date)) AS month,
        SUM(totals.pageviews) / COUNT(DISTINCT fullVisitorId) AS avg_pageviews_non_purchase
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits, UNNEST(hits.product) AS product
    WHERE _table_suffix BETWEEN '0601' AND '0731' AND totals.transactions IS NULL AND product.productRevenue IS NULL
    GROUP BY 1
)
SELECT pd.month, pd.avg_pageviews_purchase, nd.avg_pageviews_non_purchase
FROM purchaser_data pd
FULL JOIN non_purchaser_data nd USING(month)
ORDER BY pd.month;
```
* **Kết quả truy vấn:**
<img width="620" height="114" alt="image" src="https://github.com/user-attachments/assets/1b69aea9-9f93-4cbc-b2a3-90dae5eff4fa" />

### Query 06: Tính trung bình số giao dịch trên mỗi khách hàng đã mua sắm (Tháng 07/2017)
* **Câu lệnh SQL:**
```sql
SELECT
    FORMAT_DATE("%Y%m", PARSE_DATE("%Y%m%d", date)) AS month,
    SUM(totals.transactions) / COUNT(DISTINCT fullVisitorId) AS avg_total_transactions_per_user
FROM 
    `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST(hits) AS hits, UNNEST(hits.product) AS product
WHERE 
    totals.transactions >= 1 AND product.productRevenue IS NOT NULL
GROUP BY 1;
```
* **Kết quả truy vấn:**
<img width="469" height="80" alt="image" src="https://github.com/user-attachments/assets/c8db6ac9-5a16-4408-9a72-612c159067c0" />

### Query 07: Tỷ trọng doanh thu theo Thiết bị truy cập (Device Category)
* **Câu lệnh SQL:**
```sql
WITH device_data AS (
    SELECT 
        device.deviceCategory AS device,
        SUM(product.productRevenue) / 1000000 AS revenue_by_device
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hits, UNNEST(hits.product) AS product
    WHERE totals.transactions IS NOT NULL AND product.productRevenue IS NOT NULL
    GROUP BY device
)
SELECT
    device,
    revenue_by_device,
    SUM(revenue_by_device) OVER() AS total_revenue,
    (revenue_by_device / SUM(revenue_by_device) OVER()) * 100 AS ratio
FROM device_data
ORDER BY revenue_by_device DESC;
```
* **Kết quả truy vấn:**
<img width="769" height="147" alt="image" src="https://github.com/user-attachments/assets/32ea71c2-59bc-4090-bf7b-157eabef0c5b" />

### Query 08: Phân tích giỏ hàng (Cross-sell): Các sản phẩm được mua kèm với "YouTube Men's Vintage Henley" (Tháng 07/2017)
* **Câu lệnh SQL:**
```sql
SELECT
    product.v2ProductName AS other_purchased_products,
    SUM(product.productQuantity) AS quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
UNNEST(hits) AS hits, UNNEST(hits.product) AS product
WHERE totals.transactions >= 1 AND product.productRevenue IS NOT NULL AND product.v2ProductName != "YouTube Men's Vintage Henley"
AND fullVisitorId IN (
    SELECT DISTINCT(fullVisitorId)
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST(hits) AS hits, UNNEST(hits.product) AS product
    WHERE product.v2ProductName = "YouTube Men's Vintage Henley" AND totals.transactions >= 1 AND product.productRevenue IS NOT NULL 
)
GROUP BY other_purchased_products	
ORDER BY quantity DESC;
```
* **Kết quả truy vấn:**
<img width="473" height="366" alt="image" src="https://github.com/user-attachments/assets/a36b6a38-8e87-4365-86b5-17718e9877aa" />


### Query 09: Xây dựng Phễu chuyển đổi (Conversion Funnel): Xem SP -> Thêm vào giỏ -> Mua hàng (Q1/2017)
* **Câu lệnh SQL:**
```sql
WITH cohort_map AS (
    SELECT 
        FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
        SUM(CASE WHEN eCommerceAction.action_type = '2' THEN 1 ELSE 0 END) AS num_product_view,
        SUM(CASE WHEN eCommerceAction.action_type = '3' THEN 1 ELSE 0 END) AS num_addtocart,
        SUM(CASE WHEN eCommerceAction.action_type = '6' AND product.productRevenue IS NOT NULL THEN 1 ELSE 0 END) AS num_purchase
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits, UNNEST(hits.product) AS product
    WHERE _table_suffix BETWEEN '0101' AND '0331'
    GROUP BY month
    ORDER BY month
)
SELECT 
    month, num_product_view, num_addtocart, num_purchase,
    ROUND(100 * (num_addtocart / num_product_view), 2) AS add_to_cart_rate,
    ROUND(100 * (num_purchase / num_product_view), 2) AS purchase_rate
FROM cohort_map;
```
* **Kết quả truy vấn:**
<img width="1065" height="138" alt="image" src="https://github.com/user-attachments/assets/81feea3e-ad32-4266-b44a-2fd0b419b26d" />

### Query 10: Phân tích xu hướng Doanh thu theo tuần & Doanh thu lũy kế (05/2017 - 07/2017)
* **Câu lệnh SQL:**
```sql
WITH week_revenue AS (
    SELECT 
        FORMAT_DATE('%Y-%W', PARSE_DATE('%Y%m%d', date)) AS week,
        ROUND(SUM(product.productRevenue) / 1000000, 2) AS weekly_revenue
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits, UNNEST(hits.product) AS product
    WHERE _table_suffix BETWEEN '0501' AND '0731' AND product.productRevenue IS NOT NULL
    GROUP BY week
    ORDER BY week
)
SELECT 
    week, weekly_revenue,
    ROUND(SUM(weekly_revenue) OVER(ORDER BY week), 2) AS cumulative_revenue
FROM week_revenue;
```
* **Kết quả truy vấn:**
<img width="616" height="366" alt="image" src="https://github.com/user-attachments/assets/07a2f17e-91d6-4b48-82a0-005cb4e5ec11" />

## V. Kết luận & Hướng phát triển 
* Thông qua việc truy vấn và làm sạch tập dữ liệu quy mô lớn trên Google BigQuery, dự án đã bóc tách được các chỉ số quan trọng (Metrics) như lượng truy cập, tỷ lệ thoát (bounce rate), hiệu suất của từng nguồn Traffic và hành vi mua chéo (Cross-selling) của khách hàng.

* Phễu chuyển đổi (Conversion Funnel) cho thấy rõ rệt điểm rơi (drop-off) từ bước xem sản phẩm đến lúc thanh toán, mở ra cơ hội để tối ưu hóa trải nghiệm người dùng (UX) trên website.

* Hướng phát triển: Để đào sâu hơn vào các insight này, bước tiếp theo tôi sẽ trích xuất kết quả từ BigQuery và kết nối trực tiếp với phần mềm Power BI nhằm xây dựng một hệ thống Dashboard trực quan, tự động cập nhật và cho phép tương tác đa chiều.

* Tóm lại, dự án này là minh chứng rõ nét cho sức mạnh của SQL trong việc xử lý Big Data, làm nền tảng vững chắc để đưa ra các quyết định kinh doanh dựa trên dữ liệu (Data-driven decision making).

































