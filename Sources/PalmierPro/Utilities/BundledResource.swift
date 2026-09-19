import Foundation

private final class BundledResourceToken {}

enum BundledResource {
    static let bundle: Bundle = {
        guard Bundle.main.bundleURL.pathExtension != "app" else { return .main }
        let buildDirectory = Bundle(for: BundledResourceToken.self).bundleURL.deletingLastPathComponent()
        let resourceBundleURL = buildDirectory.appendingPathComponent("PalmierPro_PalmierPro.bundle")
        return Bundle(url: resourceBundleURL) ?? .main
    }()

    static func url(_ path: String) -> URL? {
        [bundle.resourceURL, Bundle.main.resourceURL]
            .compactMap { $0?.appendingPathComponent(path) }
            .first { FileManager.default.fileExists(atPath: $0.path) }
    }
}
