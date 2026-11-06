# Cách làm việc với My · designer

Áp dụng cho mọi agent (Claude, Codex, Antigravity…) khi làm cho My trên dự án app nhắc uống thuốc. File này bổ sung cho quy tắc chung trong repo code. Khi khác nhau: quy tắc repo thắng ở phần code, file này thắng ở cách làm việc với người này. **Không commit file này vào repo code.**

## 1. Người này là ai
- Vai: Designer, đồng thời là người phụ trách sản phẩm và là người dùng đầu tiên của app.
- Quyết: sản phẩm / UX. *Giả định:* cũng là người duyệt merge cuối (G3), vì dự án cá nhân chưa có owner kỹ thuật riêng.

## 2. Giao tiếp
- Trả lời tiếng Việt, ngắn, đơn giản. Chữ trên UI: **tiếng Việt** (ngoại lệ so với mặc định Danh Method).
- Không đưa lệnh terminal hay việc thủ công nhỏ. Agent tự chạy lệnh, tự xử lý lỗi môi trường (Xcode, simulator).
- Báo theo những gì thấy trên màn hình iPhone; nêu bước tiếp theo; không giải thích lại việc đã xong.
- Trước quyết định lớn hoặc yêu cầu mơ hồ: hỏi trước, nêu lựa chọn và hệ quả. Câu hỏi phải nói rõ luồng nào, vấn đề gì.
- Thấy mâu thuẫn, lỗi, rủi ro (kể cả của chính agent) thì nói ngay.
- Báo tối đa 3 điểm đạt / 3 điểm cần sửa / 1 quyết định; ưu tiên ảnh chụp màn hình.

## 3. Gate bắt buộc
- Tài liệu (PRD / USER_FLOW / TASKS) được duyệt trước khi code.
- Việc có UI: preview HTML được duyệt trước khi code UI.
- Duyệt xong chỉ làm đúng mục đã duyệt.

## 4. Nhánh & git
- Mỗi feature một nhánh từ `main` mới nhất, chỉ khi `git status` sạch.
- Không commit thẳng `main` của repo code, không force push, không xoá nhánh.
- Không reset / stash / clean việc dở. Sai thì `git revert` bằng commit mới.
- Không commit `CLAUDE.local.md`, `AGENTS.override.md`, `.env`, `.verify/`.

## 5. Công cụ
- Superpowers: đã cài, dùng để giữ kỷ luật thi hành.
- ui-ux-pro-max: chưa cài, sẽ hỏi xin phép ở bước chốt token.
- Xem app: chạy trên iOS Simulator, mở panel cho My xem trực tiếp.

## 6. Tài liệu
- Repo spec: `docs/` trong thư mục dự án. Agent sửa và commit thẳng `main` của repo spec, thêm 1 dòng "Chưa release" vào CHANGELOG.
- Prompt lưu ở `prompts/YYYY-MM-DD-<chủ-đề>.md`.
- Không ghi tên người hay luật riêng vào repo code; dùng vai trò.

## 7. Ngoại lệ riêng
- Máy Mac (macOS). Dùng Xcode và iOS Simulator.
- Dữ liệu mẫu trong tài liệu là hư cấu; không chép đơn thuốc thật vào repo.
