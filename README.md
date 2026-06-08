Project lưu trữ các script SQL Server dùng để export danh sách từ hệ thống dữ liệu.

## Cấu Trúc Thư Mục

```
sql-export-scripts/
├── README.md                          # Tài liệu hướng dẫn
├── templates/                          # Các template script
│   ├── export_list_template.sql       # Template cơ bản
│   └── export_with_filter.sql         # Template có lọc dữ liệu
├── exports/                            # Các script export thực tế
│   ├── customers/                     # Export danh sách khách hàng
│   ├── products/                      # Export danh sách sản phẩm
│   ├── orders/                        # Export danh sách đơn hàng
│   └── reports/                       # Export báo cáo
└── docs/                               # Tài liệu kỹ thuật
    └── USAGE_GUIDE.md                 # Hướng dẫn sử dụng chi tiết
```

## Hướng Dẫn Sử Dụng

### 1. Quy Ước Đặt Tên Script
- Tên script phải rõ ràng mô tả nội dung export
- Định dạng: `export_[tên_danh_sách]_[ngày_tạo].sql`
- Ví dụ: `export_customers_2026_06_08.sql`

### 2. Cấu Trúc Script Cơ Bản
Mỗi script export cần bao gồm:
- Comment header với mô tả
- Tên database và table
- Các cột cần export
- Điều kiện lọc (nếu có)

### 3. Chạy Script
```sql
-- Kết nối SQL Server
USE [DatabaseName];
GO

-- Chạy script export
EXEC sp_executesql N'SELECT ...'
```

### 4. Export Kết Quả
- Lưu kết quả thành file CSV hoặc Excel
- Đặt tên file rõ ràng với ngày export
- Lưu trong folder `exports/[loại_danh_sách]`

## Best Practices

✅ **Nên làm:**
- Thêm comment mô tả chi tiết từng script
- Thử test script trước khi commit
- Update README khi thêm script mới
- Sử dụng các tham số để script linh hoạt

❌ **Không nên làm:**
- Lưu script không liên quan đến export danh sách
- Để thông tin nhạy cảm trong script (password, keys)
- Commit script chưa test

## Liên Hệ & Hỗ Trợ

Nếu có câu hỏi hoặc cần hỗ trợ, vui lòng tạo issue hoặc liên hệ với team.
