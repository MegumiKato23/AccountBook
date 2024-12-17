import Fluent

struct CreateTransaction: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("transactions")
            .id()
            .field("category", .string, .required)
            .field("type", .string, .required)
            .create()
        
        // 初始化预设类别数据
        // 支出类别
        for category in TransactionCategory.expenseCategories {
            try await Transaction(
                category: category,
                type: .expense
            ).create(on: database)
        }
        
        // 收入类别
        for category in TransactionCategory.incomeCategories {
            try await Transaction(
                category: category,
                type: .income
            ).create(on: database)
        }
    }

    func revert(on database: Database) async throws {
        try await database.schema("transactions").delete()
    }
}