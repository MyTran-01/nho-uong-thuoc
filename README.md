# Nhớ Thuốc (tên tạm) · Tài liệu sản phẩm

Bản gốc duy nhất của tài liệu sản phẩm: PRD, user flow, task, nghiệm thu, quy trình, prompt. Người phụ trách sản phẩm làm chủ, agent commit thẳng `main`.

- Code nằm ở `../app/` (repo riêng, chưa tạo). Tài liệu không bao giờ nằm trong repo code.
- Làm theo Danh Method: `process/design-workflow.md`. Cách làm việc: `process/operator-my.md`. Cấu hình: `process/project.md`.

## Quy tắc
1. Mỗi feature một thư mục trong `features/`, tên file cố định: `PRD.md`, `USER_FLOW.md`, `GUIDANCE.md`, `TASKS.md`, `REVIEW.md`, `DESIGN-NOTES.md`, `ACCEPTANCE-<ngày>.md`, `prototype/`, `review-screens/`.
2. Sửa tài liệu nào thì thêm 1 dòng vào "Chưa release" của `CHANGELOG.md`.
3. `sources/` chỉ đọc. Bản mới thì thêm file mới có ngày trong tên.
4. Giả định chưa được duyệt ghi rõ là *giả định*.
5. Không chép đơn thuốc thật vào đây. Dữ liệu mẫu là hư cấu.

## Mục lục
| File | Là gì | Trạng thái |
|---|---|---|
| `features/med-reminder-v1/PRD.md` | PRD bản đầu: nhắc theo lần uống, chụp đơn, ảnh vỉ, ghi nhận | 05/11/2026 · nháp 0.3, chờ duyệt lần cuối |
| `features/med-reminder-v1/USER_FLOW.md` | Màn hình, đường vào, task, luồng chính | 05/11/2026 · nháp, chờ duyệt ngoại lệ X1 |
| `process/project.md` | Stack SwiftUI, lưu trên máy, kích thước kiểm | 05/11/2026 · chờ duyệt giả định |
| `sources/2026-11-05-painpoint-nguoi-dung.md` | Painpoint gốc | 05/11/2026 |
