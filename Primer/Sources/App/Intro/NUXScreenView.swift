import SwiftUI
import PrimerEngine

protocol NUXScreenView: View {
    init(page: NUXPage, onContinue: @escaping (AppState.VisibleSheet?) -> Void)
}
