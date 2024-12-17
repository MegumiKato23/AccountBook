import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: UserController())
    try app.register(collection: TransactionController())
    try app.register(collection: BillController())
}
