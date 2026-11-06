# Nhắc uống thuốc v1 · PRD

Phiên bản 1.0 · 05/11/2026 · Người viết: agent điều phối, theo painpoint và các câu trả lời người phụ trách sản phẩm chốt ngày 05/11/2026.
Trạng thái: **đã duyệt** — 05/11/2026, người phụ trách sản phẩm duyệt ("đi đến bước tiếp theo"). Các Q còn mở đóng theo mặc định đề xuất. Thêm M14 (lời văn + người lớn tuổi) cùng lúc duyệt.

**Đổi ở 1.1 (06/11/2026, sau khi thử app):**
- **Bỏ đơn thuốc.** Không chụp đơn, không tải ảnh đơn, app không đọc chữ trong đơn nữa. Người dùng nhập tay từng **loại thuốc**.
- "Dùng để làm gì" (ví dụ Trị mụn, Huyết áp) là trường tuỳ chọn, thay cho đơn thuốc để gom nhóm thuốc.
- Nhập thuốc theo 5 bước, tham khảo app mẫu người phụ trách gửi:
  1. Tên + dùng để làm gì
  2. Loại thuốc + mỗi liều
  3. Bao lâu uống một lần + giờ
  4. Ảnh thuốc (tuỳ chọn)
  5. Xem lại
- Giờ uống vẫn gợi ý theo giờ ăn và giờ ngủ (mục 4.3). Bỏ nhóm chip "Có gì cần nhớ?" của app mẫu.
- Onboarding: Chào mừng → Giờ ăn, ngủ → Thêm thuốc đầu tiên. Chưa xin quyền thông báo trong onboarding (làm flow cơ bản trước).
- Tab "Đơn thuốc" đổi thành tab "Thuốc".
- Mục 4.2 bỏ. Mục 4.3 viết lại. Các AC nói về chụp đơn, đọc đơn, chụp vỉ (S6–S8) không còn áp dụng.

**Đổi ở 0.3 (góp ý vòng 2):**
- Bỏ việc app tự hỏi "đã hết thuốc chưa". Người dùng tự bấm khi cần (M13).
- Onboarding là một danh sách 4 mốc đã điền sẵn giờ mặc định. Đồng ý thì bấm "Tiếp tục" luôn, muốn đổi thì chạm vào dòng để sửa (M05).
- Buổi chiều mặc định 15:00.
- Máy thật: iPhone 15 Pro, iOS 27.

**Đổi ở 0.2 (góp ý vòng 1 của người phụ trách sản phẩm):**
- Onboarding chỉ hỏi 4 mốc giờ (M05).
- Mỗi thuốc có 1 ảnh vỉ vuông, thấy ngay không phải vuốt (M08).
- Đánh dấu hết thuốc / hết đơn bằng 1 chạm (M13).
- Màn xác nhận đơn liệt kê tên thuốc trong đơn, sửa tên ngay tại chỗ (M06).
- Mọi thông tin thuốc nhập bằng cách chọn, không gõ tay (M12).

Nguồn (chỉ đọc):
- `sources/2026-11-05-painpoint-nguoi-dung.md`: painpoint, mong muốn, câu trả lời vòng hỏi đầu.
- `process/project.md`: stack, design system, kích thước màn kiểm tra.

Đây là feature đầu tiên. Chưa có feature mẫu để làm pattern.

---

## 0. Một câu vấn đề

**Người phải uống nhiều loại thuốc từ nhiều đơn, mỗi loại một giờ** không nhớ được *lúc này cần uống những viên nào*. Họ phải mở lại từng đơn để dò, rồi đối tên trong đơn với vỉ thuốc thật, ngày 5 lần.

## 1. Mục tiêu

Sau v1, người dùng làm được những việc sau:

