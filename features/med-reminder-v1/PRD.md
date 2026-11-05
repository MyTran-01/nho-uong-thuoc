# Nhắc uống thuốc v1 · PRD

Phiên bản 0.1 · 05/11/2026 · Người viết: agent điều phối, theo painpoint và các câu trả lời người phụ trách sản phẩm chốt ngày 05/11/2026.
Trạng thái: **nháp — chờ duyệt**. Q1–Q22 còn mở, mỗi câu đã có mặc định đề xuất.

Nguồn (chỉ đọc):
- `sources/2026-11-05-painpoint-nguoi-dung.md`: painpoint, mong muốn, câu trả lời vòng hỏi đầu.
- `process/project.md`: stack, design system, kích thước màn kiểm tra.

Đây là feature đầu tiên. Chưa có feature mẫu để làm pattern.

---

## 0. Một câu vấn đề

**Người phải uống nhiều loại thuốc từ nhiều đơn, mỗi loại một giờ** không nhớ được *lúc này cần uống những viên nào*. Họ phải mở lại từng đơn để dò, rồi đối tên trong đơn với vỉ thuốc thật, ngày 5 lần.

## 1. Mục tiêu

Sau v1, người dùng làm được những việc sau:

- **Nhập đơn một lần, không phải mở lại.** Chụp ảnh đơn, app tự tách ra từng loại thuốc. Người dùng sửa lại cho đúng, rồi chụp vỉ mặt trước và mặt sau của từng loại.
- **Không phải tự tính giờ.** Khai báo giờ thức dậy, giờ ăn, giờ ngủ một lần. App tự xếp từng thuốc vào đúng *lần uống* theo cách dùng ("trước ăn sáng", "sau ăn tối", "trước ngủ 1 tiếng", "cách ngày"…).
- **Tới giờ thì app nhắc, gom thuốc của mọi đơn.** Mỗi lần nhắc liệt kê đủ thuốc của lần đó, từ cả 2 đơn.
- **Lấy thuốc bằng mắt, không đọc tên.** Mỗi thuốc hiện bằng ảnh vỉ thật kèm số lượng ("2 viên").
- **Ghi nhận một lần cho cả lần uống.** Danh sách đã check sẵn hết. Thiếu viên nào thì bỏ check viên đó, bấm một nút là xong.
- **Xem lại đã uống đủ chưa.** Lịch theo tháng cho biết ngày nào uống đủ, thiếu hay bỏ.

Hiện chưa làm được: chưa có app, đang phải dò đơn giấy 5 lần/ngày.

## 2. Quyết định đã chốt

| ID | Quyết định |
| --- | --- |
| M01 | App iPhone, viết bằng SwiftUI native. Giao diện tiếng Việt. |
| M02 | Một người dùng, không cần tài khoản hay đăng nhập. |
| M03 | Dữ liệu chỉ nằm trên máy: đơn, ảnh, lịch sử. Không có server. Việc đọc chữ trên đơn cũng chạy trên máy (xem mục 10, Chi phí). |
| M04 | Đơn vị nhắc là **lần uống**. Một lần uống gom mọi thuốc có cùng thời điểm từ mọi đơn đang dùng. Mỗi lần uống có 1 thông báo và 1 bản ghi. |
| M05 | Giờ uống tính từ **giờ sinh hoạt** người dùng tự khai báo, gồm 6 mốc: thức dậy, ăn sáng, ăn trưa, buổi chiều, ăn tối, đi ngủ. App không tự học giờ. Mọi ngày trong tuần dùng chung một bộ giờ. |
| M06 | Nhập đơn theo 3 bước: (1) chụp ảnh đơn, (2) app đọc chữ và tách danh sách thuốc, người dùng sửa / thêm / xoá dòng, (3) lần lượt chụp vỉ **mặt trước + mặt sau** cho từng thuốc. Bước chụp vỉ bỏ qua được, chụp bổ sung sau. Đọc không được (đơn viết tay, ảnh mờ) thì nhập tay. |
| M07 | Ghi nhận theo lần uống: 1 bản ghi chứa trạng thái từng thuốc. Checkbox **mặc định check hết**, người dùng bỏ check thuốc chưa uống. |
| M08 | Ảnh vỉ mặt trước là hình chính của thuốc trên mọi màn nhắc và màn ghi nhận. Tên thuốc là chữ phụ. Ảnh mặt sau xem được khi chạm vào ảnh. |
| M09 | Điều hướng bằng tab bar dưới cùng, 4 tab: **Hôm nay · Đơn thuốc · Lịch sử · Cài đặt**. |
| M10 | Lịch dùng mỗi thuốc có 3 kiểu: hằng ngày / cách N ngày / các thứ cố định trong tuần. Có ngày bắt đầu và số ngày dùng (hoặc "dùng tới khi tắt"). |
| M11 | Bản ghi giữ **ảnh chụp tại thời điểm uống** (snapshot): tên, số lượng, ảnh của từng thuốc lúc đó. Sau này sửa hay xoá thuốc thì lịch sử cũ không đổi. |

