# Painpoint gốc · 05/11/2026

Người phụ trách sản phẩm kể từ trải nghiệm bản thân. Lưu nguyên ý, chỉ đọc. Bản mới thì thêm file mới có ngày.

## Hoàn cảnh
- Có giai đoạn phải uống thuốc **5 lần/ngày**, từ **2 đơn thuốc khác nhau**: 1 đơn da liễu, 1 đơn thuốc bổ.
- Thời điểm uống khác nhau: sáng sau ăn no, trước khi ăn, buổi chiều, buổi tối, trước khi ngủ 1 tiếng.
- Mỗi loại có số viên mỗi lần khác nhau, cách uống khác nhau, có loại **uống cách ngày**.

## Đang kẹt ở đâu
- Sau 1 tháng vẫn không nhớ buổi nào uống loại nào.
- Cả 5 lần trong ngày đều phải mở 2 đơn ra dò xem lúc đó cần uống gì.
- Đọc tên trong đơn xong lại phải dò xem tên đó là vỉ nào ở ngoài.

## Mong muốn
- Tới giờ uống thì app nhắc: lần này uống **những viên nào**, trông ra sao. Chỉ cần nhìn hình, nhìn vỉ là lấy đúng, không phải đọc tên.
- App dựa vào giờ người dùng thường ăn sáng, trưa, tối để xếp thuốc vào khung giờ phù hợp với từng thuốc.
- Đánh dấu đã uống: hiện danh sách thuốc có checkbox, **mặc định check hết**. Uống thiếu viên nào thì tự bỏ check viên đó.
- **Mỗi lần ghi nhận là cả một lần uống** (gồm nhiều loại), không ghi từng loại một.

## Ràng buộc
- App iPhone trước, giao diện tiếng Việt.
- Mục tiêu trước mắt: giải đúng vấn đề của chính người phụ trách sản phẩm.

## Trả lời vòng hỏi đầu (05/11/2026)
- Vai: Designer.
- Nền tảng: SwiftUI native.
- Giờ ăn: chỉ tự khai báo, không tự học, không tách ngày thường / cuối tuần.
- Nhập đơn: chụp ảnh đơn thuốc trước → app tự tách ra có bao nhiêu loại thuốc → lần lượt chụp vỉ **mặt trước, mặt sau** của từng loại. Người dùng hỏi tính năng tự đọc đơn có làm nhà phát hành tốn phí ngầm không.
