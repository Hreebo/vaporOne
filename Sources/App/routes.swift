import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello", String.parameter) { req  -> String in
        let name = try req.parameters.next(String.self)
    
        return "Hell, \(name)"
    }
    
    router.get("count", Int.parameter) { req -> String in
        let number = try req.parameters.next(Int.self)
        let count = number + 10
        
        return "yourn \(number) + 10 is \(count)"
        
    }
    
    router.post(InfoData.self, at: "info") { req, data -> String in
        return "Hello \(data.name)"
    }
    
    router.post(InfoData.self, at: "info") { req, data -> InfoResponse in
        return InfoResponse(request: data)
        
    }
    
    router.post("api","acronyms") { req -> Future<Acronym> in
        return try req.content.decode(Acronym.self).flatMap(to: Acronym.self) { acronym in
            
            return acronym.save(on: req)
            
        }
        
    }

}

struct InfoData: Content {
    let name: String
}

struct  InfoResponse: Content {
    let request: InfoData
}
