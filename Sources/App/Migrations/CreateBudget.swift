import Fluent

struct CreateBudget: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("budgets")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("budget_amount", .double, .required)
            .field("budget_description", .string)
            .field("budget_type", .string, .required)
            .field("createdAt", .date)
            .field("updatedAt", .date)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("budgets").delete()
    }
}