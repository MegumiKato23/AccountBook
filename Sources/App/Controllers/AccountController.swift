import Vapor
import Fluent

struct AccountController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let accounts = routes.grouped("api", "accounts")
        
        // 账户相关路由
        accounts.group(":userID") { account in
            account.post(use: createAccount)
            account.get(use: getAccount)
            account.get("balance", "month", use: calculateMonthlyBalance)
            account.get("balance", "year", use: calculateYearlyBalance)
            account.delete(use: deleteAccount)
        }
    }
    
    // 获取用户账户
    @Sendable
    func getAccount(req: Request) async throws -> AccountDTO {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "无效的用户ID")
        }
        
        guard let account = try await Account.query(on: req.db)
            .filter(\.$user.$id == userID)
            .first() else {
            throw Abort(.notFound, reason: "账户不存在")
        }
        
        // 更新账户余额
        account.balance = try await calculateBalance(for: userID, on: req.db)
        try await account.save(on: req.db)
        
        return account.toDTO()
    }
    
    // 计算指定月份的收支余额
    @Sendable
    func calculateMonthlyBalance(req: Request) async throws -> BalanceResponse {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "无效的用户ID")
        }
        
        // 从查询参数获取年月
        guard let yearString = req.query[String.self, at: "year"],
              let monthString = req.query[String.self, at: "month"],
              let year = Int(yearString),
              let month = Int(monthString) else {
            throw Abort(.badRequest, reason: "请提供有效的年月参数")
        }
        
        // 验证月份的有效性
        guard month >= 1 && month <= 12 else {
            throw Abort(.badRequest, reason: "月份必须在1-12之间")
        }
        
        // 获取指定月的起始和结束日期
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1
        
        guard let startOfMonth = calendar.date(from: dateComponents) else {
            throw Abort(.badRequest, reason: "无效的日期")
        }
        
        guard let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            throw Abort(.badRequest, reason: "无效的日期范围")
        }
        
        // 查询指定月份的所有账单
        let bills = try await Bill.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$date >= startOfMonth)
            .filter(\.$date <= endOfMonth)
            .with(\.$transaction)
            .all()
        
        // 计算总收入和总支出
        var totalIncome: Double = 0
        var totalExpense: Double = 0
        
        for bill in bills {
            if bill.transaction.type == .income {
                totalIncome += bill.amount
            } else {
                totalExpense += bill.amount
            }
        }
        
        // 计算余额
        let balance = totalIncome - totalExpense
        
        // 更新账户余额
        if let account = try await Account.query(on: req.db)
            .filter(\.$user.$id == userID)
            .first() {
            account.balance = balance
            try await account.save(on: req.db)
        }
        
        return BalanceResponse(
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            balance: balance,
            startDate: startOfMonth,
            endDate: endOfMonth,
            bills: bills.map { $0.toDTO() }
        )
    }

    // 计算指定年份的收支余额
    @Sendable
    func calculateYearlyBalance(req: Request) async throws -> BalanceResponse {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "无效的用户ID")
        }
        
        // 从查询参数获取年
        guard let yearString = req.query[String.self, at: "year"],
              let year = Int(yearString) else {
            throw Abort(.badRequest, reason: "请提供有效的年参数")
        }
        
        // 获取指定月的起始和结束日期
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = 1
        dateComponents.day = 1
        
        guard let startOfYear = calendar.date(from: dateComponents) else {
            throw Abort(.badRequest, reason: "无效的日期")
        }
        
        guard let endOfYear = calendar.date(byAdding: DateComponents(year:1, day: -1), to: startOfYear) else {
            throw Abort(.badRequest, reason: "无效的日期范围")
        }
        
        // 查询指定月份的所有账单
        let bills = try await Bill.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$date >= startOfYear)
            .filter(\.$date <= endOfYear)
            .with(\.$transaction)
            .all()
        
        // 计算总收入和总支出
        var totalIncome: Double = 0
        var totalExpense: Double = 0
        
        for bill in bills {
            if bill.transaction.type == .income {
                totalIncome += bill.amount
            } else {
                totalExpense += bill.amount
            }
        }
        
        // 计算余额
        let balance = totalIncome - totalExpense
        
        // 更新账户余额
        if let account = try await Account.query(on: req.db)
            .filter(\.$user.$id == userID)
            .first() {
            account.balance = balance
            try await account.save(on: req.db)
        }
        
        return BalanceResponse(
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            balance: balance,
            startDate: startOfYear,
            endDate: endOfYear,
            bills: bills.map { $0.toDTO() }
        )
    }
    
    // 创建账户
    @Sendable
    func createAccount(req: Request) async throws -> HTTPStatus {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "无效的用户ID")
        }
        
        // 检查用户是否已有账户
        if let _ = try await Account.query(on: req.db)
            .filter(\.$user.$id == userID)
            .first() {
            throw Abort(.conflict, reason: "用户已有账户")
        }

        let balance = try await calculateBalance(for: userID, on: req.db)
        let account = Account(userID: userID, balance: balance)
        
        try await account.create(on: req.db)
        return .created
    }
    
    
    // 删除账户
    @Sendable
    func deleteAccount(req: Request) async throws -> HTTPStatus {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "无效的用户ID")
        }
        
        guard let account = try await Account.query(on: req.db)
            .filter(\.$user.$id == userID)
            .first() else {
            throw Abort(.notFound, reason: "账户不存在")
        }
        
        try await account.delete(on: req.db)
        return .noContent
    }
    
    // 辅助方法：计算账户余额
    private func calculateBalance(for userID: UUID, on database: Database) async throws -> Double {
        let bills = try await Bill.query(on: database)
            .filter(\.$user.$id == userID)
            .with(\.$transaction)
            .all()
        
        var balance: Double = 0
        
        for bill in bills {
            if bill.transaction.type == .income {
                balance += bill.amount
            } else {
                balance -= bill.amount
            }
        }
        
        return balance
    }
}

// 余额响应模型
struct BalanceResponse: Content {
    let totalIncome: Double
    let totalExpense: Double
    let balance: Double
    let startDate: Date
    let endDate: Date
    let bills: [BillDTO]
}
