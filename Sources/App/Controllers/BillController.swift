import Vapor
import Fluent

struct BillController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let bills = routes.grouped("api", "bills")
        
        // 账单相关路由
        bills.get(use: getAllBills)
        bills.group(":billID") { bill in
            bill.get(use: getBill)
            bill.put(use: updateBill)
            bill.delete(use: deleteBill)
        }
        
        // 用户账单路由
        bills.group("user", ":userID") { userBills in
            userBills.post(use: createBill)
            userBills.get(use: getUserBills)
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
    func createBill(req: Request) async throws -> BillDTO {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "无效的用户ID")
        }
        let billDTO = try req.content.decode(BillDTO.self)
        let bill = billDTO.toModel()
        bill.$user.id = userID
        try await bill.save(on: req.db)
        return bill.toDTO()
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
        
        let updateDTO = try req.content.decode(BillDTO.self)
        
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
} 