@testable import App
import Vapor
import XCTest
import FluentPostgreSQL

final class UserTests: XCTestCase {
  
    func testUsersCanBeRetrievedFromApi() throws {
        let expectedName = "Alice"
        let expectedUsername = "alice"
        
        var config = Config.default()
        var servis = Services.default()
        var env = Environment.testing
        try App.configure(&config,&env, &servis)
        let app = try Application(config: config, environment: env, services: servis)
        try App.boot(app)
        
        let conn = try app.newConnection(to: .psql).wait()
        
        
        let user = User(name: expectedName, username: expectedUsername, password: "")
        let savedUser = try user.save(on: conn).wait()
        _ = try User(
            name: "Luke",
            username: "lukes",
            password: "").save(on: conn).wait()
        
        let responder = try app.make(Responder.self)
        
        let request = HTTPRequest(
            method: .GET,
            url: URL(string: "/api/users")!)
        let wrappedRequest = Request(http: request, using: app)
        
        let response = try responder
            .respond(to: wrappedRequest)
            .wait()

        let data = response.http.body.data
        let users = try JSONDecoder().decode([User].self, from: data!)

        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(users[0].name, expectedName)
        XCTAssertEqual(users[0].username, expectedUsername)
        XCTAssertEqual(users[0].id, savedUser.id)
        
        conn.close()
    }
}