- **Nhập đơn một lần, không phải mở lại.** Chụp ảnh đơn, app tự tách ra từng loại thuốc. Người dùng sửa lại cho đúng, rồi chụp mỗi loại một tấm ảnh vỉ.
- **Không phải tự tính giờ.** Khai báo giờ ăn sáng, ăn trưa, ăn tối và giờ đi ngủ một lần. App tự xếp từng thuốc vào đúng *lần uống* theo cách dùng ("trước ăn sáng", "sau ăn tối", "trước ngủ 1 tiếng", "cách ngày"…).
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
| M05 | Giờ uống tính từ **giờ sinh hoạt** người dùng tự khai báo. Onboarding là **một màn liệt kê 4 mốc: ăn sáng, ăn trưa, ăn tối, đi ngủ**. Mỗi dòng đã điền sẵn giờ mặc định (Q21). Đồng ý thì bấm "Tiếp tục" luôn (1 chạm). Muốn đổi thì chạm vào dòng, bánh xe giờ mở ra ngay trong dòng đó. Mốc "buổi chiều" cố định mặc định **15:00**, không có trong onboarding, chỉnh trong Cài đặt. App không tự học giờ. Mọi ngày trong tuần dùng chung một bộ giờ. *(sửa 05/11/2026, góp ý vòng 1 + 2)* |
| M06 | Nhập đơn theo 3 bước:<br>(1) Chụp ảnh đơn.<br>(2) App đọc chữ và **liệt kê từng loại thuốc**. Mỗi dòng hiện tên đúng như trong đơn, ô tên **sửa được ngay tại chỗ**, kèm liều và thời điểm đã điền sẵn. Người dùng sửa / thêm / xoá dòng tại đây.<br>(3) Lần lượt chụp **1 ảnh vỉ** cho từng thuốc, đầu màn luôn ghi tên thuốc đang chụp.<br>Bước chụp vỉ bỏ qua được, chụp bổ sung sau. Đọc không được (đơn viết tay, ảnh mờ) thì thêm thuốc bằng cách chọn (M12). |
| M07 | Ghi nhận theo lần uống: 1 bản ghi chứa trạng thái từng thuốc. Checkbox **mặc định check hết**, người dùng bỏ check thuốc chưa uống. |
| M08 | Ảnh vỉ là hình chính của thuốc trên màn ghi nhận. Mỗi thuốc có **1 khung vuông ảnh vỉ**, không phải vuốt hay chạm mới thấy. Tên thuốc là chữ phụ. Khung chụp vỉ cũng là khung vuông. Chạm vào ảnh để phóng to. *(sửa 05/11/2026 theo góp ý vòng 1; sửa 06/11/2026: bỏ ảnh mặt sau, mỗi vỉ chỉ cần 1 ảnh)* |
| M09 | Điều hướng bằng tab bar dưới cùng, 4 tab: **Hôm nay · Đơn thuốc · Lịch sử · Cài đặt**. |
| M10 | Lịch dùng mỗi thuốc có 3 kiểu: hằng ngày / cách N ngày / các thứ cố định trong tuần. Có ngày bắt đầu và số ngày dùng (hoặc "dùng tới khi tắt"). |
| M11 | Bản ghi giữ **ảnh chụp tại thời điểm uống** (snapshot): tên, số lượng, ảnh của từng thuốc lúc đó. Sau này sửa hay xoá thuốc thì lịch sử cũ không đổi. |
| M12 | **Chọn thay vì gõ.** Mọi thông tin thuốc trừ tên đều nhập bằng nút chọn (chip), không gõ tay:<br>- liều (½, 1, 2, 3, khác)<br>- đơn vị<br>- thời điểm (trước ăn / trong bữa / sau ăn / buổi chiều / trước ngủ / giờ cố định)<br>- bữa (sáng / trưa / tối)<br>- độ lệch (ví dụ 15 / 30 / 45 / 60 phút)<br>- lịch (hằng ngày / cách 1 ngày / cách 2 ngày / chọn thứ)<br>- số ngày dùng<br>App đọc được gì từ đơn thì chọn sẵn chip đó. Đơn không ghi số phút thì dùng mặc định ("trước ăn" = 30 phút), người dùng chạm chip khác để đổi. Chỉ có tên là ô chữ, và đã điền sẵn tên đọc từ đơn. |
| M13 | **Hết thuốc dễ đánh dấu.** App **không tự hỏi** — người dùng tự bấm khi cần *(sửa 05/11/2026, góp ý vòng 2)*. Có 2 chỗ, đều thấy ngay, xong trong 1–2 chạm:<br>(1) Màn lần uống: mỗi thuốc có "Hết thuốc" trong menu "…" của dòng.<br>(2) Chi tiết đơn: mỗi thuốc có nút "Đã hết" ngay trên dòng; nút "Hết cả đơn" ghim ở đáy màn, ngay vùng ngón cái *(sửa 06/11/2026: màn chỉ có 1 CTA chính thì CTA nằm đáy)*.<br>Mọi lần đánh dấu đều có "Hoàn tác" ngay sau đó. |
| M14 | **Lời văn tự nhiên, người lớn tuổi dùng dễ.** Nhóm người dùng dễ cần app nhất là người lớn tuổi. Vì vậy:<br>- **Lời văn như người nhà nhắc nhau**, câu ngắn, không thuật ngữ, không viết tắt. Ví dụ: "Tới giờ uống thuốc buổi sáng rồi" thay cho "Lần uống Sáng · sau ăn đã tới hạn". Bảng từ ngữ ở mục 13.<br>- **Chữ to mặc định**: chữ thường tối thiểu 17pt, nội dung chính 20pt trở lên. Theo cỡ chữ của máy (Dynamic Type), kiểm tới AX3.<br>- **Tương phản cao**, đạt AA, chữ chính nhắm AAA (7:1).<br>- **Nút lớn**: nút chính cao ≥ 56pt, kéo hết chiều ngang. Mọi vùng chạm ≥ 48pt.<br>- **Nút luôn có chữ**, không có nút chỉ có icon.<br>- **Không có thao tác "ẩn"** như vuốt dòng hay nhấn giữ làm cách duy nhất; nếu có thì chỉ là đường tắt.<br>- **Mỗi màn một việc chính.**<br>- Thông báo lỗi nói **làm gì tiếp theo**, không nói lỗi gì. *(thêm 05/11/2026)* |

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
- **Nguồn:** onboarding liệt kê 4 mốc (ăn sáng, ăn trưa, ăn tối, đi ngủ) đã điền sẵn giờ mặc định (Q21), người dùng chạm dòng nào thì sửa dòng đó. Mốc "buổi chiều" mặc định 15:00, chỉnh trong Cài đặt.
- **Sửa:** ở tab Cài đặt. Trước khi lưu, app hiện trước "các lần uống sẽ dời thành…".
- **Lan truyền:** chỉ áp cho các lần uống **từ bây giờ trở đi**, bản ghi đã lưu giữ nguyên. Thông báo được xếp lịch lại ngay.

