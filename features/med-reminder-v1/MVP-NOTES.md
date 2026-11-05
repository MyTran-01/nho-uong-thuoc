# Nhắc uống thuốc v1 · Ghi chú bản MVP chạy thử

05/11/2026 · Người phụ trách sản phẩm yêu cầu: "chỉ cần MVP flow, chỉ bản light, làm trọn 1 flow từ onboarding → chụp đơn → nhắc thuốc".
Code: repo `../app`, commit `36d4515`. Chạy trên iPhone 17 Pro ảo (iOS 26.5).

**Lưu ý quy trình:** bản này đi tắt qua G1 (preview HTML) và G2 (prompt hợp đồng) theo yêu cầu trực tiếp trong lượt. Đây là bản chạy thử để cảm nhận luồng, **chưa phải bản nghiệm thu**.

## Token dùng cho MVP (*giả định*, chờ chốt G0)
Theo đề xuất đã báo:
- Màu ngọc lam, cỡ chữ gốc 19, chữ thường, viền ô nhập đậm (`#71717a`).
- Chữ chip "Sắp tới" đậm hơn (`#115e59`) để đạt AA.
- **Chỉ chế độ sáng.**

## Đã làm và đã thử trên máy ảo
| Luồng | Kết quả |
|---|---|
| A01 Onboarding: O1 → O2 (4 mốc điền sẵn, bánh xe giờ mở trong dòng) → O3 xin quyền → O4 | Chạy đúng |
| S6 chụp đơn / chọn ảnh có sẵn → đọc chữ trên máy → S7 | Đơn mẫu da liễu đọc ra đủ **4 thuốc**, đơn mẫu thuốc bổ ra đủ **3 thuốc**. Mất dưới 1 giây. |
| S7 danh sách thuốc: "Trong đơn: …", ô tên sửa tại chỗ, chip liều / bữa / độ lệch / lịch | Chạy đúng. "Trước ăn" không ghi phút thì tự chọn 30 phút. "Cách ngày" tự nhận. "1/2 viên" thành "Nửa viên". |
| S8 chụp vỉ: khung vuông, mặt trước → mặt sau, "Thuốc 2/4", bỏ qua được | Chạy đúng (thử bằng ảnh có sẵn) |
| S1 Hôm nay: giờ uống kế tiếp + ảnh vỉ, còn lại hôm nay, banner thiếu ảnh vỉ | Chạy đúng. Giờ 19:15 **gom thuốc của cả 2 đơn**. |
| S2 đánh dấu: 2 ảnh vuông cạnh nhau, ô tích đã tích sẵn, "Đã uống (còn N thuốc chưa uống)", "Hôm nay bỏ cữ này", "Thuốc này đã hết" + Hoàn tác | Chạy đúng |
| Lời nhắc | Lời nhắc theo lịch cho giờ uống 19:15 tự hiện trên màn khoá khi app đã đóng. Nội dung "Tới giờ uống thuốc rồi · Tối, sau khi ăn (2 loại thuốc)", không lộ tên thuốc. Có nhắc lại sau 10 phút. Ảnh: `review-screens/mvp-ios17pro-light-lock-reminder.png`. |
| Sau giờ nhắc, mở app | Hôm nay đưa thẻ "Tới giờ uống thuốc rồi" lên đầu, nút "Đánh dấu đã uống". |
| Ghi nhận và sửa (T1, T2, T7) | Lưu xong, thẻ chuyển xuống "Đã xong · ✓ Đã uống đủ". Mở lại sửa được. Bỏ tích Omega-3 rồi lưu thì Lịch sử hiện "◐ Còn 1 thuốc chưa uống · Chưa uống: Omega-3". Vẫn chỉ 1 bản ghi cho giờ đó. Ảnh: `review-screens/mvp-ios17pro-light-S9-lich-su.png`. |

Kết quả tính giờ với 2 đơn mẫu (khớp kịch bản A02):
- 6:30 Sáng, trước khi ăn
- 7:15 Sáng, sau khi ăn (Kẽm cách ngày)
- 15:00 Buổi chiều
- 19:15 Tối, sau khi ăn
- 22:00 Trước khi ngủ

## Đợt 2 · 06/11/2026 · hoàn thiện MVP
Nhánh `feature/med-reminder-mvp`, commit `2c5b658` + `f3ffdf8`. **Chưa merge** vào `main`, chờ người phụ trách duyệt.

| Luồng | Kết quả trên máy ảo |
|---|---|
| **E1/AC11** Bấm vào lời nhắc | Mở thẳng màn đánh dấu đúng giờ uống. Đúng cả khi app đang mở lẫn khi app chạy nền. Ảnh: `review-screens/mvp-ios17pro-light-E1-mo-tu-loi-nhac.png`. |
| **E2/AC14** Nhấn giữ lời nhắc → "Đã uống đủ" | Ghi nhận được mà không mở app. Mở app thì giờ uống đó đã sang "Đã xong". Ảnh: `review-screens/mvp-ios17pro-light-E2-nut-da-uong-du.png`. |
| **S9/AC17** Lịch sử tháng | Mỗi ngày 1 dấu, phân biệt bằng **hình**: ✓ uống đủ, ◐ có thuốc chưa uống, ✕ có lần bỏ cữ hoặc chưa đánh dấu. Có chú thích. |
| **S10/AC16** Chi tiết ngày | Liệt kê từng giờ uống của ngày. Bấm "Sửa" hoặc "Đánh dấu" để đánh dấu muộn. Đã thử: đánh dấu muộn giờ 22:00 hôm trước thì dấu của ngày đổi từ ✕ sang ◐. |
| **T9** Tạm dừng đơn | Có hộp xác nhận. Thuốc của đơn biến khỏi Hôm nay ngay. "Uống tiếp đơn này" bật lại. |
| **AC08** Đổi giờ sinh hoạt | Trước khi lưu hiện "Các giờ uống sẽ dời thành: 6:30 → 7:30, 7:15 → 8:15". Lưu xong báo "Đã dời 2 giờ uống". Lời nhắc được xếp lại. |
| **Q7** Tên thuốc trên màn khoá | Công tắc trong Cài đặt, **mặc định tắt**. |
| **Kiểm tra tự động** | **19/19 đạt**: tính 5 giờ uống mỗi ngày (AC06), thuốc cách ngày qua 14 ngày (AC07), ngủ sau 0h (AC20), không gộp trước ăn với sau ăn, không quá 64 lời nhắc, nhắc lại 10 phút × 3, đọc đơn mẫu. |

## Chưa làm hoặc làm gọn (so với PRD)
- **Nhắc kiểu báo thức (AlarmKit, Q5):** chưa làm. PRD để mặc định tắt nên MVP bỏ qua.
- **Sửa thuốc (S5):** sửa trong sheet, chưa có màn chi tiết riêng.
- **Kiểm giao diện:** mới kiểm trên iPhone 17 Pro, chữ cỡ mặc định. Chưa kiểm iPhone SE, 17 Pro Max, chữ cỡ lớn (AX1–AX3), VoiceOver.
- **Đọc đơn mới thử với đơn in mẫu rõ nét.** Đơn thật (chụp nghiêng, chữ nhỏ, viết tay) chưa thử.
- **Máy ảo:** bấm lời nhắc khi app chạy nền thì app nhận được, nhưng máy ảo không tự đưa app lên trước. Trên iPhone thật iOS sẽ tự mở app. Cần xác nhận trên máy thật.
- Dữ liệu thử: giờ ăn sáng trên máy ảo đang là **8:00** (đổi từ 7:00 khi thử AC08).
