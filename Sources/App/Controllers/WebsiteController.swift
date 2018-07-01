import Vapor
import Leaf
import Fluent
import Authentication

struct WebsiteController: RouteCollection {
    func boot(router: Router) throws {
        
        let authSessionRoutes = router.grouped(User.authSessionsMiddleware())
        let protectedRoutes = authSessionRoutes.grouped(RedirectMiddleware<User>(path: "/login"))

        authSessionRoutes.get(use: indexHandler)
        authSessionRoutes.get("acronyms", Acronym.parameter, use: acronymHandler)
        router.get("hello", use: hello)
        authSessionRoutes.get("users",User.parameter , use: userHandler)
        authSessionRoutes.get("users", use: allUsersHandler)
        authSessionRoutes.get("categories", use: allCategoriesHandler)
        authSessionRoutes.get("categories", Category.parameter, use: categoryHandler)
        protectedRoutes.get("acronyms","create", use: createAcronymHandler)
        protectedRoutes.get("acronyms", Acronym.parameter, "edit", use: editAcronymHandler)
        
        protectedRoutes.post("acronyms", Acronym.parameter, "edit", use: editAcronymPostHandler)
        protectedRoutes.post(CreateAcronymData.self, at: "acronyms", "create", use: createAcronymPostHandler)
        protectedRoutes.post("acronyms",Acronym.parameter, "delete", use: deleteAcronymHandler)
        
        authSessionRoutes.get("login", use: loginHandler)
        authSessionRoutes.post(LoginPostData.self, at: "login", use: loginPostHandler)
        authSessionRoutes.post("logout", use: logoutHandler)
        
    }
    
    func hello(_ req: Request) throws -> Future<View> {
        let title = "HELLO WORLD"
        return try req.view().render("base", title)
    }
    
    func indexHandler(_ req: Request) throws -> Future<View> {
        return Acronym.query(on: req).all().flatMap(to: View.self) { acronyms in
            let acornymsData = acronyms.isEmpty ? nil : acronyms
           // let context = IndexContent(title: "Homepage", acronyms: acornymsData)
            let userLoggedIn = try req.isAuthenticated(User.self)
            //let context = IndexContent(title: "Homepage", acronyms: acornymsData, userLoggedIn: userLoggedIn)
            let showCookieMessage = req.http.cookies["cookies-accepted"] == nil
            let context = IndexContent(title: "Homepage",
                                       acronyms: acornymsData,
                                       userLoggedIn: userLoggedIn,
                                       showCookieMeesage: showCookieMessage)
            return try req.view().render("index", context)
        }
    }
    
