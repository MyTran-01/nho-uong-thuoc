import Foundation
import Testing
@testable import NhoThuoc

// Lines as Vision returned them for the fictional fixture Fixtures/Images/don-da-lieu.png.
private let dermatologyLines = [
    "PHÒNG KHÁM DA LIỄU MÃU",
    "Địa chỉ: 123 Đường Mẫu, Quận Mẫu (dữ liệu hư cấu)",
    "ĐƠN THUỐC",
    "Họ tên: Nguyễn Văn Mẫu  Tuổi: 62",
    "Chẩn đoán: dữ liệu mẫu để thử ứng dụng",
    "1. Thuốc Da Liễu A 10mg  30 viên",
    "Uống trước ăn sáng, mỗi lần 1 viên",
    "2. Thuốc Da Liễu B 250mg  60 viên",
    "Ngày 2 lần, sáng - tối sau ăn, mỗi lần 2 viên",
    "3. Thuốc Da Liễu C 5mg  30 viên",
    "Uống buổi chiều, mỗi lần 1 viên",
    "4. Thuốc Da Liễu D 2mg  15 viên",
    "Uống trước khi ngủ 1 tiếng, mỗi lần 1/2 viên",
    "Ngày 05 tháng 11 năm 2026",
    "Bác sĩ khám bệnh",
    "BS. Trần Thị Mẫu",
]

@Suite("RxParser")
struct RxParserTests {
    @Test func findsEveryMedicationWithOriginalAndShortName() {
        let r = RxParser.parse(lines: dermatologyLines)
        #expect(r.meds.map(\.nameOnRx) == ["Thuốc Da Liễu A 10mg", "Thuốc Da Liễu B 250mg", "Thuốc Da Liễu C 5mg", "Thuốc Da Liễu D 2mg"])
        #expect(r.meds.map(\.displayName) == ["Thuốc Da Liễu A", "Thuốc Da Liễu B", "Thuốc Da Liễu C", "Thuốc Da Liễu D"])
        #expect(r.title?.hasPrefix("Phòng khám") == true)
    }

    @Test func beforeMealWithoutMinutesUsesDefault() {
        let a = RxParser.parse(lines: dermatologyLines).meds[0]
        #expect(a.timings == [Timing(anchor: .breakfast, relation: .before, offsetMinutes: nil, offsetSource: .standard)])
        #expect(a.doseHalves == 2)
    }

    @Test func twiceADayMorningEveningAfterMeal() {
        let b = RxParser.parse(lines: dermatologyLines).meds[1]
        #expect(Set(b.timings.map(\.anchor)) == [.breakfast, .dinner])
        #expect(b.timings.allSatisfy { $0.relation == .after })
        #expect(b.doseHalves == 4)
    }

    @Test func afternoonAndBedtimeHalfTablet() {
        let meds = RxParser.parse(lines: dermatologyLines).meds
        #expect(meds[2].timings.map(\.anchor) == [.afternoon])
        #expect(meds[3].timings == [Timing(anchor: .bed, relation: .before, offsetMinutes: 60, offsetSource: .rx)])
        #expect(Dose.text(halves: meds[3].doseHalves, unit: meds[3].unit) == "Nửa viên")
    }

    @Test func explicitMinutesAndEveryOtherDay() {
        var d = DraftMed(nameOnRx: "X", displayName: "X")
        RxParser.apply(instructions: "Cách ngày, uống trước ăn sáng 15 phút", to: &d)
        #expect(d.everyNDays == 1)
        #expect(d.timings == [Timing(anchor: .breakfast, relation: .before, offsetMinutes: 15, offsetSource: .rx)])
    }

    @Test func doseTextCoversEveryUnit() {
        #expect(Dose.text(halves: 1, unit: .vien) == "Nửa viên")
        #expect(Dose.text(halves: 3, unit: .vien) == "1 viên rưỡi")
        #expect(Dose.text(halves: 4, unit: .goi) == "2 gói")
        #expect(Dose.text(halves: 5, unit: .ml) == "2,5 ml")
        #expect(Dose.text(halves: 10, unit: .ml) == "5 ml")
        #expect(Dose.text(halves: 4, unit: .giot) == "2 giọt")
        #expect(Dose.text(halves: 2, unit: .lanBoi) == "1 lần bôi")
        #expect(Dose.snapped(3, unit: .giot) == 2)
        #expect(Dose.snapped(1, unit: .ml) == 5)
    }

    @Test func unreadableTextGivesNoMedications() {
        #expect(RxParser.parse(lines: ["@@ ##", "mờ quá"]).meds.isEmpty)
    }

    @Test func joinsFragmentsOnTheSameLine() {
        let lines = RxParser.lines(from: [
            .init(text: "30 viên", midY: 0.30, minX: 0.8, height: 0.02),
            .init(text: "1. Kẽm 15mg", midY: 0.301, minX: 0.1, height: 0.02),
            .init(text: "Uống sau ăn sáng", midY: 0.33, minX: 0.12, height: 0.02),
        ])
        #expect(lines == ["1. Kẽm 15mg  30 viên", "Uống sau ăn sáng"])
    }
}
