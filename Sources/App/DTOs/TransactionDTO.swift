import Vapor
import Fluent

struct TransactionDTO: Content {
    var id: UUID?
    var category: TransactionCategory?
    var type: TransactionType?

    func toModel() -> Transaction {
        let model = Transaction()
        model.id = self.id

        if let category = self.category {
            model.category = category
        }

        if let type = self.type {
            model.type = type
        }
        return model
    }
}   