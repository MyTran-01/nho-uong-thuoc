# Nhớ Thuốc · Token notes

## Vòng chỉnh độ sâu và nút · 06/11/2026

- Theo phản hồi người phụ trách: CTA chính có gradient xanh bạc hà và bóng nhẹ; thẻ dùng gradient trắng → xám rất nhạt cùng bóng mềm. Các nút phụ dùng chữ nhỏ hơn, nền phẳng; lựa chọn dạng chip dùng nền xanh nhạt thay vì màu đặc.
- Bỏ viền ở thẻ, ảnh vỉ, nút đánh dấu và khung chụp; giữ viền mảnh ở ô nhập để vùng nhập vẫn nhận biết được. Trạng thái đủ/thiếu/lỗi chuyển sang nền màu nhạt, vẫn có biểu tượng và chữ.
- Tương phản chữ trên chip trạng thái sáng: đủ 7.97:1, thiếu 6.37:1, lỗi 7.04:1. Đã xem Hôm nay và onboarding trên iPhone 17 Pro ảo, bản sáng.

## UI đồng bộ màn đang dùng · 06/11/2026

- Người phụ trách sản phẩm chọn tham chiếu giao diện thoáng, nền trắng, thẻ xám rất nhạt, chữ đậm rõ, hình minh hoạ lớn ở onboarding và thao tác chính trong vùng ngón cái. Giữ xanh bạc hà đã chọn ở vòng trước.
- Token sáng hiện hành: nền `#ffffff`, thẻ `#f5f6f8`, nút phụ `#e9eaed`, accent `#00c98e`. Chữ trên accent dùng `#063b2d`, chữ xanh trên nền nhạt dùng `#006b4d`.
- Màn đang dùng đã áp style chung: onboarding, Hôm nay, danh sách/chi tiết đơn, thêm đơn/thuốc, chụp vỉ, Cài đặt và sheet sửa thuốc. Lịch sử đang ẩn, chưa nằm trong vòng này.
- Đã kiểm trực tiếp trên iPhone 17 Pro simulator các màn Hôm nay, Đơn thuốc, chi tiết đơn, Cài đặt, thêm đơn và onboarding O1/O2. Chưa kiểm hình ảnh ở kích thước iPhone nhỏ và dark mode; app hiện khoá light mode.

## Điều chỉnh theo ảnh tham chiếu · 06/11/2026

- Người phụ trách sản phẩm đổi màu chính từ xanh dương sang xanh bạc hà trong ảnh Habitual. Mẫu màu từ vùng vòng tròn trong ảnh xấp xỉ `#00c98e`.
- App dùng `#00c98e` sáng / `#35d6a4` tối; chữ trên nền xanh dùng `#063b2d` để đủ tương phản (5.83:1 ở theme sáng). Chữ xanh trên nền xanh nhạt dùng `#006b4d`.
- Màn Hôm nay thêm dải tiến độ các lần uống, giữ trạng thái có nhãn và hình riêng để không dựa vào màu. Các màn khác nhận màu brand mới qua token chung.
- G0 toàn bộ design system vẫn cần duyệt lại; mục xanh dương trước đó chỉ còn là lịch sử thay đổi.

## Cập nhật style · 06/11/2026

- Người phụ trách sản phẩm chọn **xanh dương hiện đại** cho màu chính và yêu cầu làm thoáng màn Hôm nay cùng onboarding, tham khảo độ rõ ràng, sạch sẽ của Airbnb trên iPhone.
- Token đang áp dụng trong app: xanh `#1d4ed8` (sáng) / `#60a5fa` (tối), nền `#f7f9fc` / `#10131b`, thẻ `#ffffff` / `#1b2130`. Token Playground dùng cùng màu nguồn trong `heroui-lab/src/tokens.css`.
- Cỡ chữ và vùng chạm lớn giữ theo M14. Cần review lại G0 cho toàn bộ cặp màu, đặc biệt trạng thái dark và các màn ngoài Hôm nay/onboarding. Bản G0 v0.1 bên dưới là lịch sử đề xuất ngọc lam, chưa còn là màu app hiện hành.

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
