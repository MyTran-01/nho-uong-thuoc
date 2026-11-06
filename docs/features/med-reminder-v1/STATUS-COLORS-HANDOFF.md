# Chỉnh màu theo phản hồi · 06/11/2026

Đã sửa trực tiếp trong phạm vi yêu cầu đổi màu của người phụ trách sản phẩm. Không đổi cách tính giờ, lưu dữ liệu, hay hành động đánh dấu thuốc.

- Nền màn hình #e9edf2; card #ffffff. Token card tách riêng để thay nền không làm card tối theo.
- `SlotState.palette(in:)` là nguồn chung cho nhãn, timeline, icon. Sắp tới: lam; tới giờ/còn thiếu: cam; quá giờ: đỏ; đủ: xanh lá; bỏ cữ: xám. Nhãn quá giờ ghi rõ chưa dùng.
- Đồng bộ token nền và info vào token CSS nguồn.
- Verify-kit chưa có. `xcodebuild ... build CODE_SIGNING_ALLOWED=NO`: BUILD SUCCEEDED. `git diff --check`: đạt. Tương phản 10 cặp chữ/nền light/dark: 6,37–8,60:1.
- Đã cài/chạy trên iPhone 17 Pro Simulator và xem ảnh `review-screens/status-colors/today.png`: nền/card tách rõ; trạng thái đủ hiện xanh lá.
- Chưa kiểm trực tiếp các trạng thái khác, cỡ màn nhỏ, Dynamic Type lớn và dark. App hiện khóa light từ trước.
- Repo code đã có nhiều thay đổi dở khi tiếp nhận; giữ nguyên, không commit/push gộp chúng.

## Vòng 2 · 06/11/2026

Phản hồi người dùng xác nhận kết luận thị giác vòng 1 chưa đạt. Nền trước quá tối và các lớp nền CTA/tab bar bị cắt ngang. Sửa nền thành #f5f6f8 (trắng xám nhẹ), giữ card trắng. RootView vẽ nền chung xuyên safe area; tab bar bỏ material/gradient riêng; CTA nền đồng nhất, bóng nhỏ và fade 24pt phía trên để nội dung không kết thúc đột ngột. Card compact bỏ giờ lặp và dùng một cột giờ + trạng thái.

Build cuối: BUILD SUCCEEDED. Đã xem bằng CUA tab Thuốc và Hôm nay ở trạng thái đủ mở rộng; CTA/tab bar không còn mảng nền trắng lệch hoặc bóng bị cắt như ảnh phản hồi. Bằng chứng: `review-screens/status-colors/meds-v2.png`, `today-v2.png`. Không ghi nhận pass cuộn: thao tác automation chưa làm danh sách di chuyển. Chưa kiểm cỡ màn nhỏ, AX1 hoặc tất cả trạng thái. Không thay đổi bản ghi thuốc.
