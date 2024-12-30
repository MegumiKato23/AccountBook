import Fluent

struct CreateBill: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("bills")
            .id()
            .field("transaction_id", .uuid, .required, .references("transactions", "id", onDelete: .cascade))
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("amount", .double, .required)
            .field("date", .date, .required)
            .field("description", .string)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("bills").delete()
    }
}