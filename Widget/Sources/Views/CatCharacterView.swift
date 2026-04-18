import SwiftUI

struct CatCharacterView: View {
    let expression: CatExpression

    var body: some View {
        Button(intent: CycleCatIntent()) {
            Image(expression.imageName)
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 52, height: 52)
        }
        .buttonStyle(.plain)
    }
}
