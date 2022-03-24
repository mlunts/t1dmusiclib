//
//  NetworkClient.swift
//  musiclib
//
//  Created by mlunts on 19.03.2022.
//

import Foundation
import ComposableArchitecture

enum APIError: Error {
    case downloadError
    case decodingError
}

public class NetworkClient {
    public static let shared = NetworkClient()

    private let baseURL = "https://api.deezer.com"

    enum APIEndPoint: String {
        case album = "/album/*"
        case artistAlbum = "/artist/*/albums"
        case chartArtists = "/chart/0/artists"
        case searchArtist = "/search/artist"
        case track = "/track/*"
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    // MARK: Chart Requests
    func chartArtistsEffect() -> Effect<Chart, APIError> {
        guard let url = URL(string: urlStringBuilder(.chartArtists)) else {
            fatalError("Error on creating url")
        }

        return performTask(with: url, type: Chart.self)
    }

    // MARK: Artist Requests
    func artistAlbumsEffect(id: Int) -> Effect<[Album], APIError> {
        guard let url = URL(string: urlStringBuilder(.artistAlbum)
            .replacingOccurrences(of: "*", with: String(id))) else {
            fatalError("Error on creating url")
        }

        return performTask(with: url, type: AlbumResponse.self)
                .map({ $0.data })
    }

    func searchArtistEffect(searchQuery: String, currentIndex: Int) -> Effect<[Artist], APIError> {
        let queryItems = [URLQueryItem(name: "q", value: searchQuery),
                          URLQueryItem(name: "index", value: String(currentIndex))]
        var urlComps = URLComponents(string: urlStringBuilder(.searchArtist))
        urlComps?.queryItems = queryItems

        guard let url = urlComps?.url else {
            fatalError("Error on creating url")
        }
        
        return performTask(with: url, type: ArtistsResponse.self)
                .map({ $0.data })
    }

    // MARK: Album Requests
    func albumEffect(id: Int) -> Effect<Album, APIError> {
        guard let url = URL(string: urlStringBuilder(.album)
            .replacingOccurrences(of: "*", with: String(id))) else {
            fatalError("Error on creating url")
        }

        return performTask(with: url, type: Album.self)
    }

    // MARK: Track Requests
    func trackInfoEffect(id: Int) -> Effect<Track, APIError> {
        guard let url = URL(string: urlStringBuilder(.track)
            .replacingOccurrences(of: "*", with: String(id))) else {
            fatalError("Error on creating url")
        }

        return performTask(with: url, type: Track.self)
    }

    // MARK: - private

    private func performTask<T:Decodable>(with url: URL, type: T.Type) -> Effect<T, APIError> {
        return URLSession.shared.dataTaskPublisher(for: url)
            .mapError { _ in APIError.downloadError }
            .map { data, _ in data }
            .decode(type: type.self, decoder: decoder)
            .mapError { _ in APIError.decodingError }
            .eraseToEffect()
    }

    private func urlStringBuilder(_ endpoint: APIEndPoint) -> String {
        return "\(baseURL)\(endpoint.rawValue)"
    }
}
