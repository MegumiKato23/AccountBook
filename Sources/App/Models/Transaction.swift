import Fluent
import Foundation

final class Transaction: Model, @unchecked Sendable {
    static let schema = "transactions"

    @ID(key: .id)
    var id: UUID?

    @Enum(key: "category")
    var category: TransactionCategory

    @Enum(key: "type")
    var type: TransactionType

    init () { }

    init(id: UUID? = nil, category: TransactionCategory, type: TransactionType) {
        self.id = id
        self.category = category
        self.type = type
    }

    func toDTO() -> TransactionDTO {
        .init(
            id: self.id,
            category: self.category,
            type: self.type
        )
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case expense = "支出"
    case income = "收入"
}

enum TransactionCategory: String, Codable, CaseIterable {
    // 支出类别
    case food = "餐饮"
    case shopping = "购物"
    case transport = "交通"
    case entertainment = "娱乐"
    case housing = "居住"
    case medical = "医疗"
    case education = "教育"
    case other = "其他"
    
    // 收入类别
    case salary = "工资"
    case bonus = "奖金"
    case investment = "投资"
    case partTime = "兼职"
    case gift = "礼金"
    case otherIncome = "其他收入"
    
    /// 获取支出类别
    static var expenseCategories: [TransactionCategory] {
        [.food, .shopping, .transport, .entertainment, .housing, .medical, .education, .other]
    }
    
    /// 获取收入类别
    static var incomeCategories: [TransactionCategory] {
        [.salary, .bonus, .investment, .partTime, .gift, .otherIncome]
    }
}