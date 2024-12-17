import Vapor
import Fluent

struct TransactionController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let transactions = routes.grouped("api", "transactions")
        
        // 获取所有类别
        transactions.get(use: getAllTransactions)
        // 获取支出类别
        transactions.get("expenses", use: getExpenseCategories)
        // 获取收入类别
        transactions.get("incomes", use: getIncomeCategories)
        // 获取交易类型id
        transactions.get("types", use: getTransactionCategoryID)
    }
    
    // 获取所有交易类别
    @Sendable
    func getAllTransactions(req: Request) async throws -> [TransactionDTO] {
        let transactions = try await Transaction.query(on: req.db).all()
        return transactions.map { $0.toDTO() }
    }
    
    // 获取支出类别
    @Sendable
    func getExpenseCategories(req: Request) async throws -> [String] {
        return TransactionCategory.expenseCategories.map { $0.rawValue }
    }
    
    // 获取收入类别
    @Sendable
    func getIncomeCategories(req: Request) async throws -> [String] {
        return TransactionCategory.incomeCategories.map { $0.rawValue }
    }

    // 获取交易类型id
    @Sendable
    func getTransactionCategoryID(req: Request) async throws -> TransactionDTO {
        // 从请求参数中获取类型
        guard let categoryString = req.query[String.self, at: "category"],
              let category = TransactionCategory(rawValue: categoryString) else {
            throw Abort(.badRequest, reason: "无效的交易类型参数")
        }
        
        // 查询数据库
        guard let transaction = try await Transaction.query(on: req.db)
            .filter(\.$category == category)
            .first() else {
            throw Abort(.notFound, reason: "未找到该类型的交易记录")
        }

        return transaction.toDTO()
    }
} 