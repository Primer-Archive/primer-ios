import SwiftUI


struct BackgroundView: View {
    
    var color: UIColor?
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        if let color = color {
            return SwiftUI.Color(color)
        }
        
        switch colorScheme {
        case .light:
            return BrandColors.sand.color
        case .dark:
            return BrandColors.darkBlue.color
        @unknown default:
            return BrandColors.sand.color
        }
    }
}

struct BackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundView()
    }
}
