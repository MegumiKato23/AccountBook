import Fluent
import Foundation

final class Account: Model, @unchecked Sendable {
    static let schema = "accounts"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "balance")
    var balance: Double

    init() { }

    init(id: UUID? = nil, userID: User.IDValue, balance: Double) {
        self.id = id
        self.$user.id = userID
        self.balance = balance
    }

    func toDTO() -> AccountDTO {
        .init(
            id: self.id,
            user: self.$user.value,
            balance: self.balance
        )
    }
}