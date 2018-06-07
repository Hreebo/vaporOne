import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req -> String in
        
        return "Hello You Motherfucker and ape sucker..."
        
    }
    
    router.get("hello", String.parameter) { req  -> String in
        let name = try req.parameters.next(String.self)
    
        return "Hell, \(name)"
    }
    
    router.get("count", Int.parameter) { req -> String in
        let number = try req.parameters.next(Int.self)
        let count = number + 10
        
        return "yourn \(number) + 10 is \(count)"
        
    }
    /*
    router.post(InfoData.self, at: "info") { req, data -> String in
        return "Hello \(data.name)"
    }
    
    router.post(InfoData.self, at: "info") { req, data -> InfoResponse in
        return InfoResponse(request: data)
        
    }
    
    
    //POST
    router.post("api","acronyms") { req -> Future<Acronym> in
        return try req.content
            .decode(Acronym.self)
            .flatMap(to: Acronym.self) { acronym in
            return acronym.save(on: req)
        }
    }
    
    //GET All
    /*
    router.get("api","acronyms") { req -> Future<[Acronym]> in
        return Acronym.query(on: req).all()
    }
 */
    
    //GET by ID
    router.get("api", "acronyms", Acronym.parameter) { req  -> Future<Acronym> in
        return try req.parameters.next(Acronym.self)
    }
    
    //UPDATE
    router.put("api","acronyms", Acronym.parameter) { req -> Future<Acronym> in
        return try flatMap(to: Acronym.self, req.parameters.next(Acronym.self), req.content.decode(Acronym.self)) { acronym, updateAcronym in
            acronym.short = updateAcronym.short
            acronym.long = updateAcronym.long
            
            return acronym.save(on: req)
        }
    }
    
    //DELETE
    router.delete("api", "acronyms", Acronym.parameter) { req -> Future<HTTPStatus> in
        return try req.parameters.next(Acronym.self)
                        .delete(on: req)
                        .transform(to: HTTPStatus.noContent)
        
    }
    
    //Search by Flunet
    router.get("api","acronyms", "search") { req -> Future<[Acronym]> in
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        
        return try Acronym.query(on: req).group(.or) { or in
            try or.filter(\.short == searchTerm )
            try or.filter(\.long == searchTerm)
            
        }.all()
    }
    
    //GET First
    router.get("api", "acronyms","first") { req  -> Future<Acronym> in
        return Acronym.query(on: req)
                    .first()
                    .map(to: Acronym.self) { acronym in
                        guard let acronym = acronym else {
                            throw Abort(.notFound)
                        }
                        return acronym
        }
    }
    
    //Sorting
    router.get("api", "acronyms","sorted") { req -> Future<[Acronym]> in
        return try Acronym.query(on: req)
                    .sort(\.short, .ascending)
                    .all()
    }
    */
    
    let acronymsController = AcronymController()
    try router.register(collection: acronymsController)
    
    let usersController = UsersController()
    try router.register(collection: usersController)
}

struct InfoData: Content {
    let name: String
}

struct  InfoResponse: Content {
    let request: InfoData
}