### 4.2 Đơn thuốc — **bỏ ở 1.1** (06/11/2026)
Thay bằng trường "Dùng để làm gì" của từng thuốc. Thuốc không còn thuộc về đơn nào.

### 4.3 Thuốc (nhập tay, sửa ở 1.1)
| Thông tin | Ví dụ (hư cấu) | Bắt buộc |
| --- | --- | --- |
| Tên thuốc (ô chữ) | "Amlodipin" | ✓ |
| Dùng để làm gì (ô chữ, có chip gợi ý: mục đã dùng + Huyết áp, Tiểu đường, Trị mụn, Dạ dày, Vitamin) | "Huyết áp" | Tuỳ chọn |
| Loại thuốc (lưới 8 ô) | Viên nén · Viên nang · Dung dịch · Giọt · Tiêm · Kem bôi · Ống hít · Khác | ✓ (mặc định Viên nén) |
| Mỗi liều (nút − / +) | 1 viên nén · ½ viên nén · 5 ml · 1 giọt | ✓ |
| Bao lâu một lần | Một lần / Hai lần / 3 lần mỗi ngày / Lịch khác | ✓ (mặc định 1 lần) |
| Lịch khác | Một số ngày (T2…CN, 1–3 lần/ngày) · Cách 1–3 ngày (1–3 lần/ngày) · Mỗi 4/6/8/12 tiếng | |
| Giờ uống | Gợi ý sẵn theo bữa, chạm để đổi (bảng dưới) | ✓ |
| Ảnh thuốc | 1 ảnh vuông (chụp hoặc chọn từ thư viện) | Tuỳ chọn |
| Trạng thái | `Đang uống` / `Tạm dừng` / `Đã hết` (hoàn tác được) | ✓ |

**Giờ gợi ý theo số lần mỗi ngày.**
| Số lần | Giờ gợi ý (mặc định sau ăn 15 phút) |
| --- | --- |
| 1 | sau ăn sáng |
| 2 | sau ăn sáng, sau ăn tối |
| 3 | sau ăn sáng, trưa, tối |
| Mỗi N tiếng | từ giờ đầu tiên (mặc định sau ăn sáng), cộng N tiếng tới trước giờ ngủ |

