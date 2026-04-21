import SwiftUI

extension Font {
    public static let sarcasmMega = Font.system(size: 28, weight: .bold, design: .monospaced)
    public static let sarcasmTitle = Font.system(size: 22, weight: .bold, design: .monospaced)
    public static let sarcasmHeadline = Font.system(size: 17, weight: .semibold, design: .monospaced)
    public static let sarcasmBody = Font.system(size: 15, weight: .regular, design: .monospaced)
    public static let sarcasmLabel = Font.system(size: 12, weight: .semibold, design: .monospaced)
    public static let sarcasmMono = Font.system(size: 16, weight: .regular, design: .monospaced)
    public static let sarcasmMonoSmall = Font.system(size: 13, weight: .regular, design: .monospaced)
}

extension Text {
    public func sarcasmTight() -> Text {
        self.tracking(0)
    }

    public func sarcasmLoose() -> Text {
        self.tracking(2)
    }
}
