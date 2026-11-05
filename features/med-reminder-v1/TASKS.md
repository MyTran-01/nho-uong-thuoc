# Nhắc uống thuốc v1 · Tasks

Spec: `PRD.md`, `USER_FLOW.md`, `GUIDANCE.md`. Đọc cả ba trước khi làm.
Repo code: `app/` (chưa tạo). Nhánh: `med-reminder-v1`, cắt từ `main` sau commit khởi tạo project Xcode.

## Gate
| Gate | Nội dung | Trạng thái |
|---|---|---|
| G-PRD | PRD / USER_FLOW được duyệt, Q1–Q26 chốt | **chờ** |
| G0 | Token (màu, chữ, bo góc, khoảng cách, light/dark) được duyệt | chờ |
| G1 | Preview HTML các màn S1–S12, O1–O4 được duyệt | chờ |
| G2 | Prompt hợp đồng logic / UI được duyệt | chờ |
| G3 | Duyệt cuối sau nghiệm thu trên iPhone thật | chờ |

## Logic (chạy sau G-PRD, song song với design)
| Task | Việc | Xong khi |
|---|---|---|
| ML-00 | Khảo sát, **không viết code app**: thử Vision đọc tiếng Việt trên iOS đích; kiểm FoundationModels có hỗ trợ tiếng Việt không; xác nhận giới hạn 64 thông báo; kiểm AlarmKit với Apple ID miễn phí | Ghi kết quả + bằng chứng vào HANDOFF. Người phụ trách chọn hướng đọc đơn nếu Vision không đọc được tiếng Việt. |
| ML-01 | Khởi tạo project Xcode, SwiftData model, `.gitignore` chặn `docs/`, `HANDOFF*.md` | Build chạy được trên simulator; có test model |
| ML-02 | `SlotEngine`: quy tắc thời điểm → giờ, gộp slot, cách ngày, ngày uống qua 0h | AC06, AC07, AC20 có test tự động xanh |
| ML-03 | Vòng đời đơn + thuốc: hết thuốc, hết cả đơn, hoàn tác, tạm dừng, nhãn "đã đủ N ngày" (không tự hỏi) | AC19, AC24 có test |
| ML-04 | `DoseLog` + snapshot + ràng buộc duy nhất; ghi nhận / thiếu / bỏ qua / lỡ / ghi bù / sửa | AC13, AC15, AC16, AC18 có test |
| ML-05 | `NotificationScheduler`: xếp lịch cuộn ≤ 64, nhắc lại, huỷ, action "Đã uống đủ", nội dung màn khoá theo Q7 | AC09, AC10, AC14 có test đơn vị và kiểm thủ công trên simulator |
| ML-06 | `RxParser` + Vision: đọc ảnh → danh sách thuốc nháp với chip chọn sẵn; xử lý lỗi | AC02, AC03, AC04, AC25 trên 5 ảnh đơn mẫu hư cấu |
| ML-07 | Đổi giờ sinh hoạt → xem trước + dời slot tương lai | AC08 có test |
| ML-08 | AlarmKit (nếu Q5 giữ "có") | Bật / tắt được, quay về thông báo thường khi bị từ chối |
| ML-09 | Fixture dữ liệu mẫu hư cấu (kịch bản A02) | Dùng chung cho test và preview |

## UI (chỉ mở khi G1 xong)
| Task | Việc | Xong khi |
|---|---|---|
| MU-01 | Tab bar + S1 Hôm nay (mọi trạng thái) | Khớp preview, 3 kích thước iPhone, light/dark, AX1 |
| MU-02 | S2 Lần uống (2 ảnh vuông cạnh nhau, "Hết thuốc") + D1 | AC11, AC12, AC13, AC23 trên simulator |
| MU-03 | S3, S4, S5 Đơn thuốc / chi tiết đơn ("Hết cả đơn", "Đã hết") / chi tiết thuốc (toàn chip) | T9–T13, T15 đạt số bước; AC23, AC25 |
| MU-04 | S6, S7, S8 luồng chụp đơn + chụp vỉ | AC02, AC05; ngoại lệ X1 đúng như đã duyệt |
| MU-05 | S9, S10 Lịch sử | AC17 |
| MU-06 | O1–O4 Onboarding (O2 là danh sách điền sẵn, sửa tại dòng), S11, S12 Cài đặt | AC01, AC08 |
| MU-07 | Soát accessibility: VoiceOver, Dynamic Type, tương phản, vùng chạm | AC22 |

## Việc kéo theo
- Cài đặt verify-kit vào repo code sau ML-01.
- Hướng dẫn cài app lên iPhone thật bằng Apple ID (Q18). Agent tự làm, chỉ nhờ người phụ trách cắm máy / bấm tin cậy.

## Global constraints
- Không gọi mạng. Không SDK bên thứ ba có thu thập dữ liệu.
- Dữ liệu mẫu hư cấu.
- UI tiếng Việt, mọi chuỗi qua String Catalog.

## Review focus
1. `SlotEngine`: gộp slot, cách ngày, ngày uống qua 0h. Sai ở đây là uống sai thuốc.
2. Ghi nhận trùng giữa action thông báo và app.
3. Giới hạn 64 thông báo và huỷ nhắc lại.
4. Snapshot lịch sử không bị ghi đè khi sửa thuốc.
