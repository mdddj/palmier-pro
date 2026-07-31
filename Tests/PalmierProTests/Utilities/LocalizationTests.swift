import Testing
@testable import PalmierPro

@Suite("Localization")
struct LocalizationTests {
    @Test func chineseResourcesResolveStaticAndFormattedKeys() {
        #expect(loc("Send feedback", localeIdentifier: "zh-Hans") == "发送反馈")
        #expect(
            loc(
                format: "%@ does not support this media type.",
                localeIdentifier: "zh-Hans",
                "Model"
            ) == "Model 不支持此媒体类型。"
        )
    }
}
