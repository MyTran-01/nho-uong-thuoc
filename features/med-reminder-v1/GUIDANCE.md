# Nhắc uống thuốc v1 · Hướng dẫn kỹ thuật

Viết cho agent thi hành. Đọc cùng `PRD.md`, `USER_FLOW.md`. Khi đã có preview duyệt thì mở `prototype/` để đối chiếu.

## 1. Đang có, dùng lại

Repo code chưa tồn tại. Không có gì để tái dùng ngoài framework của Apple:

| Thứ | Dùng cho |
|---|---|
| SwiftUI (TabView, NavigationStack, List, sheet, fullScreenCover) | Toàn bộ UI. Không custom style ngoài token đã duyệt (G0). |
| SwiftData | Lưu đơn, thuốc, giờ sinh hoạt, bản ghi |
| UserNotifications | Thông báo cục bộ, category có action "Đã uống đủ", interruptionLevel `.timeSensitive` |
| AlarmKit (iOS 26+) | Nhắc kiểu báo thức (Q5), chỉ khi người dùng bật |
| Vision (`RecognizeTextRequest`) | Đọc chữ trên ảnh đơn |
| FoundationModels (tuỳ chọn) | Tách chữ thành danh sách thuốc. Chỉ dùng khi `SystemLanguageModel` khả dụng **và** hỗ trợ tiếng Việt, ngược lại dùng luật phân tích. |
| VisionKit `DataScannerViewController` / AVFoundation | Camera chụp đơn và chụp vỉ |
| PhotosPicker | Chọn ảnh từ thư viện, không cần quyền thư viện đầy đủ |

## 2. Mô hình dữ liệu gợi ý

```
DailyRoutine (1 bản)       wake, breakfast, lunch, afternoon, dinner, bed : phút-trong-ngày (Int)
                           beforeMealOffset=30, afterMealOffset=15 (Q1, Q2 — cấu hình)
Prescription               id, name, photo (file ref), issuedOn, clinic?, startDate, durationDays?,
                           status: active|paused|ended, createdAt
Medication                 id, prescription, nameOnRx, nickname?, frontPhoto?, backPhoto?, pillPhoto?,
                           doseAmount: Decimal, doseUnit: enum, method?, note?,
                           schedule: daily | everyNDays(n) | weekdays(Set<Int>),
                           startDate (mặc định = đơn), endDate? (tính từ đơn),
                           timings: [Timing]
Timing                     anchor: wake|breakfast|lunch|afternoon|dinner|bed|fixed
                           relation: before|during|after|at   offsetMinutes?   fixedTime?
DoseLog                    id, slotKey (ngày-uống + khoá lần uống), scheduledAt, recordedAt?,
                           status: taken|partial|skipped|missed, isBackfill,
                           items: [DoseLogItem]  ← snapshot (M11)
DoseLogItem                medicationId?, nameSnapshot, doseSnapshot, frontPhotoSnapshot, taken: Bool
```

- **Lần uống (slot) không lưu.** Tính bằng hàm thuần `slots(for day, routine, medications) -> [Slot]`. Đây là lõi, test kỹ nhất.
- Ảnh lưu thành file trong thư mục Application Support của app, DB chỉ giữ đường dẫn. Snapshot ảnh = copy file (hoặc tham chiếu bất biến, không bao giờ ghi đè file cũ khi người dùng chụp lại).
- `DoseLog` có ràng buộc duy nhất trên `slotKey`. Nhờ vậy bấm 2 lần hoặc vừa bấm trên thông báo vừa bấm trong app vẫn ra 1 bản ghi (AC13, AC14).

## 3. Quyền

App một người dùng, không có role. Quyền hệ thống iOS xem PRD mục 3.

## 4. View model