## 3. Role và quyền

App một người dùng, **không có role** (N/A).

Quyền hệ thống iOS cần xin, theo nguyên tắc chỉ xin khi cần:

| Quyền | Khi nào xin | Bị từ chối thì |
| --- | --- | --- |
| Thông báo (gồm Time Sensitive) | Cuối onboarding, sau khi giải thích vì sao cần | Banner trên tab Hôm nay: "Chưa bật thông báo nên app không nhắc được", kèm nút mở Cài đặt iOS. App vẫn dùng được. |
| Camera | Lần đầu bấm chụp đơn hoặc chụp vỉ | Chọn ảnh từ thư viện, hoặc nhập tay |
| Thư viện ảnh | Dùng picker hệ thống nên không cần quyền đầy đủ | — |
| Báo thức (AlarmKit) | Chỉ khi người dùng bật "Nhắc kiểu báo thức" (Q5) | Quay về thông báo thường |

## 4. Đối tượng và vòng đời

### 4.1 Giờ sinh hoạt (mới, một bản duy nhất)
- **Nguồn:** người dùng nhập ở onboarding, có giờ gợi ý sẵn (Q21).
- **Sửa:** ở tab Cài đặt. Trước khi lưu, app hiện trước "các lần uống sẽ dời thành…".
- **Lan truyền:** chỉ áp cho các lần uống **từ bây giờ trở đi**, bản ghi đã lưu giữ nguyên. Thông báo được xếp lịch lại ngay.

### 4.2 Đơn thuốc (mới)
- **Nội dung:** tên đơn (ví dụ "Da liễu", "Thuốc bổ"), ảnh đơn gốc, ngày kê, nơi khám / bác sĩ (không bắt buộc), ngày bắt đầu, số ngày dùng.
- **Trạng thái:** `Đang dùng` → `Đã hết` (tự chuyển sau ngày cuối) / `Tạm dừng` (bấm tay) → `Đang dùng` (bấm tay).
- **Xoá:** có hộp xác nhận. Lịch sử vẫn giữ nhờ snapshot (Q11).
- **Lan truyền:** đổi trạng thái hoặc ngày thì các lần uống tương lai cập nhật ngay.

### 4.3 Thuốc (mới, thuộc 1 đơn)
| Thông tin | Ví dụ (hư cấu) | Bắt buộc |
| --- | --- | --- |
| Tên như trong đơn | "Vitamin Tổng Hợp ABC 500mg" | ✓ |
| Tên gọi ngắn (tuỳ chọn) | "Viên vàng to" | |
| Ảnh vỉ mặt trước / mặt sau | 2 ảnh | Không bắt buộc, có nhắc "chưa có ảnh vỉ" |
| Ảnh viên thuốc (tuỳ chọn, Q12) | 1 ảnh | |
| Số lượng mỗi lần + đơn vị | 1 viên · ½ viên · 1 gói · 5 ml · 1 lần bôi (Q14) | ✓ |
| Cách dùng | Uống với nhiều nước / ngậm dưới lưỡi / pha với nước / không nhai | |
| Thời điểm (có thể nhiều thời điểm/ngày) | "Sau ăn sáng" + "Sau ăn tối" | ✓ |
| Lịch | Hằng ngày / cách 1 ngày / Thứ 2-4-6 | ✓ (mặc định hằng ngày) |
| Ghi chú | "Tránh nắng sau khi uống" | |

**Quy tắc đổi thời điểm thành giờ** (độ lệch là cấu hình, xem Q1–Q2):

