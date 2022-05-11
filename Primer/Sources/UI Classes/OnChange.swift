import SwiftUI

extension View {
    
    public func onChange<T: Equatable>(value: T, perform action: @escaping (T,T) -> Void) -> some View {
        ChangeObserverView(value: value, content: self, action: action)
    }
    
}

fileprivate struct ChangeObserverView<T: Equatable, Content: View>: View {
    
    var value: T
    var content: Content
    var action: (T,T) -> Void
    
    @State private var lastKnownValue: T
    
    init(value: T, content: Content, action: @escaping (T,T) -> Void) {
        self.value = value
        self.content = content
        self.action = action
        self._lastKnownValue = State(initialValue: value)
    }
    
    var body: some View {
        content
            .preference(key: ChangePreferenceKey<T>.self, value: value)
            .onPreferenceChange(ChangePreferenceKey<T>.self) { newValue in
                self.valueDidChange(to: newValue!)
            }
    }
    
    private func valueDidChange(to newValue: T) {
        guard newValue != lastKnownValue else {
            return
        }
        let oldValue = lastKnownValue
        lastKnownValue = newValue
        action(oldValue, newValue)
    }
    
}

fileprivate struct ChangePreferenceKey<T>: PreferenceKey {
    
    static var defaultValue: T? {
        nil
    }
    
    static func reduce(value: inout T?, nextValue: () -> T?) {
        value = value ?? nextValue()
    }
    
}