Chạm một giờ sẽ mở sheet. Ở đó chọn:
- Buổi: Sáng / Trưa / Chiều / Tối / Trước ngủ / Giờ khác.
- Trước ăn, trong bữa hay sau ăn.
- Bao lâu, theo bảng dưới.

"Giờ khác" là giờ cố định, chọn bằng bánh xe giờ.

**Quy tắc đổi thời điểm thành giờ.** Độ lệch chọn bằng chip theo từng thuốc. Đơn có ghi số phút thì chọn sẵn đúng số đó, không ghi thì dùng mặc định (Q1–Q2):

| Thời điểm | Giờ uống | Chip độ lệch |
| --- | --- | --- |
| Trước ăn [sáng/trưa/tối] (gồm "lúc đói") | giờ bữa − X | 15 · **30** · 45 · 60 phút |
| Trong bữa [sáng/trưa/tối] | giờ bữa | — |
| Sau ăn / sau ăn no [sáng/trưa/tối] | giờ bữa + X | Ngay sau · **15** · 30 · 60 phút |
| Buổi chiều | mốc "buổi chiều" (mặc định 15:00) | — |
| Trước khi ngủ | giờ ngủ − X | 15 · 30 · **60** · 120 phút |
| Giờ cố định | giờ người dùng chọn bằng bánh xe giờ | — |

### 4.4 Lần uống (tính ra, không nhập tay)
- Mỗi ngày, app gom các *thời điểm* của mọi thuốc đang dùng thành các lần uống.
- **Quy tắc gộp (Q3):** gộp khi cùng mốc và cùng quan hệ (ví dụ cùng "sau ăn sáng"), hoặc khi giờ tính ra trùng nhau. **Không bao giờ gộp "trước ăn" với "sau ăn".**
- Tên lần uống tự đặt theo mốc: "Sáng · trước ăn", "Sáng · sau ăn", "Chiều", "Tối · sau ăn", "Trước ngủ".
- **Ngày uống thuốc** kết thúc ở giờ đi ngủ, không cắt ở 0h. Lần uống nào rơi sau 0h nhưng trước giờ ngủ thì vẫn thuộc ngày đang sống. Ví dụ giờ ngủ là 1:00 thì lần "trước ngủ 30 phút" lúc 0:30 thuộc ngày hôm trước.

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

### 5.1 Đánh dấu ngay trên Hôm nay *(thêm 06/11/2026, theo mẫu tham khảo người phụ trách gửi; làm thẳng trong app)*

Thứ tự ở bảng trên giữ nguyên. Chỉ đổi cách hiện từng lần uống: không còn thẻ tóm tắt rồi mở màn đánh dấu, mà **hiện thẳng từng thuốc và đánh dấu ngay tại dòng**.

- **Mỗi lần uống là 1 nhóm.** Đầu nhóm: biểu tượng buổi (màu riêng), tên buổi, giờ uống, chữ trạng thái. Dưới danh sách thuốc: nút **"Uống đủ N thuốc"** kéo hết chiều ngang (ghi cả buổi trong 1 chạm); buổi chỉ có 1 thuốc thì không có nút này.
- **Mỗi thuốc 1 dòng** trong nhóm: ảnh vỉ vuông (chạm để phóng to, D1), tên thuốc, số lượng + cách dùng ("1 viên · sau ăn"). Bên phải là **nút tròn đánh dấu ≥ 48pt**:
  - chưa uống: nút viền, dấu ＋
  - đã uống: nút xanh lá, dấu ✓, dòng phụ đổi thành "Đã uống 1 viên" màu xanh lá
- Chạm nút lần nữa là bỏ đánh dấu. Mỗi lần chạm hiện toast ngắn kèm **"Hoàn tác"**.
- **Đánh dấu được khi nào:** lần uống tới giờ, bị lỡ, và **lần uống kế tiếp, lúc nào cũng được** dù còn xa giờ *(sửa 06/11/2026 theo góp ý: không ẩn nút)*. Các lần sau đó trong ngày chỉ xem, chưa có nút.
- **Trạng thái lần uống** tính từ các dấu:
  - tất cả thuốc đã đánh dấu → "Đã uống đủ", nhóm thu gọn xuống phần "Đã xong"
  - đánh dấu một phần → "Còn 1 thuốc chưa uống", nhóm **vẫn ở trên**, dừng nhắc lại
  - tới lúc lần uống bị tính lỡ (Q8) mà vẫn còn thiếu → "Uống thiếu", chuyển xuống "Đã xong"