    func acronymHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Acronym.self).flatMap(to: View.self) { acronym in
            return try acronym.user.get(on: req).flatMap(to: View.self) { user in
                //let context = AcronymContext(title: acronym.short, acronym: acronym, user: user)
                let categories = try acronym.categories.query(on: req).all()
                let context = AcronymContext(title: acronym.short,
                                             acronym: acronym,
                                             user: user,
                                             categories: categories)
                return try req.view().render("acronym", context)
            }
        }
    }
    
    func userHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(User.self).flatMap(to: View.self) { user in
            return try user.acronyms
                        .query(on: req)
                        .all()
                .flatMap(to: View.self) { acronyms in
                    let context = UserContext(title: user.name, user: user, acronyms: acronyms)
                    
                    return try req.view().render("user", context)
            }
        }
    }
    
    func allUsersHandler(_ req: Request) throws -> Future<View> {
        return User.query(on: req).all().flatMap(to: View.self) { users in
            let context = AllUsersContext(title: "All Users", users: users)
            return try req.view().render("allUsers", context)
        }
    }
    
    func allCategoriesHandler(_ req: Request) throws -> Future<View> {
        let categories = Category.query(on: req).all()
        let context = AllCategoriesContext(categories: categories)
        return try req.view().render("allCategories", context)
    }
    
    func categoryHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Category.self).flatMap(to: View.self) { category in
            let acronyms = try category.acronyms.query(on: req).all()
            let context = CategoryContext(title: category.name, category: category, acronyms: acronyms)
            return try req.view().render("category", context)
        }
    }
    
    func createAcronymHandler(_ req: Request) throws -> Future<View> {
       // let context = CreateAcronymContext(users: User.query(on: req).all())
        let token = try CryptoRandom()
            .generateData(count: 16)
            .base64EncodedString()
        let context = CreateAcronymContext(csrfToken: token)
        try req.session()["CSRF_TOKEN"] = token
        return try req.view().render("createAcronym", context)
    }
    /* with NO Categories
    func createAcronymPostHandler(_ req: Request, acronym: Acronym) throws -> Future<Response> {
        return acronym.save(on: req).map(to: Response.self) { acronym in
            guard let id = acronym.id else {
                throw Abort(.internalServerError)
            }
            return req.redirect(to: "/acronyms/\(id)")
        }
    }
    */
    
    func createAcronymPostHandler(_ req: Request, data: CreateAcronymData) throws
    -> Future<Response> {
       // let acronym = Acronym(short: data.short, long: data.long, userID: data.userID)
        let user = try req.requireAuthenticated(User.self)
        let expectedToken = try req.session()["CSRF_TOKEN"]
        try req.session()["CSRF_TOKEN"] = nil
        guard expectedToken == data.csrfToken else {
            throw Abort(.badRequest)
        }
        let acronym = try Acronym(short: data.short,
                                  long: data.long,
                                  userID: user.requireID())
        return acronym.save(on: req).flatMap(to: Response.self) { acronym in
            guard let id = acronym.id else {
                throw Abort(.internalServerError)
            }
            
            var categorySaves: [Future<Void>] = []
            
            for category in data.categories ?? [] {
                try categorySaves.append(Category.addCategory(category, to: acronym, on: req))
            }
            
            let redirect = req.redirect(to: "/acronyms/\(id)")
            
            return categorySaves.flatten(on: req).transform(to: redirect)
            
        }

    }
    
    func editAcronymHandler(_ req: Request) throws -> Future<View> {
        
        return try req.parameters.next(Acronym.self).flatMap(to: View.self) { acronym in
            //let context = EditAcronymContext(acronym: acronym, users: User.query(on: req).all())
            //let users = User.query(on: req).all()
            let categories = try acronym.categories.query(on: req).all()
           // let context = EditAcronymContext(acronym: acronym, users: users, categories: categories)
            let context = EditAcronymContext(acronym: acronym, categories: categories)
            return try req.view().render("createAcronym", context)
        }
 
    }
    
    func editAcronymPostHandler(_ req: Request) throws -> Future<Response> {
        return try flatMap(to: Response.self, req.parameters.next(Acronym.self), req.content.decode(CreateAcronymData.self)) { acronym, data in
           let user = try req.requireAuthenticated(User.self)
            acronym.short = data.short
            acronym.long = data.long
            acronym.userID = try user.requireID()
            
            return acronym.save(on: req).flatMap(to: Response.self) { savedAcronym in
                guard let id = savedAcronym.id else {
                    throw Abort(.internalServerError)
                }
                //return req.redirect(to: "/acronyms/\(id)")
                return try acronym.categories.query(on: req).all().flatMap(to: Response.self) {
                    
                    existingCategories in
                    
                    let existingStringArray =  existingCategories.map {$0.name}
                    let existingSet = Set<String>(existingStringArray)
                    let newSet = Set<String>(data.categories ?? [])
                    
                    let categoriesToAdd = newSet.subtracting(existingSet)
                    let categoriesToRemove = existingSet.subtracting(newSet)
                    
                    var categoryResults: [Future<Void>] = []
                    
                    for newCategory in categoriesToAdd {
                        categoryResults.append(try Category.addCategory(newCategory, to: acronym, on: req))
                    }
                    
                    for categoryNameToRemove in categoriesToRemove {
                        let categoryToRemove = existingCategories.first {
                            $0.name == categoryNameToRemove
                        }
                        
                        if let category = categoryToRemove {
                            categoryResults.append(try AcronymCategoryPivot.query(on: req)
                                                            .filter(\.acronymID == acronym.requireID())
                                                            .filter(\.categoryID == category.requireID())
                                                            .delete())
                        }
                    }
                    
                    return categoryResults.flatten(on: req).transform(to: req.redirect(to: "/acronyms/\(id)"))
                }
            }
        }
    }
    
    func deleteAcronymHandler(_ req: Request) throws -> Future<Response> {
        return try req.parameters.next(Acronym.self).delete(on: req).transform(to: req.redirect(to: "/"))
    }
    
    func loginHandler(_ req: Request) throws -> Future<View> {
        let context: LoginContext
        if req.query[Bool.self, at: "error"] != nil {
            context = LoginContext(loginError: true)
        } else {
            context = LoginContext()
        }
        
        return try req.view().render("login", context)
    }
    
    func loginPostHandler(_ req: Request, userData: LoginPostData) throws -> Future<Response> {
        return User.authenticate(username: userData.username, password: userData.password, using: BCryptDigest(),
                                 on: req).map(to: Response.self) { user in
                                    guard let user = user else {
                                        return req.redirect(to: "/login?error")
                                    }
                                    try req.authenticateSession(user)
                                    return req.redirect(to: "/")
        }
    }
    
    func logoutHandler(_ req: Request) throws -> Response {
        try req.unauthenticateSession(User.self)
        return req.redirect(to: "/")
    }
}

struct IndexContent: Encodable {
    let title: String
    let acronyms: [Acronym]?
    let userLoggedIn: Bool
    let showCookieMeesage: Bool
}

struct AcronymContext: Encodable {
    let title: String
    let acronym: Acronym
    let user: User
    let categories: Future<[Category]>
}

struct UserContext: Encodable {
    let title: String
    let user: User
    let acronyms: [Acronym]
}

struct AllUsersContext: Encodable {
    let title: String
    let users: [User]
}

struct AllCategoriesContext: Encodable {
    let title = "All Categories"
    let categories : Future<[Category]>
}

struct CategoryContext: Encodable {
    let title: String
    let category: Category
    let acronyms: Future<[Acronym]>
}

struct CreateAcronymContext: Encodable {
    let title = "Create An Acronym"
    let csrfToken: String
    //let users: Future<[User]>
}

struct EditAcronymContext: Encodable {
    let title = "Edit Acronym"
    let acronym: Acronym
    //let users: Future<[User]>
    let editing = true
    let categories: Future<[Category]>
}

struct CreateAcronymData: Content {
    //let userID: User.ID
    let short: String
    let long: String
    let categories: [String]?
    let csrfToken: String
}

struct LoginContext: Encodable {
    let title = "Log In"
    let loginError : Bool
    
    init(loginError: Bool = false) {
        self.loginError = loginError
    }
}

struct LoginPostData: Content {
    let username: String
    let password: String
}