| Thời điểm | Giờ uống |
| --- | --- |
| Lúc đói, ngay khi thức dậy | giờ thức dậy |
| Trước ăn [sáng/trưa/tối] | giờ bữa − 30 phút |
| Trong bữa [sáng/trưa/tối] | giờ bữa |
| Sau ăn / sau ăn no [sáng/trưa/tối] | giờ bữa + 15 phút |
| Buổi chiều | mốc "buổi chiều" trong giờ sinh hoạt |
| Trước khi ngủ X phút | giờ ngủ − X |
| Giờ cố định | giờ người dùng chọn |

### 4.4 Lần uống (tính ra, không nhập tay)
- Mỗi ngày, app gom các *thời điểm* của mọi thuốc đang dùng thành các lần uống.
- **Quy tắc gộp (Q3):** gộp khi cùng mốc và cùng quan hệ (ví dụ cùng "sau ăn sáng"), hoặc khi giờ tính ra trùng nhau. **Không bao giờ gộp "trước ăn" với "sau ăn".**
- Tên lần uống tự đặt theo mốc: "Sáng · trước ăn", "Sáng · sau ăn", "Chiều", "Tối · sau ăn", "Trước ngủ".
- **Ngày uống thuốc** tính từ giờ thức dậy tới giờ ngủ, không cắt ở 0h. Ví dụ giờ ngủ là 0:30 thì lần "trước ngủ 1 tiếng" lúc 23:30 vẫn thuộc ngày đang sống.

### 4.5 Bản ghi lần uống (mới)
| Trạng thái | Khi nào |
| --- | --- |
| Sắp tới | Chưa tới giờ |
| Tới giờ | Đã tới giờ, chưa ghi nhận. Đang nhắc lại. |
| Đã uống đủ | Ghi nhận, mọi thuốc đều check |
| Uống thiếu | Ghi nhận, có ít nhất 1 thuốc bỏ check |
| Bỏ qua | Người dùng bấm "Bỏ qua lần này" |
| Lỡ | Quá hạn ghi nhận (Q8) mà chưa ghi. Vẫn ghi bù được, khi đó gắn nhãn "ghi bù". |

- Mỗi bản ghi lưu: giờ dự kiến, giờ ghi nhận, và snapshot từng thuốc (M11) kèm uống / không uống.
- Sửa được bản ghi đã lưu (đổi check, đổi giờ ghi nhận).

## 5. Hàng việc trên tab "Hôm nay" và thứ tự

| Thứ tự | Loại | Khi nào vào | Khi nào ra |
| --- | --- | --- | --- |
| 1 | Lần uống **Tới giờ** hoặc **Lỡ** của hôm nay | Tới giờ | Khi ghi nhận hoặc bỏ qua |
| 2 | Lần uống **kế tiếp** (thẻ lớn, có ảnh các vỉ) | Là lần sớm nhất chưa tới giờ | Khi tới giờ thì chuyển lên nhóm 1 |
| 3 | Các lần uống còn lại trong ngày (thẻ nhỏ) | — | — |
| 4 | Các lần đã xong (thu gọn, đã uống đủ / thiếu / bỏ qua) | Khi ghi nhận | Hết ngày |

Nhắc phụ trên Hôm nay (tối đa 1 banner, theo độ ưu tiên): chưa bật thông báo → đơn sắp hết (Q10) → thuốc chưa có ảnh vỉ.

## 6. Thao tác tiết kiệm thời gian
- Nút **"Đã uống đủ"** ngay trên thông báo, ghi nhận mà không cần mở app (Q6).
- Checkbox check sẵn: trường hợp phổ biến nhất (uống đủ) chỉ cần 1 chạm.
- Chữ đọc từ đơn được dùng để **điền sẵn** liều và thời điểm. Ví dụ "Ngày 2 lần, mỗi lần 1 viên, sáng – tối sau ăn" → 1 viên, sau ăn sáng + sau ăn tối.
- Uống sớm: ghi nhận được từ 60 phút trước giờ (Q22). Ghi rồi thì huỷ thông báo của lần đó.
- Sửa giờ sinh hoạt một chỗ, mọi thuốc tự dời theo.

## 7. Bề mặt thứ hai: thông báo và màn khoá

- **Thấy:** tên lần uống, giờ, số loại thuốc. Ví dụ: "Sáng · sau ăn — 3 loại thuốc".
- **Mặc định không thấy trên màn khoá:** tên thuốc, ảnh vỉ, tên đơn (Q7). Lý do: thông tin sức khoẻ, người khác nhìn được màn khoá.
- Khi mở khoá rồi kéo thông báo xuống, hoặc bấm vào thông báo: mở thẳng màn lần uống, có đủ ảnh.

