import Foundation

func loc(_ key: String) -> String {
    var url = Bundle.main.bundleURL
    while url.pathExtension != "app", url.path != "/" {
        url = url.deletingLastPathComponent()
    }
    let bundle: Bundle = url.pathExtension == "app" ? (Bundle(url: url) ?? .main) : .main
    return bundle.localizedString(forKey: key, value: key, table: nil)
}
