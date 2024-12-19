import Fluent
import Foundation

final class Budget: Model, @unchecked Sendable {
    static let schema = "budgets"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "budget_amount")
    var budget: Double

    @Field(key: "budget_description")
    var description: String

    @Enum(key: "budget_type")
    var type: BudgetType

    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updatedAt", on: .update)
    var updatedAt: Date?

    init() { }

    init(id: UUID? = nil, userID: User.IDValue, budget: Double, description: String, type: BudgetType) {
        self.id = id
        self.$user.id = userID
        self.budget = budget
        self.description = description
        self.type = type
    }

    func toDTO() -> BudgetDTO {
        .init(
            id: self.id,
            user: self.$user.value,
            budget: self.budget,
            description: self.description,
            type: self.type
        )
    }
}

enum BudgetType: String, Codable {
    case year = "年预算"
    case month = "月预算"
}