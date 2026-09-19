import Testing

@testable import PalmierPro

@Test func resolvesBundledKernelLibrary() {
    #expect(BundledResource.url("Vignette.metallib") != nil)
}

@Test func loadsMetalKernelFromBundledLibrary() {
    #expect(CIKernelLoader.kernel("Vignette", "vignette") != nil)
}

@Test func resolvesBundledImageDirectory() {
    #expect(BundledResource.url("Images/LabLogos") != nil)
}

@Test func missingResourceResolvesToNil() {
    #expect(BundledResource.url("NotABundledResource.txt") == nil)
}
