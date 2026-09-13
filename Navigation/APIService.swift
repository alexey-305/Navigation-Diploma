//
//  APIService.swift
//  Navigation
//

import Foundation

struct ChuckNorrisQuote: Decodable {
    let value: String
    let category: String?
}

/// Сырой ответ от api.chucknorris.io — отдельная модель, чтобы не завязывать
/// весь остальной код на конкретный формат внешнего API (categories там —
/// массив строк, часто пустой; наружу отдаём куда более удобный ChuckNorrisQuote
/// с одной опциональной категорией).
private struct ChuckNorrisAPIResponse: Decodable {
    let value: String
    let categories: [String]
}

enum APIServiceError: LocalizedError {
    case badStatusCode(Int)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .badStatusCode(let code):
            return "Сервер вернул код ошибки \(code)"
        case .noData:
            return "Сервер не вернул данные"
        }
    }
}

protocol APIServiceProtocol {
    func fetchRandomQuote(completion: @escaping (Result<ChuckNorrisQuote, Error>) -> Void)
}

/// Реальный сетевой запрос к https://api.chucknorris.io через URLSession —
/// публичный бесплатный API, ключ не требуется.
final class APIService: APIServiceProtocol {
    
    private let session: URLSession
    private let url = URL(string: "https://api.chucknorris.io/jokes/random")!
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchRandomQuote(completion: @escaping (Result<ChuckNorrisQuote, Error>) -> Void) {
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                completion(.failure(APIServiceError.badStatusCode(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIServiceError.noData))
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(ChuckNorrisAPIResponse.self, from: data)
                let quote = ChuckNorrisQuote(value: decoded.value, category: decoded.categories.first)
                completion(.success(quote))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