- **Các lần còn lại trong ngày** (nhóm 3) và **các lần đã xong** (nhóm 4) hiện gọn 1 dòng. Chạm vào thì mở ra xem từng thuốc, và với lần đã xong thì sửa dấu được ngay tại chỗ (AC16).
- Cuối nhóm tới giờ / bị lỡ có 2 nút chữ nhỏ (không dùng nút "…" chỉ có icon, theo M14): **"Hôm nay bỏ cữ này"** (có xác nhận) và **"Có thuốc đã hết"** (mở màn S2 để chọn thuốc).
- Màn S2 vẫn giữ, dùng khi bấm vào lời nhắc (E1) và khi sửa từ Lịch sử.

Nhắc phụ trên Hôm nay (tối đa 1 banner, theo độ ưu tiên):
1. Chưa bật thông báo.
2. Thuốc chưa có ảnh vỉ.

## 6. Thao tác tiết kiệm thời gian
- Nút **"Đã uống đủ"** ngay trên thông báo, ghi nhận mà không cần mở app (Q6).
- Checkbox check sẵn: trường hợp phổ biến nhất (uống đủ) chỉ cần 1 chạm.
- Trên Hôm nay: nút "Uống đủ" ở đầu mỗi lần uống ghi cả buổi trong 1 chạm; uống thiếu thì chạm từng thuốc đã uống (mục 5.1).
- Chữ đọc từ đơn được dùng để **chọn sẵn chip** liều và thời điểm. Ví dụ "Ngày 2 lần, mỗi lần 1 viên, sáng – tối sau ăn" → chip 1 viên, sau ăn sáng + sau ăn tối, độ lệch mặc định. "Uống trước ăn sáng 30 phút" → chip trước ăn · sáng · 30 phút.
- **Không gõ tay** ngoài tên và ghi chú (M12).
- **Hết thuốc 1–2 chạm** ngay trên màn lần uống hoặc chi tiết đơn (M13).
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
| AC01 | Onboarding: một màn liệt kê **4 mốc** (ăn sáng, ăn trưa, ăn tối, đi ngủ) **đã điền sẵn giờ mặc định**. Không sửa gì thì bấm "Tiếp tục" là xong bước này (1 chạm). Chạm một dòng → bánh xe giờ mở ngay trong dòng đó. Sau đó được giải thích rồi mới xin quyền thông báo, cuối cùng tới bước "Thêm đơn đầu tiên". Bỏ qua được bước thêm đơn. |
| AC02 | Chụp ảnh một đơn in mẫu → trong ≤ 5 giây hiện danh sách thuốc tách được. Mỗi dòng có: tên đúng như trong đơn, ô tên **sửa được ngay tại dòng đó**, số lượng và thời điểm đã chọn sẵn. Sửa / xoá / thêm dòng được trước khi lưu. |
| AC03 | Bật chế độ máy bay, chụp đơn vẫn đọc được (đọc chạy trên máy). |
| AC04 | Đọc thất bại (ảnh mờ, viết tay) → app nói rõ "Không đọc được đơn này", cho chụp lại hoặc thêm thuốc bằng cách chọn. Không bị kẹt màn. |
| AC05 | Sau khi xác nhận danh sách, app lần lượt mời chụp 1 ảnh vỉ cho từng thuốc. Khung chụp vuông, đầu màn ghi tên thuốc đang chụp. Bỏ qua được. Thuốc thiếu ảnh có nhãn "Chưa có ảnh vỉ" và chụp bổ sung được từ màn thuốc. |
| AC06 | Với giờ sinh hoạt mẫu và 2 đơn mẫu, tab Hôm nay hiện **đúng 5 lần uống**. Mỗi lần đúng thuốc, đúng giờ theo bảng quy tắc ở mục 4.3. Có test tự động cho phần tính này. |
| AC07 | Thuốc "cách 1 ngày" chỉ xuất hiện ở các ngày đúng lịch tính từ ngày bắt đầu. Kiểm trên 14 ngày liên tiếp, có test tự động. |
| AC08 | Đổi giờ ăn sáng 7:00 → 8:00: màn xem trước liệt kê các lần uống sẽ dời. Lưu xong, các lần tương lai dời đúng, thông báo được xếp lịch lại, bản ghi đã lưu không đổi. |
| AC09 | Tới giờ, thông báo hiện trong ≤ 1 phút kể cả khi app đã tắt hẳn. Màn khoá không lộ tên thuốc (theo Q7). |
| AC10 | Chưa ghi nhận thì nhắc lại theo Q4. Ghi nhận rồi thì không nhắc lại nữa. |
| AC11 | Bấm thông báo → mở thẳng màn lần uống đó (1 bước). |
| AC12 | Màn lần uống: mỗi thuốc 1 dòng, **1 ảnh vỉ vuông**, thấy ngay không cần vuốt. Có số lượng ("2 viên") và cách dùng. **Mọi checkbox đã check sẵn.** Chạm ảnh để phóng to. Kiểm cả trên iPhone SE và Dynamic Type AX1. |
| AC13 | Bấm "Đã uống" → tạo **đúng 1 bản ghi** chứa trạng thái từng thuốc. Trạng thái lần uống là "Đã uống đủ" hoặc "Uống thiếu". Bấm 2 lần nhanh vẫn chỉ ra 1 bản ghi. |
| AC14 | Nút "Đã uống đủ" trên thông báo ghi nhận được mà không mở app. Mở app thấy đúng trạng thái. |
| AC15 | "Bỏ qua lần này" → bản ghi "Bỏ qua", hết nhắc. |
| AC16 | Sửa được bản ghi đã lưu từ Hôm nay và từ Lịch sử. |
| AC17 | Lịch sử tháng: mỗi ngày một dấu theo kết quả (đủ / có thiếu / có bỏ hoặc lỡ / không có thuốc). Dấu phân biệt được bằng **hình dạng**, không chỉ bằng màu. Bấm ngày → xem từng lần uống. |
| AC18 | Sửa tên / ảnh / xoá một thuốc → lịch sử các ngày trước vẫn hiện đúng thuốc và ảnh lúc đó (snapshot). |
| AC19 | Đánh dấu "Đã hết" 1 thuốc hoặc "Hết cả đơn" → các lần uống, kể cả lần còn lại của hôm nay, không còn thuốc đó, và thông báo đã xếp lịch được huỷ. Nếu một lần uống không còn thuốc nào thì lần đó biến mất. Hiện "Hoàn tác" trong vài giây; bấm thì mọi thứ trở lại như cũ. |
| AC20 | Giờ ngủ sau 0h (ví dụ 0:30): lần "trước ngủ 1 tiếng" vẫn thuộc ngày đang sống, không bị mất và không bị tính trùng. |
| AC21 | Chế độ máy bay, đi hết mọi luồng: không lỗi. App không gửi dữ liệu người dùng ra mạng. |
| AC23 | Trên màn lần uống, đánh dấu một thuốc "Hết thuốc" xong trong ≤ 2 chạm. Ở chi tiết đơn, nút "Hết cả đơn" ghim ở đáy màn, thấy ngay không cần cuộn, xong trong ≤ 2 chạm (bấm + xác nhận). |
| AC24 | App **không** tự hỏi "đã hết thuốc chưa" ở bất kỳ đâu (không banner, không thông báo). Đơn đủ số ngày dùng chỉ hiện nhãn "Đã đủ N ngày" trong chi tiết đơn, thuốc vẫn được nhắc tới khi người dùng bấm hết. |
| AC25 | Thêm hoặc sửa một thuốc: mọi trường trừ tên và ghi chú đều chọn bằng chip hoặc bánh xe giờ, **không có bàn phím bật lên**. Đơn không ghi số phút "trước ăn" → chip 30 phút được chọn sẵn. |
| AC26 | Trên Hôm nay, lần uống tới giờ hiện từng thuốc với ảnh vỉ và nút đánh dấu. Bấm "Uống đủ" → 1 bản ghi "Đã uống đủ", nhóm chuyển xuống "Đã xong", hết nhắc lại. Chạm 1 trong 2 thuốc → nhóm ghi "Còn 1 thuốc chưa uống", hết nhắc lại. Mỗi lần chạm có "Hoàn tác". Lần uống kế tiếp đánh dấu được ngay cả khi còn xa giờ. *(thêm 06/11/2026)* |
| AC22 | Design: mọi đường vào ≤ 3 bước, mọi task ≤ 3 bước (ngoại lệ đã ghi và được duyệt). Mỗi màn một hành động chính. Kiểm trên iPhone SE / 17 / 17 Pro Max, light + dark, Dynamic Type tới AX3 không vỡ hay cắt chữ. Tương phản đạt AA. VoiceOver đọc tên thuốc cho mỗi ảnh vỉ. Vùng chạm ≥ 48pt, nút chính ≥ 56pt. Không có nút chỉ có icon. |

