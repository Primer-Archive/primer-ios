import SwiftUI
import PrimerEngine

struct NUXIntroScreenView: NUXScreenView {
    @Environment(\.analytics) var analytics
    var page: NUXPage
    var onContinue: (AppState.VisibleSheet?) -> Void

    var body: some View {
        NUXScreenContentView(page: page, onContinue: { sheet in
            analytics?.didAcknowldegeNUXTutorial()
            onContinue(sheet)
        })
        .analytics(analytics)
    }
    
    init(page: NUXPage, onContinue: @escaping (AppState.VisibleSheet?) -> Void) {
        self.page = page
        self.onContinue = onContinue
        return
    }
}
