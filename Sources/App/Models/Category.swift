import Vapor
import FluentPostgreSQL

final class Category: Codable {
    var id: Int?
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

extension Category: PostgreSQLModel {}
extension Category: Content {}
extension Category: Migration {}
extension Category: Parameter {}

extension Category {
    var acronyms: Siblings<Category, Acronym, AcronymCategoryPivot> {
        return siblings()
    }
    
    static func addCategory(_ name: String, to acronym: Acronym, on req: Request) throws -> Future<Void> {
        return try Category.query(on: req)
            .filter(\.name == name)
            .first()
            .flatMap(to: Void.self) { foundCategory in
                if let existingCategory = foundCategory {
                    let pivot = try AcronymCategoryPivot(acronym.requireID(),
                                                         existingCategory.requireID())
                    
                    return pivot.save(on: req).transform(to: ())
                } else {
                    let category = Category(name: name)
                    return category.save(on: req)
                        .flatMap(to: Void.self) { savedCategory in
                            let pivot = try AcronymCategoryPivot(acronym.requireID(),
                                                                 savedCategory.requireID())
                            return pivot.save(on: req).transform(to: ())
                    }
                }
        }
    }

}











