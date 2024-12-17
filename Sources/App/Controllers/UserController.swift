import Vapor
import Fluent

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let usersRoute = routes.grouped("api", "users")
        
        // 公开路由
        usersRoute.post("register", use: register)
        usersRoute.post("login", use: login)
        
        usersRoute.group(":userID") { user in
            user.get("profile", use: getProfile)
            user.put("profile", use: updateProfile)
            user.delete("profile", use: deleteUser)
            user.post("avatar", use: uploadAvatar)
        }
    }
    
   
    // 用户注册
    @Sendable
    func register(req: Request) async throws -> HTTPStatus {
        let user = try req.content.decode(UserDTO.self).toModel()

        UserDTO.validations(user: user)
        // 检查手机号是否已存在
        if try await User.query(on: req.db)
            .filter(\.$phoneNumber == user.phoneNumber)
            .first() != nil {
            throw Abort(.conflict, reason: "该手机号已被注册")
        }
        
        // 密码加密
        let hashedPassword = try await req.password.async.hash(user.password)
        
        user.password = hashedPassword

        try await user.save(on: req.db)
        
        if let userUUID = user.id {
            req.logger.info("UserID: \(userUUID)")
        }

        return .accepted
    }
    
    // 用户登录
    @Sendable
    func login(req: Request) async throws -> HTTPStatus {
        let loginDTO = try req.content.decode(LoginDTO.self)
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$phoneNumber == loginDTO.phoneNumber)
            .first()
        else {
            throw Abort(.unauthorized, reason: "手机号或密码错误")
        }
        
        guard try await req.password.async.verify(loginDTO.password, created: user.password) else {
            throw Abort(.unauthorized, reason: "手机号或密码错误")
        }
        
        return .accepted
    }
    
    // 获取用户资料
    @Sendable   
    func getProfile(req: Request) async throws -> UserDTO {
        // 打印接收到的ID
        if let userID = req.parameters.get("userID") {
            req.logger.info("Attempting to find user with ID: \(userID)")
        }

        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound, reason: "用户不存在")
        }
        return user.toDTO()
    }
    

    // 更新用户资料
    @Sendable
    func updateProfile(req: Request) async throws -> UserDTO {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound, reason: "用户不存在")
        }
        
        let updateDTO = try req.content.decode(UserUpdateDTO.self)

        if let name = updateDTO.name {
            user.name = name
        }
        
        if let phoneNumber = updateDTO.phoneNumber {
            // 检查新手机号是否被其他用户使用
            if try await User.query(on: req.db)
                .filter(\.$phoneNumber == phoneNumber)
                .filter(\.$id != user.id!)
                .first() != nil {
                throw Abort(.conflict, reason: "该手机号已被使用")
            }
            user.phoneNumber = phoneNumber
        }

        if let password = updateDTO.password {
            let hashedPassword = try await req.password.async.hash(password)
            user.password = hashedPassword
        }
        
        try await user.save(on: req.db)
        return user.toDTO()
    }
    
    // 删除账号
    @Sendable
    func deleteUser(req: Request) async throws -> HTTPStatus {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound, reason: "用户不存在")
        }
        try await user.delete(on: req.db)
        return .noContent
    }
    
    // 上传头像
    @Sendable
    func uploadAvatar(req: Request) async throws -> UserDTO {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound, reason: "用户不存在")
        }
        
        // 获取并验证上传的文件
        struct FileUpload: Content {
            var file: File?
        }
        
        let fileUpload = try req.content.decode(FileUpload.self)
        guard var file = fileUpload.file else {
            throw Abort(.badRequest, reason: "请选择要上传的图片")
        }
        
        // 验证文件类型
        guard let contentType = file.contentType,
              let fileExt = contentType.description.split(separator: "/").last,
              ["jpeg", "jpg", "png"].contains(fileExt.lowercased()) else {
            throw Abort(.badRequest, reason: "只支持JPG和PNG格式的图片")
        }
        
        // 读取文件数据
        guard let fileData = try? file.data.readData(length: file.data.readableBytes) else {
            throw Abort(.internalServerError, reason: "读取文件失败")
        }
        
        // 生成文件名和路径
        let fileName = "\(UUID().uuidString).\(fileExt)"
        let avatarPath = "uploads/avatars/"
        let publicPath = req.application.directory.publicDirectory
        let fullPath = publicPath + avatarPath
        let filePath = fullPath + fileName
        
        do {
            // 创建目录
            try FileManager.default.createDirectory(
                atPath: fullPath,
                withIntermediateDirectories: true,
                attributes: nil
            )
            
            // 保存文件
            try fileData.write(to: URL(fileURLWithPath: filePath))
            
            // 删除旧头像文件（如果存在）
            if let oldAvatarURL = user.avatarURL,
               let oldPath = oldAvatarURL.split(separator: "/").last {
                let oldFilePath = fullPath + String(oldPath)
                try? FileManager.default.removeItem(atPath: oldFilePath)
            }
            
            // 更新用户头像URL
            user.avatarURL = "/" + avatarPath + fileName
            try await user.save(on: req.db)
            
            return user.toDTO()
        } catch {
            // 清理：如果保存过程中出错，删除已上传的文件
            try? FileManager.default.removeItem(atPath: filePath)
            throw Abort(.internalServerError, reason: "保存头像失败：\(error.localizedDescription)")
        }
    }
}

// MARK: - 辅助结构体
private struct LoginDTO: Content {
    let phoneNumber: String
    let password: String
}

private struct UserUpdateDTO: Content {
    let name: String?
    let phoneNumber: String?
    let password: String?
} 