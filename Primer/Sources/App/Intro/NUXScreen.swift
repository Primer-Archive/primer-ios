import SwiftUI
import PrimerEngine

struct NUXScreen: Identifiable {
    private let _id: String
    private let _page: NUXPage
    private let _makeView: (@escaping (AppState.VisibleSheet?) -> Void) -> AnyView
    
    init<T: NUXScreenView>(page: NUXPage, viewType: T.Type, sheet: AppState.VisibleSheet? = nil) {
        _id = page.rawValue
        _page = page
        _makeView = { AnyView(T(page: page, onContinue: $0)) }
    }
    
    var id: String {
        _id
    }
    
    func makeView(onContinue: @escaping (AppState.VisibleSheet?) -> Void) -> AnyView {
        _makeView(onContinue)
    }
}





