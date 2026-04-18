import AppIntents
import WidgetKit

struct CycleCatIntent: AppIntent {
    static var title: LocalizedStringResource = "Cycle Cat Expression"
    static var description: IntentDescription = "Changes the cat's expression."

    func perform() async throws -> some IntentResult {
        let storage = AppGroupStorage.shared
        let current = CatExpression.fromIndex(storage.catExpressionIndex)
        storage.catExpressionIndex = current.nextIndex
        WidgetCenter.shared.reloadTimelines(ofKind: "SystemStatsWidget")
        return .result()
    }
}
