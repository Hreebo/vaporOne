import Vapor
import FluentSQLite

final class Acronym: Codable, Content, SQLiteModel, Migration {
    var id: Int?
    var short: String
    var long: String
    
    init(short: String, long: String) {
        self.short = short
        self.long = long
    }
}
/*
extension Acronym: Model {
    typealias Database = SQLiteDatabase
    typealias ID  = Int
    public static var idKey: IDKey = \Acronym.id
}
*/

// This can be replace with:


