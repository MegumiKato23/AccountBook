import Vapor
import Fluent

struct BudgetController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let budgets = routes.grouped("api", "budgets")

        budgets.group(":userID") { budget in 
            budget.get(use: getBudget)
            budget.put(use: updateBudget)
            budget.post(use: createBudget)
            budget.delete(use: deleteBudget)
        }
    }

    // 获取用户预算
    @Sendable
    func getBudget(req: Request) async throws -> BudgetDTO {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "无效的用户ID")
        }

        guard let typeString = req.query[String.self, at: "type"],
            let type = BudgetType(rawValue: typeString) else {
                throw Abort(.badRequest, reason: "无效的预算类型参数")
            }

        guard let budget = try await Budget.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$type == type)
            .first() else {
            throw Abort(.notFound, reason: "未找到预算记录")
        }

        return budget.toDTO()
    }

    // 更新用户预算
    @Sendable
    func updateBudget(req: Request) async throws -> BudgetDTO {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "无效的用户ID")
        }

        guard let typeString = req.query[String.self, at: "type"],
            let type = BudgetType(rawValue: typeString) else {
                throw Abort(.badRequest, reason: "无效的预算类型参数")
            }

        guard let budget = try await Budget.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$type == type)
            .first() else {
            throw Abort(.notFound, reason: "未找到预算记录")
        }

        let budgetDTO = try req.content.decode(BudgetDTO.self)

        if let budget_amount = budgetDTO.budget {
            budget.budget = budget_amount
        }
        if let description = budgetDTO.description {
            budget.description = description
        }
        
        try await budget.save(on: req.db)
        return budget.toDTO()
    }

    // 创建用户预算
    @Sendable
    func createBudget(req: Request) async throws -> HTTPStatus {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "无效的用户ID")
        } 

        let budgetDTO = try req.content.decode(BudgetDTO.self)
        let budget = budgetDTO.toModel()
        budget.$user.id = userID
        try await budget.save(on: req.db)
        return .created
    }

    // 删除用户预算
    @Sendable
    func deleteBudget(req: Request) async throws -> HTTPStatus {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "无效的用户ID")
        }

        guard let typeString = req.query[String.self, at: "type"],
            let type = BudgetType(rawValue: typeString) else {
                throw Abort(.badRequest, reason: "无效的预算类型参数")
            }
        
        guard let budget = try await Budget.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$type == type)
            .first() else {
            throw Abort(.notFound, reason: "未找到预算记录")
        }
        try await budget.delete(on: req.db)
        return .noContent
    }
}
