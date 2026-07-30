import Foundation

/// How a visual clip composites over the layers below it. `normal` = source-over.
enum BlendMode: String, Codable, Sendable, CaseIterable {
    case normal, darken, multiply, colorBurn, lighten, screen, colorDodge
    case overlay, softLight, hardLight, difference, exclusion
    case hue, saturation, color, luminosity

    var displayName: String {
        switch self {
        case .normal: loc("Normal")
        case .darken: loc("Darken")
        case .multiply: loc("Multiply")
        case .colorBurn: loc("Color Burn")
        case .lighten: loc("Lighten")
        case .screen: loc("Screen")
        case .colorDodge: loc("Color Dodge")
        case .overlay: loc("Overlay")
        case .softLight: loc("Soft Light")
        case .hardLight: loc("Hard Light")
        case .difference: loc("Difference")
        case .exclusion: loc("Exclusion")
        case .hue: loc("Hue")
        case .saturation: loc("Saturation")
        case .color: loc("Color")
        case .luminosity: loc("Luminosity")
        }
    }

    /// Core Image blend-filter name; nil for `normal` (plain source-over compositing).
    var ciFilterName: String? {
        switch self {
        case .normal: nil
        case .darken: "CIDarkenBlendMode"
        case .multiply: "CIMultiplyBlendMode"
        case .colorBurn: "CIColorBurnBlendMode"
        case .lighten: "CILightenBlendMode"
        case .screen: "CIScreenBlendMode"
        case .colorDodge: "CIColorDodgeBlendMode"
        case .overlay: "CIOverlayBlendMode"
        case .softLight: "CISoftLightBlendMode"
        case .hardLight: "CIHardLightBlendMode"
        case .difference: "CIDifferenceBlendMode"
        case .exclusion: "CIExclusionBlendMode"
        case .hue: "CIHueBlendMode"
        case .saturation: "CISaturationBlendMode"
        case .color: "CIColorBlendMode"
        case .luminosity: "CILuminosityBlendMode"
        }
    }
}
