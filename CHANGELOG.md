# Changelog tài liệu Nhớ Thuốc

Mỗi lần sửa tài liệu thêm 1 dòng vào "Chưa release". Dòng mới nhất ở trên.

## Chưa release

- 06/11/2026 · Sửa hồi quy trong luồng thêm thuốc: các khối/ô nhập đang dùng background cũ (trắng) bị hòa vào nền sau khi đổi token. Tách fill của ô nhập, nút quay lại, ô loại thuốc, liều, lịch, giờ, ảnh và thẻ xem lại sang cardBackground; khối trắng minh họa onboarding cũng dùng token card. Giữ nền màn hình hiện tại. Build thành công; đã xem trực tiếp cả 5 bước thêm thuốc bằng bản nháp không lưu trên Simulator; cuối cùng mở lại bước 1 trống. Ảnh: review-screens/status-colors/add-med-restored.png. Chưa chạy trực tiếp onboarding chào mừng.

- 06/11/2026 · Sửa vòng 2 theo phản hồi: ghi đè kết luận thị giác vòng trước — nền #e9edf2 quá đậm, nền CTA/tab bar lệch và bị cắt ngang, card cữ hiển thị giờ lặp. Đổi nền thành #f5f6f8, RootView/CTA/tab bar cùng nền, bỏ lớp material tab bar, giảm bóng CTA và thêm fade đầu vùng CTA; card compact chỉ hiện giờ một lần và nhãn trạng thái bên dưới. Build thành công; đã xem trực tiếp tab Thuốc và Hôm nay mở rộng trên iPhone 17 Pro Simulator. Chưa xác minh cuộn bằng automation (thao tác không di chuyển danh sách), chưa kiểm màn nhỏ/Dynamic Type lớn.

- 06/11/2026: Theo yêu cầu chỉnh màu: nền màn hình xám xanh #e9edf2, card trắng độc lập. Trang Hôm nay dùng chung bảng màu cho mốc giờ, biểu tượng và nhãn: sắp tới xanh lam; tới giờ/còn thiếu cam; quá giờ đỏ; đủ xanh lá; bỏ cữ xám. Giữ chữ và biểu tượng cạnh màu. Build iOS Simulator thành công; đã xem màn Hôm nay ở trạng thái đủ; tương phản 10 cặp chữ/nền light/dark tối thiểu 6,37:1. Chưa kiểm trực tiếp mọi trạng thái/kích cỡ.

- 06/11/2026: Thêm câu giải thích dưới "Giờ sinh hoạt" ở Cài đặt và ở bước giờ ăn ngủ của onboarding: app dựa vào giờ ăn, giờ ngủ của riêng người dùng để nhắc dùng thuốc đúng lúc.

- 06/11/2026: Chip chưa chọn bỏ nền trắng, chỉ còn viền mảnh (1pt) và nhạt hơn. Áp dụng cho mọi chip trong app.

- 06/11/2026: Chỉnh theo góp ý.
  - Chip/tag toàn app nhỏ lại: cao 38pt thay vì 48pt, chữ 17pt, vùng chạm vẫn 44pt.
  - Chip đang chọn nền đen đậm, chữ trắng, thay cho màu chính.
  - Đổi "uống" thành "dùng" ở mọi chữ trong app (ví dụ "Bao lâu dùng một lần?", "Đã dùng đủ"), vì kem bôi, ống hít, thuốc tiêm không phải uống. Tên app chưa đổi.

- 06/11/2026: Bỏ ô "Hàm lượng bao nhiêu?" ở bước 2 khi thêm thuốc, theo góp ý. Hàm lượng cũng không còn hiện ở tab Thuốc và màn xem lại.

- 06/11/2026: Phase này chưa làm thông báo nên **ẩn mọi giao diện thông báo**: banner "Thông báo đang tắt" ở Hôm nay và mục "Nhắc nhở" trong Cài đặt (gồm bật thông báo, hiện tên thuốc trên màn khoá, gửi thử lời nhắc). Phần xếp lịch nhắc trong code vẫn giữ, bật lại bằng `NotificationScheduler.showsUI`.

