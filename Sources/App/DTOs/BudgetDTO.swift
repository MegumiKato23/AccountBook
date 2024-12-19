import Vapor
import Fluent

struct BudgetDTO: Content {
    var id: UUID?
    var user: User?
    var budget: Double?
    var description: String?
    var type: BudgetType?

    func toModel() -> Budget {
        let model = Budget()
        model.id = self.id
        if let user = self.user {
            model.$user.id = user.id!
        }
        if let budget = self.budget {
            model.budget = budget
        }
        if let description = self.description {
            model.description = description
        }
        if let type = self.type {
            model.type = type
        }
        return model
    }
}