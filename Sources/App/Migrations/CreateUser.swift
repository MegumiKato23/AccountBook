import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("name", .string, .required)
            .field("password", .string, .required)
            .field("phoneNumber", .string, .required)
            .field("avatarURL", .string)
            .field("createdAt", .date, .required)
            .field("updatedAt", .date, .required)
            .unique(on: "phoneNumber")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
