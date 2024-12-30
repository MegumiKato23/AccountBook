import Fluent
import Vapor

struct BillController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let bills = routes.grouped("api", "bills")

        // 账单相关路由
        bills.get(use: getAllBills)
        bills.group(":billID") { bill in
            bill.get(use: getBill)
            bill.put(":transactionID", use: updateBill)
            bill.delete(use: deleteBill)
        }

        // 用户账单路由
        bills.group("user", ":userID") { userBills in
            userBills.get(use: getUserBills)
            userBills.get("income", use: getUserIncomeBills)
            userBills.get("expence", use: getUserExpenseBills)
            userBills.get("month", use: getUserMonthlyBills)
            userBills.get("year", use: getUserYearlyBills)
            userBills.get("search", use: searchUserBills)
        }

        // 用户交易账单路由
        bills.group("user", ":userID", "transaction", ":transactionID") { userTransactionBills in
            userTransactionBills.post(use: createBill)
            userTransactionBills.get(use: getUserTransactionBills)
        }
    }

    // 获取所有账单
    @Sendable
    func getAllBills(req: Request) async throws -> [BillDTO] {
        let bills = try await Bill.query(on: req.db)
            .with(\.$transaction)
            .with(\.$user)
            .all()
        return bills.map { $0.toDTO() }
    }

    // 创建新账单
    @Sendable
    func createBill(req: Request) async throws -> HTTPStatus {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "无效的用户ID")
        }

        guard let transactionID = req.parameters.get("transactionID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "无效的类型ID")
        }

        let billDTO = try req.content.decode(BillDTO.self)
        let bill = billDTO.toModel()
        bill.$user.id = userID
        bill.$transaction.id = transactionID
        try await bill.save(on: req.db)
        return .created
    }

    // 获取单个账单
    @Sendable
    func getBill(req: Request) async throws -> BillDTO {
        guard let bill = try await Bill.find(req.parameters.get("billID"), on: req.db) else {
            throw Abort(.notFound, reason: "账单不存在")
        }
        return bill.toDTO()
    }

    // 更新账单
    @Sendable
    func updateBill(req: Request) async throws -> BillDTO {
        guard let bill = try await Bill.find(req.parameters.get("billID"), on: req.db) else {
            throw Abort(.notFound, reason: "账单不存在")
        }

        guard let transactionID = req.parameters.get("transactionID", as: UUID.self) else {
            throw Abort(.notFound, reason: "类型不存在")
        }
        let updateDTO = try req.content.decode(BillDTO.self)

        bill.$transaction.id = transactionID
        if let amount = updateDTO.amount {
            bill.amount = amount
        }
        if let date = updateDTO.date {
            bill.date = date
        }
        if let description = updateDTO.description {
            bill.description = description
        }

        try await bill.save(on: req.db)
        return bill.toDTO()
    }

    // 删除账单
    @Sendable
    func deleteBill(req: Request) async throws -> HTTPStatus {
        guard let bill = try await Bill.find(req.parameters.get("billID"), on: req.db) else {
            throw Abort(.notFound, reason: "账单不存在")
        }
        try await bill.delete(on: req.db)
        return .noContent
    }

    // 获取用户的所有账单
    @Sendable
    func getUserBills(req: Request) async throws -> [BillDTO] {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "无效的用户ID")
        }

        let bills = try await Bill.query(on: req.db)
            .with(\.$transaction)
            .with(\.$user)
            .filter(\.$user.$id == userID)
            .all()

        return bills.map { $0.toDTO() }
    }

    // 获取用户的交易账单
    @Sendable
    func getUserTransactionBills(req: Request) async throws -> [BillDTO] {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "无效的用户ID")
        }

        guard let transactionID = req.parameters.get("transactionID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "无效的交易ID")
        }

        let bills = try await Bill.query(on: req.db)
            .with(\.$transaction)
            .with(\.$user)
            .filter(\.$user.$id == userID)
            .filter(\.$transaction.$id == transactionID)
            .all()
        return bills.map { $0.toDTO() }
    }

    // 获取用户的收入账单
    @Sendable
    func getUserIncomeBills(req: Request) async throws -> [BillDTO] {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "无效的用户ID")
        }
        let bills = try await Bill.query(on: req.db)
            .with(\.$transaction)
            .join(Transaction.self, on: \Bill.$transaction.$id == \Transaction.$id)
            .filter(\Bill.$user.$id == userID)
            .filter(Transaction.self, \.$type == .income)
            .all()
        return bills.map { $0.toDTO() }
    }

    // 获取用户的支出账单
    @Sendable
    func getUserExpenseBills(req: Request) async throws -> [BillDTO] {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "无效的用户ID")
        }

        let bills = try await Bill.query(on: req.db)
            .with(\.$transaction)
            .join(Transaction.self, on: \Bill.$transaction.$id == \Transaction.$id)
            .filter(\.$user.$id == userID)
            .filter(Transaction.self, \.$type == .expense)
            .all()
        return bills.map { $0.toDTO() }
    }

    // 计算指定月份的账单
    @Sendable
    func getUserMonthlyBills(req: Request) async throws -> [BillDTO] {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "无效的用户ID")
        }

        // 从查询参数获取年月
        guard let yearString = req.query[String.self, at: "year"],
            let monthString = req.query[String.self, at: "month"],
            let year = Int(yearString),
            let month = Int(monthString)
        else {
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

        guard
            let endOfMonth = calendar.date(
                byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)
        else {
            throw Abort(.badRequest, reason: "无效的日期范围")
        }

        // 查询指定月份的所有账单
        let bills = try await Bill.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$date >= startOfMonth)
            .filter(\.$date <= endOfMonth)
            .with(\.$transaction)
            .all()

        return bills.map { $0.toDTO() }
    }

    // 计算指定年份的账单
    @Sendable
    func getUserYearlyBills(req: Request) async throws -> [BillDTO] {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "无效的用户ID")
        }

        // 从查询参数获取年份
        guard let yearString = req.query[String.self, at: "year"],
            let year = Int(yearString)
        else {
            throw Abort(.badRequest, reason: "请提供有效的年参数")
        }

        // 获取指定年份的起始和结束日期
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = 1
        dateComponents.day = 1

        guard let startOfYear = calendar.date(from: dateComponents) else {
            throw Abort(.badRequest, reason: "无效的日期")
        }

        guard
            let endOfYear = calendar.date(
                byAdding: DateComponents(year: 1, day: -1), to: startOfYear)
        else {
            throw Abort(.badRequest, reason: "无效的日期范围")
        }

        // 查询指定年份的所有账单
        let bills = try await Bill.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$date >= startOfYear)
            .filter(\.$date <= endOfYear)
            .with(\.$transaction)
            .all()

        return bills.map { $0.toDTO() }
    }

    @Sendable
    func searchUserBills(req: Request) async throws -> [BillDTO] {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "无效的用户ID")
        }

        // 从查询参数获取日期
        guard let startDateString = req.query[String.self, at: "startDate"],
            let endDateString = req.query[String.self, at: "endDate"] else {
            throw Abort(.badRequest, reason: "缺少必要的查询参数")
        }

        // 创建日期格式化器
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // 解析日期
        guard let startDate = dateFormatter.date(from: startDateString),
            let endDate = dateFormatter.date(from: endDateString)
        else {
            throw Abort(.badRequest, reason: "日期格式无效")
        }

        let bills = try await Bill.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$date >= startDate)
            .filter(\.$date <= endDate)
            .with(\.$transaction)
            .all()

        return bills.map { $0.toDTO() }
    }
}