- 06/11/2026: Nhắc uống thuốc v1.1 — **bỏ đơn thuốc**. Không còn chụp hay tải ảnh đơn, app không đọc chữ trong đơn nữa.
  - Nhập tay từng loại thuốc theo 5 bước như app mẫu: tên + dùng để làm gì → loại, hàm lượng, mỗi liều → bao lâu một lần + giờ → ảnh (tuỳ chọn) → xem lại.
  - Giờ vẫn gợi ý theo giờ ăn và giờ ngủ. Chạm vào giờ để đổi buổi, trước/trong/sau ăn, hoặc đặt giờ cố định.
  - Thêm lịch: theo thứ trong tuần, và vài tiếng một lần.
  - Onboarding còn 3 bước: chào mừng → giờ ăn ngủ → thêm thuốc đầu tiên. Chưa xin quyền thông báo.
  - Tab "Đơn thuốc" đổi thành "Thuốc", gom theo "Dùng để làm gì".
  - Sửa PRD (1.1, mục 4.2–4.3) và USER_FLOW (mục 0).
  - Dữ liệu cũ trên máy thử bị xoá.

- 06/11/2026: Tinh chỉnh UI theo phản hồi: CTA có gradient và bóng mềm, thẻ có chiều sâu nhẹ, nút phụ gọn hơn; bỏ bớt stroke và làm dịu chip trạng thái.

- 06/11/2026: Đồng bộ UI các màn đang dùng theo tham chiếu mới: nền trắng, thẻ xám nhạt, xanh bạc hà; onboarding có hình minh hoạ sản phẩm; Đơn thuốc và Cài đặt gọn hơn, thao tác chính ở vùng ngón cái. Màn Lịch sử đang ẩn chưa chỉnh.

- 06/11/2026: Nhắc uống thuốc v1 — rút gọn chữ toàn app theo góp ý "quá nhiều chữ". Hôm nay: gộp tiêu đề, ngày, "3/5" và dãy chấm trạng thái thành 1 khối; bỏ câu giải thích; trạng thái thể hiện bằng icon/màu. Cũng rút gọn màn đánh dấu, thiết lập lần đầu, Cài đặt, Đơn thuốc, chụp đơn, chụp vỉ, lời nhắc. Quy tắc mới ở PRD mục 13.

- 06/11/2026: Nhắc uống thuốc v1 — màn Hôm nay đánh dấu ngay tại chỗ, theo mẫu tham khảo người phụ trách gửi. Thứ tự lần uống giữ nguyên. Mỗi lần uống hiện từng thuốc (ảnh vỉ, tên, liều) với nút tròn ＋/✓. Không thêm nút đổi ngày. Nút "Uống đủ N thuốc" kéo hết chiều ngang, nằm dưới danh sách thuốc (chữ app to hơn mẫu nên không vừa đầu nhóm), ẩn khi buổi chỉ có 1 thuốc. Lần uống kế tiếp luôn đánh dấu được, không chờ tới 60 phút trước giờ. Đã làm thẳng trong app (SwiftUI), xem trên iPhone ảo. Sửa PRD 5.1, AC26, S1, E3, T7, thêm T16–T17.

- 06/11/2026: Nhắc uống thuốc v1 — mỗi vỉ thuốc chỉ cần **1 ảnh**, bỏ ảnh mặt sau theo góp ý. Sửa M06, M08, AC05, AC12, S2, D1, S8, T5. Ảnh mặt sau đã chụp trước đó vẫn lưu trong máy nhưng không hiện nữa.

- 06/11/2026: Nhắc uống thuốc v1 — quy tắc mới: màn chỉ có 1 CTA chính thì CTA ghim ở đáy, ngay vùng ngón cái. Áp dụng cho Đơn thuốc ("Thêm đơn thuốc"), Hôm nay lúc chưa có đơn ("Chụp đơn thuốc"), Chi tiết đơn ("Hết cả đơn" / "Uống tiếp" / "Dùng lại"). Sửa M13, AC23, S4.

