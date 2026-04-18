import Foundation

enum CatExpression: Int, CaseIterable {
    case frame0 = 0
    case frame1
    case frame2

    static func fromIndex(_ index: Int) -> CatExpression {
        let count = CatExpression.allCases.count
        return CatExpression(rawValue: index % count) ?? .frame0
    }

    var nextIndex: Int {
        (rawValue + 1) % CatExpression.allCases.count
    }

    var imageName: String {
        "cat_frame_\(rawValue)"
    }
}
