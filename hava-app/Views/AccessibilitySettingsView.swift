import SwiftUI

struct AccessibilitySettingsView: View {
    @EnvironmentObject private var store: AppStore
    
    var body: some View {
        Form {
            Section(header: Text("Display")) {
                Toggle("High Contrast Mode", isOn: $store.highContrastMode)
                    .onChange(of: store.highContrastMode) { _ in
                    }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Font Size")
                        .font(.headline)
                        .fontSize(store.dynamicTypeSize)
                    
                    Slider(value: $store.dynamicTypeSize, in: 0.8...1.5, step: 0.1)
                        .onChange(of: store.dynamicTypeSize) { _ in
                        }
                    
                    HStack {
                        Text("Smaller")
                            .font(.caption)
                            .fontSize(store.dynamicTypeSize)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Larger")
                            .font(.caption)
                            .fontSize(store.dynamicTypeSize)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Current: \(Int(store.dynamicTypeSize * 100))%")
                        .font(.caption)
                        .fontSize(store.dynamicTypeSize)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("About")) {
                Text("These settings help make the app more accessible for everyone.")
                    .font(.caption)
                    .fontSize(store.dynamicTypeSize)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
        .fontSize(store.dynamicTypeSize)
    }
}

extension View {
    func fontSize(_ multiplier: Double) -> some View {
        self.modifier(DynamicFontSizeModifier(multiplier: multiplier))
    }
}

struct DynamicFontSizeModifier: ViewModifier {
    @EnvironmentObject var store: AppStore
    let multiplier: Double
    
    func body(content: Content) -> some View {
        let effectiveMultiplier = store.dynamicTypeSize
        let baseSize: CGFloat = 17
        let scaledSize = baseSize * effectiveMultiplier * multiplier
        
        return content
            .font(.system(size: scaledSize))
    }
}

