import Fluent
import Foundation

final class Bill: Model, @unchecked Sendable {
    static let schema = "bills"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "transaction_id")
    var transaction: Transaction

    @Parent(key: "user_id")
    var user: User

    @Field(key: "amount")
    var amount: Double

    @Field(key: "date")
    var date: Date?

    @Field(key: "description")
    var description: String?


    init() { }

    init(id: UUID? = nil, transactionID: Transaction.IDValue, userID: User.IDValue, amount: Double, date: Date, description: String) {
        self.id = id
        self.$transaction.id = transactionID
        self.$user.id = userID
        self.amount = amount
        self.date = date
        self.description = description
    }

    func toDTO() -> BillDTO {
        .init(
            id: self.id,
            transaction: self.transaction,
            user: self.user,
            amount: self.amount,
            date: self.date,
            description: self.description
        )
    }
}