| Tên | Vào | Ra |
|---|---|---|
| `SlotEngine.slots(day:routine:meds:)` | ngày uống, giờ sinh hoạt, thuốc đang dùng | `[Slot]` đã sắp theo giờ, mỗi slot có `key`, `time`, `title`, `items` |
| `TodayViewModel` | now, slots hôm nay, logs hôm nay | các nhóm theo thứ tự PRD mục 5 + banner duy nhất |
| `DoseSessionViewModel` | slot, log hiện có? | items có checkbox (mặc định true), `record()`, `skip()` |
| `RxParser.parse(lines:)` | các dòng chữ từ Vision | `[DraftMedication]` + độ tin cậy từng trường |
| `NotificationScheduler.reschedule(now:)` | slots N ngày tới, logs | đăng ký lại thông báo (xem bẫy số 1) |
| `HistoryViewModel` | tháng | trạng thái mỗi ngày: `allTaken / hasPartial / hasSkippedOrMissed / none` |

## 5. Hợp đồng dữ liệu

| Màn/caller | Hàm | Mốc thời gian | Biên | Đơn vị | Thiếu dữ liệu |
|---|---|---|---|---|---|
| S1, thông báo | `SlotEngine.slots` | **Ngày uống** = từ `wake` tới `bed`, giờ địa phương của máy. `bed` < `wake` nghĩa là ngủ sau 0h, khi đó slot sau 0h thuộc ngày uống trước. | gồm cả wake, gồm cả bed | phút | Không có thuốc thì trả `[]`, không trả slot rỗng |
| Thuốc cách ngày | `isDue(day)` | `(day - startDate) % (n+1) == 0` theo **ngày uống** | gồm startDate, gồm endDate | ngày | Thiếu endDate thì dùng tới khi tắt |
| S9 | `HistoryViewModel` | ngày uống | — | — | Ngày không có slot là `none`, khác ngày "lỡ hết" |
| Lỡ (Q8) | `missedAt(slot)` | min(slot kế tiếp, slot.time + 3h) | — | phút | Slot cuối ngày dùng +3h |

Breaking change: chưa có, vì đây là bản đầu.

## 6. Bẫy

1. **iOS chỉ giữ tối đa 64 thông báo cục bộ đang chờ.** 5 slot × 4 lần (1 gốc + 3 nhắc lại) = 20/ngày, nên chỉ xếp lịch khoảng 2–3 ngày tới. Gọi `reschedule` khi: mở app, ghi nhận, đổi dữ liệu, và background refresh. Có test đếm ≤ 64.
2. **Nhắc lại phải huỷ được.** Đặt identifier theo `slotKey#n` để huỷ chính xác khi đã ghi nhận.
3. **Action trên thông báo chạy khi app không mở.** Ghi `DoseLog` từ notification delegate phải dùng cùng store SwiftData và tôn trọng ràng buộc duy nhất. Test ghi trùng.
4. **Giờ ngủ sau 0h** (AC20): không cắt ngày ở 0h. Có test cho bed = 0:30 và bed = 1:00.
5. **Đổi giờ sinh hoạt** chỉ ảnh hưởng slot tương lai. Không tính lại `scheduledAt` của log cũ.
6. **Vision và tiếng Việt chưa chắc chắn.** ML-00 phải gọi `supportedRecognitionLanguages` trên iOS đích và chạy thử ảnh đơn mẫu có dấu. Nếu không có `vi`: dừng và báo người phụ trách, **không** tự chuyển sang AI đám mây.
7. **Không gửi dữ liệu ra mạng** (AC21). Không thêm SDK analytics hay crash reporting bên thứ ba.
8. Dữ liệu mẫu là **hư cấu** và nằm trong test fixture. Không chép đơn thuốc thật vào repo.
9. Đơn vị `½ viên`: lưu `Decimal`, không dùng `Double`, để hiện "½" cho đúng.
10. Đổi ngày hệ thống / múi giờ: tính lại slot theo giờ máy hiện tại khi app vào foreground. Không xử lý thêm (ngoài phạm vi).
