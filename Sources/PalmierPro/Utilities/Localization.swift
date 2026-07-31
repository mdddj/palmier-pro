import Foundation

func loc(_ key: String) -> String {
    localizedString(for: key, in: localizationBundle())
}

func loc(_ key: String, localeIdentifier: String) -> String {
    guard let localeBundle = localizationBundle(for: localeIdentifier) else {
        return loc(key)
    }
    return localizedString(for: key, in: localeBundle)
}

func loc(format key: String, _ arguments: CVarArg...) -> String {
    localizedFormat(for: key, arguments: arguments, in: localizationBundle())
}

func loc(format key: String, localeIdentifier: String, _ arguments: CVarArg...) -> String {
    guard let localeBundle = localizationBundle(for: localeIdentifier) else {
        return localizedFormat(for: key, arguments: arguments, in: localizationBundle())
    }
    return localizedFormat(for: key, arguments: arguments, in: localeBundle)
}

private func localizedString(for key: String, in bundle: Bundle) -> String {
    bundle.localizedString(forKey: key, value: key, table: nil)
}

private func localizedFormat(for key: String, arguments: [CVarArg], in bundle: Bundle) -> String {
    String(format: localizedString(for: key, in: bundle), locale: .current, arguments: arguments)
}

private func localizationBundle() -> Bundle {
    if let appBundle = applicationBundle() {
        return appBundle
    }
    for identifier in Locale.preferredLanguages {
        if let bundle = localizationBundle(for: identifier) {
            return bundle
        }
    }
    return .module
}

private func localizationBundle(for identifier: String) -> Bundle? {
    if let appBundle = applicationBundle(),
       let url = appBundle.url(forResource: identifier, withExtension: "lproj"),
       let bundle = Bundle(url: url) {
        return bundle
    }
    guard let resources = Bundle.module.resourceURL?.appending(path: "Localization") else {
        return nil
    }
    for candidate in localeCandidates(for: identifier) {
        let url = resources.appending(path: "\(candidate).lproj")
        if let bundle = Bundle(url: url) {
            return bundle
        }
    }
    return nil
}

private func applicationBundle() -> Bundle? {
    var url = Bundle.main.bundleURL
    while url.pathExtension != "app", url.path != "/" {
        url = url.deletingLastPathComponent()
    }
    return url.pathExtension == "app" ? Bundle(url: url) : nil
}

private func localeCandidates(for identifier: String) -> [String] {
    let normalized = identifier.replacingOccurrences(of: "_", with: "-")
    let parts = normalized.split(separator: "-").map(String.init)
    var candidates = [normalized]
    if parts.count >= 2 { candidates.append(parts.prefix(2).joined(separator: "-")) }
    if let language = parts.first { candidates.append(language) }
    var seen = Set<String>()
    return candidates.filter { seen.insert($0).inserted }
}
