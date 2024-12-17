import Vapor
import Fluent

struct BillDTO: Content {
    var id: UUID?
    var transaction: Transaction?
    var user: User?
    var amount: Double?
    var date: Date?
    var description: String?

    func toModel() -> Bill {
        let model = Bill()
        model.id = self.id
        if let transaction = self.transaction {
            model.transaction = transaction
        }
        if let user = self.user {
            model.user = user
        }
        if let amount = self.amount {
            model.amount = amount
        }
        if let date = self.date {
            model.date = date
        }
        if let description = self.description {
            model.description = description
        }
        return model
    }
}