## 12. Câu hỏi Q1–Q26 · mặc định đề xuất, chờ duyệt (Q10, Q17, Q23 đã chốt; Q24, Q25 đã bỏ)

Bạn duyệt hoặc sửa. Đổi mặc định thì sửa ở đây và ghi CHANGELOG. Các con số là **cấu hình**, đổi được sau mà không mất dữ liệu.

| ID | Câu hỏi | Mặc định đề xuất |
| --- | --- | --- |
| Q1 | "Trước ăn" mặc định trước bữa bao lâu, khi đơn không ghi? | 30 phút. Đổi bằng chip 15 / 30 / 45 / 60 cho từng thuốc. |
| Q2 | "Sau ăn / sau ăn no" mặc định sau bữa bao lâu? | 15 phút. Chip: Ngay sau / 15 / 30 / 60. |
| Q3 | Gộp thuốc thành một lần uống thế nào? | Chỉ gộp khi cùng mốc + cùng quan hệ, hoặc trùng giờ. Không gộp trước ăn với sau ăn. |
| Q4 | Nhắc lại khi chưa ghi nhận? | Mỗi 10 phút, tối đa 3 lần |
| Q5 | Có nhắc kiểu báo thức (kêu cả khi máy để im lặng) không? | Có làm, **mặc định tắt**, bật bằng 1 công tắc chung trong Cài đặt |
| Q6 | Có nút "Đã uống đủ" ngay trên thông báo không? | Có |
| Q7 | Màn khoá có hiện tên thuốc / ảnh vỉ không? | Không. Chỉ hiện "Sáng · sau ăn — 3 loại thuốc". Có công tắc cho phép hiện. |
| Q8 | Khi nào một lần uống bị tính là "Lỡ"? | Tới giờ lần uống kế tiếp hoặc sau 3 tiếng, tuỳ cái nào tới trước. Vẫn ghi bù được, có nhãn "ghi bù". |
| Q9 | Thuốc cách ngày, nếu lỡ 1 lần thì lịch có dời không? | Không dời, luôn tính theo ngày bắt đầu (đúng như đơn bác sĩ) |
| Q10 | Đơn đủ số ngày dùng thì xử lý sao? | **Đã chốt 05/11/2026:** không tự tắt, không hỏi. Chỉ hiện nhãn "Đã đủ N ngày" trong chi tiết đơn. |
| Q11 | Xoá đơn thì lịch sử có mất không? | Không mất (snapshot). Có hộp xác nhận. |
| Q12 | Ngoài ảnh vỉ, có chụp riêng viên thuốc không? | Tuỳ chọn, không bắt buộc, không nằm trong luồng chụp chính |
| Q13 | Nguồn đọc đơn ở v1? | Chỉ đọc trên máy, miễn phí. AI đám mây để sau khi thấy đọc trên máy không đủ tốt. |
| Q14 | Đơn vị hỗ trợ (đơn da liễu hay có thuốc bôi)? | viên, ½ viên, gói, ml, giọt, lần bôi. Thuốc bôi vẫn nằm trong lần uống như một dòng. |
| Q15 | Đếm số thuốc còn lại, nhắc mua thêm? | Không làm ở v1 |
| Q16 | Sao lưu iCloud? | Không làm ở v1. Chấp nhận rủi ro đổi máy mất dữ liệu. |
| Q17 | iPhone của bạn là đời nào, đang chạy iOS mấy? | **Đã chốt 05/11/2026:** iPhone 15 Pro, iOS 27 (*xác nhận lại khi cắm máy ở ML-00*). App yêu cầu tối thiểu iOS 26. Máy có Apple Intelligence nên thử được AI trên máy để tách thuốc. |
| Q18 | Có tài khoản Apple Developer trả phí (99 USD/năm) chưa? | Lúc đầu dùng Apple ID miễn phí để cài lên máy bạn (7 ngày cài lại một lần). Mua khi muốn dùng ổn định. |
| Q19 | Widget màn hình chính / màn khoá hiện lần uống kế tiếp? | Để v1.1 |
| Q20 | Tên app? | Tạm gọi "Nhớ Thuốc" |
| Q21 | Giờ điền sẵn ở onboarding (4 mốc)? | Ăn sáng 7:00 · Ăn trưa 12:00 · Ăn tối 19:00 · Đi ngủ 23:00 |
| Q22 | Được ghi nhận sớm trước giờ nhắc bao lâu? | Tới 60 phút. Ghi rồi thì huỷ thông báo của lần đó. |
| Q23 | Mốc "buổi chiều" lấy ở đâu? | **Đã chốt 05/11/2026:** mặc định 15:00, không có trong onboarding, chỉnh trong Cài đặt. |
| Q24 | ~~Bỏ check bao nhiêu lần thì app hỏi "đã hết chưa"?~~ | **Bỏ 05/11/2026:** app không tự hỏi. |
| Q25 | ~~Trả lời "Vẫn còn" thì bao lâu sau hỏi lại?~~ | **Bỏ 05/11/2026:** app không tự hỏi. |
| Q26 | Thuốc đã hết có hiện lại không? | Hiện trong chi tiết đơn ở nhóm "Đã hết" (mờ, thu gọn), bấm "Dùng lại" được. Không hiện ở Hôm nay. |

