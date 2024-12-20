import Fluent

struct CreateAccount: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("accounts")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("balance", .double, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("accounts").delete()
    }
}