## 8. Thông báo

| Thông báo | Khi nào | Mức | Dừng khi |
| --- | --- | --- | --- |
| Tới giờ uống | Đúng giờ của lần uống | Time Sensitive: hiện cả khi bật Focus, ở lại tới khi người dùng thao tác | Ghi nhận / bỏ qua |
| Nhắc lại | Mỗi 10 phút, tối đa 3 lần (Q4) | Như trên | Ghi nhận / bỏ qua |
| Kiểu báo thức (tuỳ chọn, Q5) | Thay cho thông báo thường, kêu cả khi máy để im lặng | AlarmKit | Ghi nhận / bỏ qua |
| Đơn sắp hết | 9:00 sáng, 1 ngày trước ngày cuối (Q10) | Thường | Tự tắt |

Không có thông báo nào khác. Không quảng cáo.

## 9. Ngoài phạm vi v1
- Android, iPad, Apple Watch.
- Nhiều người dùng / theo dõi giùm người nhà.
- Tài khoản, đồng bộ đám mây, sao lưu iCloud (Q16). Đổi máy thì mất dữ liệu ở v1.
- Đọc đơn bằng AI trên đám mây (Q13).
- App tự học giờ ăn từ lịch sử; bộ giờ riêng cho cuối tuần.
- Theo dõi số thuốc còn lại, nhắc mua thêm (Q15).
- Tra cứu thông tin thuốc, tương tác thuốc, cảnh báo y khoa.
- Widget màn hình chính / màn khoá, Live Activity (Q19, để v1.1).
- Đồng bộ với app Sức khoẻ (Apple Health).
- Đổi múi giờ khi đi du lịch: app dùng giờ hiện tại của máy, không xử lý riêng.
- Xuất báo cáo cho bác sĩ.

## 10. Chi phí vận hành (trả lời câu hỏi "có tốn phí ngầm không")

| Hạng mục | Có tốn phí? | Ghi chú |
| --- | --- | --- |
| Đọc chữ trên ảnh đơn (Apple Vision, chạy trên máy) | **Không** | Miễn phí, chạy cả khi không có mạng. *Rủi ro cần kiểm ở task ML-00:* xác nhận Vision đọc được tiếng Việt có dấu. Nếu không, phải chọn phương án khác. |
| Tách chữ thành danh sách thuốc (luật phân tích trong app) | **Không** | Chạy trên máy. Hợp với đơn in. Đơn viết tay sẽ đọc kém. |
| Apple Foundation Models (AI trên máy, tuỳ chọn) | **Không** | Chỉ có trên iPhone hỗ trợ Apple Intelligence. Hỗ trợ tiếng Việt chưa chắc chắn, phải kiểm. Dùng làm lớp tăng cường, không bắt buộc. |
| AI đám mây (Claude / GPT đọc ảnh) | **Có**, trả theo từng lần quét | Đọc tốt hơn, kể cả chữ viết tay. Nhưng cần server để giấu khoá API, và ảnh đơn bị gửi ra ngoài. **Không làm ở v1** (M03). |
| Thông báo, báo thức | **Không** | Thông báo cục bộ trên máy, không cần server đẩy tin. |
| Lưu trữ | **Không** | Trên máy. |
| Apple Developer Program | 99 USD/năm, **không bắt buộc lúc đầu** | Apple ID miễn phí vẫn cài được lên iPhone của bạn, nhưng 7 ngày phải cài lại một lần. Muốn dùng ổn định, TestFlight hay lên App Store thì cần gói trả phí (Q18). |

**Kết luận: v1 không có chi phí ngầm nào theo lượt dùng.**

## 11. Tiêu chí chấp nhận

Dữ liệu mẫu dùng trong AC là hư cấu, mô phỏng đúng painpoint gốc: 2 đơn, 5 lần uống/ngày, có thuốc cách ngày, có thuốc trước ngủ 1 tiếng.