## 13. Lời văn trong app (M14)

Giọng: như con cháu nhắc ông bà, bố mẹ — nhẹ nhàng, rõ ràng, không ra lệnh, không đùa. **Hạn chế xưng hô**; khi cần thì dùng "bạn" (Q27). Câu ≤ 12 chữ khi có thể.

**Rút gọn chữ (06/11/2026, theo góp ý "quá nhiều chữ"):**
- Cái gì icon, màu hoặc trạng thái nói được thì bỏ chữ. Ví dụ: dấu ✓ trên nút đã thay câu "Đã uống 1 viên"; viền đỏ + "Chưa uống" thay câu dài.
- Không câu giải thích dưới tiêu đề. Chỉ giữ câu khi nó nói hậu quả của việc không đảo ngược được (ví dụ "Xoá hết dữ liệu?").
- "N loại thuốc" → **"N thuốc"**. Toast chỉ nói kết quả: "Đã uống đủ", "Đã bỏ cữ", "<Tên thuốc>: đã hết".
- Hôm nay: tiêu đề + ngày + "3/5" + dãy chấm trạng thái gộp 1 khối; mục "Kế tiếp", "Còn lại", "Đã xong".

Bảng dưới là bản chốt sau khi rút gọn (cột "Dùng" là chữ đang có trong app).

