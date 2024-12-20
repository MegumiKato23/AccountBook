import Vapor
import Fluent

struct AccountDTO: Content {
    var id: UUID?
    var user: User?
    var balance: Double?

    func toModel() -> Account {
        let model = Account()
        model.id = id
        if let user = self.user {
            model.$user.id = user.id!
        }
        if let balance = self.balance {
            model.balance = balance
        }
        return model
    }
}