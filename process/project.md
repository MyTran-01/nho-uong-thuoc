# App nhắc uống thuốc · Project config
Cập nhật: 05/11/2026 · bởi agent điều phối (chờ người phụ trách sản phẩm duyệt)

Tên tạm của sản phẩm: **Nhớ Thuốc** (*giả định*, xem Q20 trong PRD).

## Repo
| Repo | Đường dẫn | Nhánh chính | Ai push |
|---|---|---|---|
| Spec | `<thư mục dự án>/docs` | main | người phụ trách sản phẩm + agent của họ, push thẳng |
| Code | `<thư mục dự án>/app` (*chưa tạo*) | main | chỉ qua nhánh feature; người phụ trách sản phẩm duyệt merge |

Tài liệu và code tách riêng tuyệt đối: repo code chặn `docs/`, `research/`, `HANDOFF*.md` trong `.gitignore`.

## Stack
- App: **SwiftUI native**, chỉ iPhone. iOS tối thiểu: 26. Máy thật để thử: **iPhone 15 Pro, iOS 27** (người dùng nói "thì phải", xác nhận khi cắm máy). Máy có Apple Intelligence.
- Lưu dữ liệu: SwiftData, **chỉ trên máy**, không tài khoản, không server (xem M03).
- Nhắc: `UserNotifications` (local notification, time-sensitive, có nút thao tác). Tuỳ chọn nhắc kiểu báo thức: AlarmKit (iOS 26+).
- Đọc đơn: Vision (nhận dạng chữ, chạy trên máy). Tách thuốc từ chữ: luật phân tích + tuỳ chọn Apple Foundation Models (trên máy) nếu thiết bị hỗ trợ.
- Test: Swift Testing (logic) + XCUITest (luồng chính).
- Máy làm: macOS, Xcode, iOS Simulator.

## Design system
- Nền: **component hệ thống của iOS (SwiftUI) theo Apple HIG.**
  Ngoại lệ so với luật Danh Method "chỉ shadcn/ui hoặc HeroUI": hai thư viện đó dành cho web, không dùng được cho app SwiftUI native. Preview HTML (G1) sẽ mô phỏng component iOS.
- Token: màu thương hiệu, cỡ chữ theo Dynamic Type, bo góc, khoảng cách. Chốt ở bước `design-tokens` (G0). File: `design-system/tokens.html` (chưa có).
- ui-ux-pro-max: chưa cài, hỏi ở bước token.
- Icon: SF Symbols.

## Kiểm tra
- Kích thước màn kiểm UI: iPhone SE (375×667), iPhone 17 (402×874), iPhone 17 Pro Max (440×956). Light + dark. Dynamic Type mặc định và cỡ lớn (AX1).
  Thay cho 1440/768/390 của web.
- Verify-kit: cài khi đã có repo code.

## Môi trường
- Không có server, không có cổng dev.
- Ảnh đơn thuốc và vỉ thuốc: chỉ lưu trong app trên máy.
- Dữ liệu mẫu để test: hư cấu, nằm trong test fixture, không dùng đơn thật.

## Quyền
- Người phụ trách sản phẩm: designer, quyết sản phẩm/UX, duyệt merge (*giả định*).
- App một người dùng, không có role.

## Ngôn ngữ
- UI: **tiếng Việt** · Trao đổi: tiếng Việt · Commit: English (`feat:`, `fix:`, `docs:`).