| Tránh | Dùng |
| --- | --- |
| Lần uống / slot / cữ | **Giờ uống thuốc** ("Giờ uống thuốc buổi sáng") |
| Sáng · sau ăn | **Sáng, sau khi ăn** |
| Ghi nhận / check-in / log | **Đánh dấu đã uống** |
| Đã uống đủ | **Đã uống đủ** (giữ) |
| Uống thiếu · 1 thuốc | **Thiếu 1** (chip ◐ màu cam) |
| Bỏ qua lần này | **Bỏ cữ** · hộp xác nhận "Bỏ cữ 7:30?" |
| Lỡ | **Chưa uống** (viền đỏ) |
| Ghi bù | **Đánh dấu muộn** |
| Hết cả đơn | **Hết đơn này** |
| Hết thuốc | **Hết thuốc** |
| Hoàn tác | **Hoàn tác** → hoặc "Bấm nhầm, lấy lại" (Q28) |
| Không đọc được đơn này | **Chưa đọc được đơn** · "Chụp lại cho rõ, hoặc tự thêm thuốc." |
| Thông báo: "Sáng · sau ăn — 3 loại thuốc" | **"Tới giờ uống thuốc rồi" — "Sáng, sau khi ăn · 3 thuốc"** |
| Đơn vị "½ viên" | **"Nửa viên"** |



Thêm câu hỏi (mặc định dùng luôn, sửa ở preview):

| ID | Câu hỏi | Mặc định đề xuất |
| --- | --- | --- |
| Q27 | Xưng hô trong app? | Hạn chế xưng hô; khi cần thì "bạn" |
| Q28 | Câu chữ cho bỏ qua / hoàn tác? | Chốt khi xem preview, với 2–3 phương án đặt cạnh nhau |

