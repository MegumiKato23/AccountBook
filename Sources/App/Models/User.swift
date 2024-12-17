import Fluent
import Foundation

/// Property wrappers interact poorly with `Sendable` checking, causing a warning for the `@ID` property
/// It is recommended you write your model with sendability checking on and then suppress the warning
/// afterwards with `@unchecked Sendable`.
final class User: Model, @unchecked Sendable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "password")
    var password: String

    @Field(key: "phoneNumber")   
    var phoneNumber: String

    @Field(key: "avatarURL")
    var avatarURL: String?

    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updatedAt", on: .update)
    var updatedAt: Date?

    init() { }

    init(id: UUID? = nil, 
        name: String, 
        password: String, 
        createdAt: Date? = nil, 
        updatedAt: Date? = nil, 
        phoneNumber: String, 
        avatarURL: String? = nil) {
        self.id = id
        self.name = name
        self.password = password
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.phoneNumber = phoneNumber
        self.avatarURL = avatarURL
    }
    
    func toDTO() -> UserDTO {
        .init(
            id: self.id,
            name: self.$name.value,
            password: self.$password.value,
            phoneNumber: self.$phoneNumber.value,
            avatarURL: self.avatarURL,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt
        )
    }
}