| ID | Tiêu chí |
| --- | --- |
| AC01 | Onboarding: nhập đủ 6 mốc giờ sinh hoạt (có giờ gợi ý sẵn), được giải thích rồi mới xin quyền thông báo, cuối cùng tới bước "Thêm đơn đầu tiên". Bỏ qua được bước thêm đơn. |
| AC02 | Chụp ảnh một đơn in mẫu → trong ≤ 5 giây hiện danh sách thuốc tách được. Mỗi dòng có tên, số lượng, thời điểm gợi ý. Sửa / xoá / thêm dòng được trước khi lưu. |
| AC03 | Bật chế độ máy bay, chụp đơn vẫn đọc được (đọc chạy trên máy). |
| AC04 | Đọc thất bại (ảnh mờ, viết tay) → app nói rõ "Không đọc được đơn này", cho chụp lại hoặc nhập tay. Không bị kẹt màn. |
| AC05 | Sau khi xác nhận danh sách, app lần lượt mời chụp vỉ mặt trước rồi mặt sau cho từng thuốc. Bỏ qua được. Thuốc thiếu ảnh có nhãn "Chưa có ảnh vỉ" và chụp bổ sung được từ màn thuốc. |
| AC06 | Với giờ sinh hoạt mẫu và 2 đơn mẫu, tab Hôm nay hiện **đúng 5 lần uống**. Mỗi lần đúng thuốc, đúng giờ theo bảng quy tắc ở mục 4.3. Có test tự động cho phần tính này. |
| AC07 | Thuốc "cách 1 ngày" chỉ xuất hiện ở các ngày đúng lịch tính từ ngày bắt đầu. Kiểm trên 14 ngày liên tiếp, có test tự động. |
| AC08 | Đổi giờ ăn sáng 7:00 → 8:00: màn xem trước liệt kê các lần uống sẽ dời. Lưu xong, các lần tương lai dời đúng, thông báo được xếp lịch lại, bản ghi đã lưu không đổi. |
| AC09 | Tới giờ, thông báo hiện trong ≤ 1 phút kể cả khi app đã tắt hẳn. Màn khoá không lộ tên thuốc (theo Q7). |
| AC10 | Chưa ghi nhận thì nhắc lại theo Q4. Ghi nhận rồi thì không nhắc lại nữa. |
| AC11 | Bấm thông báo → mở thẳng màn lần uống đó (1 bước). |
| AC12 | Màn lần uống: mỗi thuốc 1 dòng, ảnh vỉ là hình chính, có số lượng ("2 viên") và cách dùng. **Mọi checkbox đã check sẵn.** Chạm ảnh để xem mặt sau. |
| AC13 | Bấm "Đã uống" → tạo **đúng 1 bản ghi** chứa trạng thái từng thuốc. Trạng thái lần uống là "Đã uống đủ" hoặc "Uống thiếu". Bấm 2 lần nhanh vẫn chỉ ra 1 bản ghi. |
| AC14 | Nút "Đã uống đủ" trên thông báo ghi nhận được mà không mở app. Mở app thấy đúng trạng thái. |
| AC15 | "Bỏ qua lần này" → bản ghi "Bỏ qua", hết nhắc. |
| AC16 | Sửa được bản ghi đã lưu từ Hôm nay và từ Lịch sử. |
| AC17 | Lịch sử tháng: mỗi ngày một dấu theo kết quả (đủ / có thiếu / có bỏ hoặc lỡ / không có thuốc). Dấu phân biệt được bằng **hình dạng**, không chỉ bằng màu. Bấm ngày → xem từng lần uống. |
| AC18 | Sửa tên / ảnh / xoá một thuốc → lịch sử các ngày trước vẫn hiện đúng thuốc và ảnh lúc đó (snapshot). |
| AC19 | Đơn qua ngày cuối thì tự sang "Đã hết", thuốc của đơn không còn trong lần uống từ ngày hôm sau. Nếu một lần uống không còn thuốc nào thì lần đó biến mất. |
| AC20 | Giờ ngủ sau 0h (ví dụ 0:30): lần "trước ngủ 1 tiếng" vẫn thuộc ngày đang sống, không bị mất và không bị tính trùng. |
| AC21 | Chế độ máy bay, đi hết mọi luồng: không lỗi. App không gửi dữ liệu người dùng ra mạng. |
| AC22 | Design: mọi đường vào ≤ 3 bước, mọi task ≤ 3 bước (ngoại lệ đã ghi và được duyệt). Mỗi màn một hành động chính. Kiểm trên iPhone SE / 17 / 17 Pro Max, light + dark, Dynamic Type tới AX1 không vỡ hay cắt chữ. Tương phản đạt AA. VoiceOver đọc tên thuốc cho mỗi ảnh vỉ. Vùng chạm ≥ 44pt. |

