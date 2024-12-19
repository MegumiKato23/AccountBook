import NIOSSL
import Fluent
import FluentMySQLDriver
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // 设置请求体大小限制
    app.routes.defaultMaxBodySize = "10mb"

    // 设置文件上传路径
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    var tls = TLSConfiguration.makeClientConfiguration()
    tls.certificateVerification = .none

    app.databases.use(DatabaseConfigurationFactory.mysql(
        hostname: "localhost",
        port: 3306,
        username: "MegumiKato",
        password: "20040923",
        database: "testz",
        tlsConfiguration: tls
    ), as: .mysql)

    app.migrations.add(CreateUser())
    app.migrations.add(CreateTransaction())
    app.migrations.add(CreateBill())
    app.migrations.add(CreateBudget())
    try await app.autoMigrate()
    // register routes
    try routes(app)
}
