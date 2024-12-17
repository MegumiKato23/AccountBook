import Fluent
import Vapor

struct UserDTO: Content {
    // 基本信息
    var id: UUID?
    var name: String?
    var password: String?
    var phoneNumber: String?
    var avatarURL: String?

    // 创建时间
    var createdAt: Date?
    var updatedAt: Date?

    // 转换为模型
    func toModel() -> User {
        let model = User()
        
        model.id = self.id
        if let name = self.name {
            model.name = name
        }
        if let password = self.password {
            model.password = password
        }
        if let phoneNumber = self.phoneNumber {
            model.phoneNumber = phoneNumber
        }
        if let avatarURL = self.avatarURL {
            model.avatarURL = avatarURL
        }
        if let createdAt = self.createdAt {
            model.createdAt = createdAt
        }
        if let updatedAt = self.updatedAt {
            model.updatedAt = updatedAt
        }
        return model
    }

    // 验证规则
    static func validations(user: User) {
        // TODO: 写用户名，密码，电话的验证规则
    }
}
