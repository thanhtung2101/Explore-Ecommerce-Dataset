# Explore-Ecommerce-Dataset
# [SQL] Phân Tích Dữ Liệu Thương Mại Điện Tử (E-commerce)

## I. Giới thiệu dự án (Introduction)
Dự án này tập trung vào việc khai thác và phân tích tập dữ liệu Thương mại điện tử (eCommerce dataset) sử dụng ngôn ngữ truy vấn **SQL** trên nền tảng **[Google BigQuery](https://cloud.google.com/bigquery)**. 

Tập dữ liệu được trích xuất từ Google Analytics (public dataset), bao gồm các thông tin chi tiết về các phiên truy cập trang web (web sessions), hành vi người dùng, nguồn lưu lượng (traffic sources) và các giao dịch mua hàng trực tuyến thực tế. Mục tiêu của dự án là tìm ra các "insights" (sự thật ngầm hiểu) có giá trị kinh doanh, giúp tối ưu hóa tỷ lệ chuyển đổi và tăng trưởng doanh thu.

## II. Yêu cầu hệ thống (Requirements)
Để thực thi và tái tạo lại các phân tích trong dự án này, bạn cần chuẩn bị:
* Tài khoản [Google Cloud Platform (GCP)](https://cloud.google.com).
* Một Project đã được khởi tạo trên Google Cloud Platform.
* Kích hoạt [Google BigQuery API](https://cloud.google.com/bigquery/docs/enable-transfer-service).
* Môi trường thực thi: [Trình chỉnh sửa truy vấn SQL của BigQuery](https://cloud.google.com/monitoring/mql/query-editor) hoặc các IDE tương đương.

## III. Truy cập tập dữ liệu (Dataset Access)
Tập dữ liệu eCommerce được lưu trữ công khai trên Google BigQuery. Dưới đây là các bước để truy cập:
1. Đăng nhập vào Google Cloud Platform và chọn Project của bạn.
2. Điều hướng đến giao diện điều khiển (console) của BigQuery.
3. Trong bảng điều hướng bên trái, chọn **"Add Data"** (Thêm dữ liệu) -> **"Search a project"** (Tìm kiếm dự án).
4. Nhập Project ID: `bigquery-public-data.google_analytics_sample.ga_sessions` và nhấn Enter.
5. Click vào bảng `ga_sessions_*` để bắt đầu khám phá cấu trúc dữ liệu (schema) và thực hiện truy vấn.

## IV. Khám phá và Phân tích Dữ liệu (Exploring the Dataset)
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
* **Kết quả truy vấn:**
<img width="761" height="128" alt="image" src="https://github.com/user-attachments/assets/c3cfca19-95f9-4699-83fb-ae25a37560f0" />