## 12. Câu hỏi Q1–Q22 · mặc định đề xuất, chờ duyệt

Bạn duyệt hoặc sửa. Đổi mặc định thì sửa ở đây và ghi CHANGELOG. Các con số là **cấu hình**, đổi được sau mà không mất dữ liệu.

| ID | Câu hỏi | Mặc định đề xuất |
| --- | --- | --- |
| Q1 | "Trước ăn" là trước bữa bao lâu? | 30 phút |
| Q2 | "Sau ăn / sau ăn no" là sau khi bắt đầu ăn bao lâu? | 15 phút |
| Q3 | Gộp thuốc thành một lần uống thế nào? | Chỉ gộp khi cùng mốc + cùng quan hệ, hoặc trùng giờ. Không gộp trước ăn với sau ăn. |
| Q4 | Nhắc lại khi chưa ghi nhận? | Mỗi 10 phút, tối đa 3 lần |
| Q5 | Có nhắc kiểu báo thức (kêu cả khi máy để im lặng) không? | Có làm, **mặc định tắt**, bật bằng 1 công tắc chung trong Cài đặt |
| Q6 | Có nút "Đã uống đủ" ngay trên thông báo không? | Có |
| Q7 | Màn khoá có hiện tên thuốc / ảnh vỉ không? | Không. Chỉ hiện "Sáng · sau ăn — 3 loại thuốc". Có công tắc cho phép hiện. |
| Q8 | Khi nào một lần uống bị tính là "Lỡ"? | Tới giờ lần uống kế tiếp hoặc sau 3 tiếng, tuỳ cái nào tới trước. Vẫn ghi bù được, có nhãn "ghi bù". |
| Q9 | Thuốc cách ngày, nếu lỡ 1 lần thì lịch có dời không? | Không dời, luôn tính theo ngày bắt đầu (đúng như đơn bác sĩ) |
| Q10 | Báo đơn sắp hết lúc nào? Đơn không ghi số ngày thì sao? | Báo 1 ngày trước ngày cuối. Không ghi số ngày thì dùng tới khi người dùng tự tắt. |
| Q11 | Xoá đơn thì lịch sử có mất không? | Không mất (snapshot). Có hộp xác nhận. |
| Q12 | Ngoài vỉ mặt trước + mặt sau, có chụp riêng viên thuốc không? | Tuỳ chọn, không bắt buộc, không nằm trong luồng chụp chính |
| Q13 | Nguồn đọc đơn ở v1? | Chỉ đọc trên máy, miễn phí. AI đám mây để sau khi thấy đọc trên máy không đủ tốt. |
| Q14 | Đơn vị hỗ trợ (đơn da liễu hay có thuốc bôi)? | viên, ½ viên, gói, ml, giọt, lần bôi. Thuốc bôi vẫn nằm trong lần uống như một dòng. |
| Q15 | Đếm số thuốc còn lại, nhắc mua thêm? | Không làm ở v1 |
| Q16 | Sao lưu iCloud? | Không làm ở v1. Chấp nhận rủi ro đổi máy mất dữ liệu. |
| Q17 | iPhone của bạn là đời nào, đang chạy iOS mấy? | *Cần bạn trả lời.* Đề xuất yêu cầu tối thiểu iOS 26 (có AlarmKit). |
| Q18 | Có tài khoản Apple Developer trả phí (99 USD/năm) chưa? | Lúc đầu dùng Apple ID miễn phí để cài lên máy bạn (7 ngày cài lại một lần). Mua khi muốn dùng ổn định. |
| Q19 | Widget màn hình chính / màn khoá hiện lần uống kế tiếp? | Để v1.1 |
| Q20 | Tên app? | Tạm gọi "Nhớ Thuốc" |
| Q21 | Giờ sinh hoạt gợi ý sẵn ở onboarding? | Thức 6:30 · Sáng 7:00 · Trưa 12:00 · Chiều 15:00 · Tối 19:00 · Ngủ 23:00 |
| Q22 | Được ghi nhận sớm trước giờ nhắc bao lâu? | Tới 60 phút. Ghi rồi thì huỷ thông báo của lần đó. |