- 06/11/2026: Nhắc uống thuốc v1 — làm lại phần chỉnh thuốc (S7/S5) theo góp ý: ô "Tên loại thuốc"; chọn buổi Sáng / Trưa / Chiều / Tối / Khi ngủ; chọn buổi nào thì chỉ hiện chi tiết của buổi đó (trước/trong/sau ăn, bao lâu, giờ uống tính sẵn); "Mỗi lần uống" là chọn loại + nút Bớt/Thêm (½ viên, 2,5 ml, 1 giọt mỗi bước); lịch uống giữ nguyên.

- 06/11/2026: Nhắc uống thuốc v1 — bỏ ô "Tên đơn" ở màn kiểm danh sách thuốc (S7) theo góp ý: không ưu tiên. Tên đơn lấy từ dòng phòng khám trên đơn, không có thì đặt "Đơn ngày 6/11". Đổi tên được ở cuối màn chi tiết đơn.

- 06/11/2026: Nhắc uống thuốc v1 — hoàn thiện MVP (nhánh `feature/med-reminder-mvp`, chờ duyệt merge).
  - Bấm lời nhắc mở thẳng màn đánh dấu. Nút "Đã uống đủ" ngay trên lời nhắc.
  - Lịch sử tháng, chi tiết ngày, đánh dấu muộn.
  - Tạm dừng đơn. Xem trước giờ uống sẽ dời khi đổi giờ sinh hoạt. Công tắc hiện tên thuốc trên màn khoá.
  - 19 kiểm tra tự động đều đạt. Chi tiết ở `MVP-NOTES.md`.

- 05/11/2026: Nhắc uống thuốc v1 — có **bản MVP chạy thử trên iPhone ảo**, theo yêu cầu "làm trọn 1 flow, chỉ bản light".
  - Luồng: onboarding → chụp đơn → app đọc đơn → chụp vỉ → Hôm nay → lời nhắc → đánh dấu đã uống.
  - Chi tiết, kết quả và phần chưa làm: `features/med-reminder-v1/MVP-NOTES.md`.

- 05/11/2026: Design system — chuyển token v0.1 sang SwiftUI.
  - Có màn thử chạy trên iPhone ảo, kèm bảng tuỳ chỉnh 4 câu hỏi và bảng tương phản tự tính.
  - Ghi 2 chỗ lệch so với HeroUI để chữ dễ đọc hơn.
  - Phát hiện chip "Sắp tới" trượt AA ở chế độ sáng (4.4:1).

- 05/11/2026: Design system — chốt nền giao diện theo phong cách HeroUI (app vẫn là SwiftUI). Dựng Token Playground bằng HeroUI thật, token v0.1 chờ duyệt (G0).
- 05/11/2026: Nhắc uống thuốc v1 — **PRD 1.0 được duyệt**, các câu hỏi còn mở dùng mặc định. Thêm yêu cầu: lời văn tự nhiên, chữ to, nút lớn cho người lớn tuổi (M14, mục 13).
- 05/11/2026: Nhắc uống thuốc v1 — PRD 0.3 theo góp ý vòng 2:
  - Bỏ việc app tự hỏi "đã hết thuốc chưa".
  - Onboarding là danh sách 4 mốc giờ đã điền sẵn, sửa tại dòng.
  - Buổi chiều mặc định 15:00.
  - Máy thử: iPhone 15 Pro, iOS 27.
- 05/11/2026: Nhắc uống thuốc v1 — PRD 0.2 theo góp ý vòng 1:
  - Onboarding chỉ hỏi 4 mốc giờ.
  - Ảnh vỉ là 2 khung vuông nằm cạnh nhau.
  - Thêm nút "Hết thuốc" / "Hết cả đơn", và app tự hỏi khi nghi thuốc đã hết.
  - Màn xác nhận đơn hiện tên thuốc trong đơn, sửa tên ngay tại chỗ.
  - Mọi thông tin thuốc nhập bằng chip, mặc định "trước ăn" là 30 phút.
- 05/11/2026: Nhắc uống thuốc v1 — bản nháp đầu tiên của PRD, user flow, hướng dẫn kỹ thuật và danh sách task. Có 22 câu hỏi kèm mặc định đề xuất.
- 05/11/2026: Dựng thư mục tài liệu, hồ sơ làm việc, cấu hình dự án (SwiftUI, dữ liệu chỉ trên máy, UI tiếng Việt).
