# Nhớ Thuốc · Token notes

## v0.1 · 05/11/2026 · đề xuất, **chờ duyệt G0**

- **Nền:** HeroUI v3.2.7 (`@heroui/react`, `@heroui/styles`), Tailwind v4.
- **Quyết định ngày 05/11/2026:** app vẫn viết bằng SwiftUI, chỉ lấy *phong cách* HeroUI. Token duyệt ở đây sẽ chuyển sang SwiftUI.
- **Token Playground** (component HeroUI thật): `heroui-lab/`. Chạy bằng Vite cổng 5181. File token nguồn: `heroui-lab/src/tokens.css`.
- **Có thêm khung "Nhớ Thuốc · xem thử trong app"** (390px) dựng bằng HeroUI Card / Checkbox / Button / Chip: màn đánh dấu đã uống, thẻ Hôm nay, chip chọn số phút, chip trạng thái, nút "Đã uống hết đơn này".
- **ui-ux-pro-max:** người dùng đồng ý cài nhưng plugin chưa có trên máy. Bản v0.1 này làm thủ công, chưa có gợi ý từ plugin.
- **Ảnh review:** chưa chụp vì máy chưa có Playwright. Đã kiểm bằng mắt trên trình duyệt ở 1440px, cả sáng và tối.

### Lựa chọn chính
| Nhóm | Sáng | Tối | Lý do |
|---|---|---|---|
| Màu chủ đạo (accent) | `#0f766e` ngọc lam đậm, chữ trắng | `#2dd4bf` ngọc sáng, chữ `#042f2e` | Cảm giác sức khoẻ, bình tĩnh. Không trùng màu xanh lá của "Đã uống đủ". |
| Nền trang / thẻ | `#f2f2f7` / `#ffffff` | `#000000` / `#1c1c1e` | Giống nền nhóm của iOS, để sau này chuyển sang SwiftUI không lệch. |
| Chữ chính / chữ phụ | `#111114` / `#52525b` | `#f4f4f5` / `#d4d4d8` | Chữ phụ đạt AAA trên thẻ, hợp với người lớn tuổi (M14). |
| Trạng thái | đủ `#15803d` · thiếu `#b45309` · lỗi/hết `#b91c1c` (đều chữ trắng) | bản sáng hơn, chữ tối | Trạng thái luôn kèm biểu tượng hình (✓ ◐ – !), không chỉ dựa vào màu (AC17). |
| Bo góc | `--radius: 0.75rem` (≈ 14px với cỡ chữ gốc 19px) · ô nhập ×1.25 | như sáng | Mềm, thân thiện, vẫn gọn. |
| Cỡ chữ gốc | `19px` (iOS mặc định 17) | — | Người lớn tuổi. Vẫn theo Dynamic Type khi sang SwiftUI. |
| Chiều cao nút chính / vùng chạm tối thiểu | `56px` / `48px` | — | M14. |
| Font | SF Pro của hệ thống | — | Có sẵn trên iPhone, rõ dấu tiếng Việt. Phương án "bo tròn" (SF Pro Rounded) chưa bật. |

### Tương phản (WCAG)
| Cặp | Sáng | Tối |
|---|---|---|
| Chữ chính / nền thẻ | 18.8:1 AAA | 15.5:1 AAA |
| Chữ chính / nền trang | 16.9:1 AAA | 19.1:1 AAA |
| Chữ phụ / nền thẻ | 7.7:1 AAA | 11.5:1 AAA |
| Chữ phụ / nền trang | 6.9:1 đạt AA | 14.2:1 AAA |
| Chữ trên nút chính | 5.5:1 đạt AA | 7.8:1 AAA |
| Màu chủ đạo làm chữ / nền thẻ | 5.5:1 đạt AA | 9.1:1 AAA |
| Nút phụ: chữ / nền | 14.9:1 AAA | 10.3:1 AAA |
| Chip "Đã uống đủ" | 5.0:1 đạt AA | 8.6:1 AAA |
| Chip "Còn thuốc chưa uống" | 5.0:1 đạt AA | 9.0:1 AAA |
| Nút "Đã uống hết đơn" / chip "Chưa đánh dấu" | 6.5:1 đạt AA | 5.8:1 đạt AA |
| Viền ô nhập / nền thẻ (cần ≥ 3:1) | **2.6:1 trượt** | 3.5:1 đạt |
| Nút chính / nền trang (cần ≥ 3:1) | 4.9:1 đạt | 11.3:1 đạt |

**Cặp trượt (chưa tự sửa, chờ người phụ trách quyết):**
- Viền ô nhập ở theme sáng: `--field-border` `#a1a1aa` chỉ đạt 2.6:1. Đề xuất đổi sang `#71717a` → 4.8:1.

### Màn thử trên iPhone ảo (SwiftUI) · 05/11/2026
- Code: repo `../app`, project `NhoThuoc.xcodeproj`. Màn `TokenLab/TokenLabView.swift`. Token: `DesignSystem/Tokens.swift`.
- **Đã kiểm trên iPhone 17 Pro ảo (iOS 26.5)**, cả sáng và tối:
  - Tích / bỏ tích thuốc chạy được, nút đổi thành "Đã uống (còn 1 thuốc chưa uống)".
  - Nút "Tuỳ chỉnh" mở bảng chọn. Đổi màu, cỡ chữ, kiểu chữ thấy ngay trên màn phía sau.
  - Bảng tương phản trong app tự tính lại theo lựa chọn.
- Ảnh: `token-review/ios-17pro-light-1-nhac.png`, `token-review/ios-17pro-dark-1-nhac.png`.
- **Hai chỗ lệch so với HeroUI gốc**, vì người lớn tuổi phải đọc được (M14):
  - Nút xám (secondary) dùng chữ màu chính thay vì chữ màu chủ đạo. Lý do: chữ ngọc lam trên nền xám chỉ đạt 4.3:1.
  - Viền nút chọn (outline) dùng màu viền ô nhập thay vì `--border`. Lý do: `--border` chỉ đạt 1.4:1 trên nền trắng.
- **Phát hiện mới:** chip "Sắp tới" kiểu nền nhạt (soft) ở chế độ sáng, màu ngọc lam, đạt **4.4:1, trượt AA một chút**. Ở chế độ tối đạt 6.7.
  - Với màu lam đạt 5.3, hồng đất 4.8, cam đất 4.1.
  - Chưa tự sửa. Hướng sửa nếu giữ ngọc lam: dùng chữ ngọc lam đậm hơn cho chip này.
- Tương phản của 3 màu thay thế (sáng · tối):
  - Nút chính: lam 6.7 · 5.8, cam đất 5.2 · 6.9, hồng đất 6.3 · 5.8.
  - **Lam là màu duy nhất đạt AA ở mọi cặp.**
  - Lưu ý: cam đất dễ lẫn với trạng thái "Còn thiếu" (cam), hồng đất dễ lẫn với "Chưa đánh dấu" (đỏ).

### Câu hỏi khi duyệt
1. Màu chủ đạo ngọc lam có hợp ý không? Phương án khác: lam `#1d4ed8`, cam đất `#c2410c`, hồng đất `#be123c`.
2. Cỡ chữ gốc 19px có đủ to không? Phương án: 21px.
3. Chữ thường hay chữ bo tròn (SF Pro Rounded)?
4. Đổi viền ô nhập sang `#71717a`? Từ bản iPhone, lựa chọn này áp cho cả viền ô tích và viền nút chọn.
