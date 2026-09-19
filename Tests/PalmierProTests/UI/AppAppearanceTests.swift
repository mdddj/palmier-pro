import AppKit
import Foundation
import Testing
@testable import PalmierPro

@Suite("App appearance")
@MainActor
struct AppAppearanceTests {
    @Test func missingOrInvalidPreferenceUsesDarkAppearance() throws {
        let suiteName = "AppAppearanceTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        #expect(AppAppearance.stored(in: defaults) == .dark)

        defaults.set("sepia", forKey: AppAppearance.defaultsKey)
        #expect(AppAppearance.stored(in: defaults) == .dark)
    }

    @Test(arguments: AppAppearance.allCases)
    func storedPreferenceRoundTrips(_ appearance: AppAppearance) throws {
        let suiteName = "AppAppearanceTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(appearance.rawValue, forKey: AppAppearance.defaultsKey)
        #expect(AppAppearance.stored(in: defaults) == appearance)
    }

    @Test func semanticPaletteInvertsBetweenAppearances() throws {
        let light = try #require(NSAppearance(named: .aqua))
        let dark = try #require(NSAppearance(named: .darkAqua))

        #expect(brightness(AppTheme.Background.surface, in: light) > brightness(AppTheme.Background.surface, in: dark))
        #expect(brightness(AppTheme.Text.primary, in: light) < brightness(AppTheme.Text.primary, in: dark))
    }

    @Test func chromePaletteUsesSystemSemanticColors() throws {
        let light = try #require(NSAppearance(named: .aqua))
        let dark = try #require(NSAppearance(named: .darkAqua))

        let tokens: [(NSColor, NSColor)] = [
            (AppTheme.Background.base, .windowBackgroundColor),
            (AppTheme.Background.surface, .controlBackgroundColor),
            (AppTheme.Background.raised, .underPageBackgroundColor),
            (AppTheme.Background.prominent, .textBackgroundColor),
            (AppTheme.Border.primary, .separatorColor),
            (AppTheme.Border.subtle, .gridColor),
            (AppTheme.Border.divider, .separatorColor),
            (AppTheme.Border.panel, .separatorColor),
            (AppTheme.Text.primary, .labelColor),
            (AppTheme.Text.secondary, .secondaryLabelColor),
            (AppTheme.Text.tertiary, .tertiaryLabelColor),
            (AppTheme.Text.muted, .quaternaryLabelColor),
            (AppTheme.Accent.primaryNSColor, .controlAccentColor),
            (AppTheme.Accent.timecodeNSColor, .controlAccentColor),
            (AppTheme.Accent.playheadNSColor, .systemRed),
            (AppTheme.Status.error, .systemRed),
            (AppTheme.Status.success, .systemGreen),
            (AppTheme.AgentActivity.added, .systemGreen),
            (AppTheme.AgentActivity.mutated, .systemOrange),
            (AppTheme.AgentActivity.read, .secondaryLabelColor),
        ]

        for (token, expected) in tokens {
            for appearance in [light, dark] {
                expectSameColor(resolved(token, in: appearance), resolved(expected, in: appearance))
            }
        }
    }

    @Test func mediaOverlayPaletteIsAppearanceInvariant() throws {
        let light = try #require(NSAppearance(named: .aqua))
        let dark = try #require(NSAppearance(named: .darkAqua))
        let colors = [
            AppTheme.MediaOverlay.background,
            AppTheme.MediaOverlay.primary,
            AppTheme.MediaOverlay.secondary,
            AppTheme.MediaOverlay.tertiary,
            AppTheme.MediaOverlay.muted,
            AppTheme.MediaOverlay.error,
        ]

        for color in colors {
            expectSameColor(resolved(color, in: light), resolved(color, in: dark))
        }
    }

    @Test func clipSelectionBorderInvertsBetweenAppearances() throws {
        let light = try #require(NSAppearance(named: .aqua))
        let dark = try #require(NSAppearance(named: .darkAqua))

        expectSameColor(resolved(AppTheme.Border.timelineClip, in: light), resolved(.white, in: light))
        expectSameColor(resolved(AppTheme.Border.timelineClipSelected, in: light), resolved(.black, in: light))
        expectSameColor(resolved(AppTheme.Border.timelineClip, in: dark), resolved(.black, in: dark))
        expectSameColor(resolved(AppTheme.Border.timelineClipSelected, in: dark), resolved(.white, in: dark))
    }

    @Test func labelTextRemainsLegibleOnSystemSurfaces() throws {
        let light = try #require(NSAppearance(named: .aqua))
        let dark = try #require(NSAppearance(named: .darkAqua))

        #expect(contrastRatio(AppTheme.Text.primary, over: AppTheme.Background.surface, in: light) >= 4.5)
        #expect(contrastRatio(AppTheme.Text.primary, over: AppTheme.Background.surface, in: dark) >= 4.5)
        #expect(contrastRatio(AppTheme.Text.secondary, over: AppTheme.Background.surface, in: light) >= 3.5)
        #expect(contrastRatio(AppTheme.Text.secondary, over: AppTheme.Background.surface, in: dark) >= 3.5)
    }

    private func brightness(_ color: NSColor, in appearance: NSAppearance) -> CGFloat {
        let resolved = resolved(color, in: appearance)
        return resolved.redComponent * 0.2126
            + resolved.greenComponent * 0.7152
            + resolved.blueComponent * 0.0722
    }

    private func resolved(_ color: NSColor, in appearance: NSAppearance) -> NSColor {
        var resolved = color
        appearance.performAsCurrentDrawingAppearance {
            resolved = color.usingColorSpace(.sRGB) ?? color
        }
        return resolved
    }

    private func expectSameColor(
        _ lhs: NSColor,
        _ rhs: NSColor,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(abs(lhs.redComponent - rhs.redComponent) < 0.001, sourceLocation: sourceLocation)
        #expect(abs(lhs.greenComponent - rhs.greenComponent) < 0.001, sourceLocation: sourceLocation)
        #expect(abs(lhs.blueComponent - rhs.blueComponent) < 0.001, sourceLocation: sourceLocation)
        #expect(abs(lhs.alphaComponent - rhs.alphaComponent) < 0.001, sourceLocation: sourceLocation)
    }

    private func contrastRatio(_ foreground: NSColor, over background: NSColor, in appearance: NSAppearance) -> CGFloat {
        let foreground = resolved(foreground, in: appearance)
        let background = resolved(background, in: appearance)
        let alpha = foreground.alphaComponent
        let blended = [
            foreground.redComponent * alpha + background.redComponent * (1 - alpha),
            foreground.greenComponent * alpha + background.greenComponent * (1 - alpha),
            foreground.blueComponent * alpha + background.blueComponent * (1 - alpha),
        ]
        let foregroundLuminance = relativeLuminance(blended)
        let backgroundLuminance = relativeLuminance([
            background.redComponent,
            background.greenComponent,
            background.blueComponent,
        ])
        let lighter = max(foregroundLuminance, backgroundLuminance)
        let darker = min(foregroundLuminance, backgroundLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private func relativeLuminance(_ components: [CGFloat]) -> CGFloat {
        let linear = components.map { component in
            component <= 0.04045
                ? component / 12.92
                : pow((component + 0.055) / 1.055, 2.4)
        }
        return linear[0] * 0.2126 + linear[1] * 0.7152 + linear[2] * 0.0722
    }
}
