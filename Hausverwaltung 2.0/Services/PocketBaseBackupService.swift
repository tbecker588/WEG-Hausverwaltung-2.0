//
//  PocketBaseBackupService.swift
//  Hausverwaltung 2.0
//

import Foundation

struct PocketBaseBackupConfig {
    var baseURL: String
    var email: String
    var password: String
    var collection: String
    var fileFieldName: String

    var istVollstaendig: Bool {
        !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.isEmpty
            && !collection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !fileFieldName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct PocketBaseBackupService {
    enum PocketBaseError: LocalizedError {
        case ungueltigeKonfiguration
        case ungueltigeURL
        case authentifizierungFehlgeschlagen
        case uploadFehlgeschlagen(status: Int, message: String)
        case downloadFehlgeschlagen(status: Int, message: String)
        case keinBackupGefunden
        case antwortUngueltig

        var errorDescription: String? {
            switch self {
            case .ungueltigeKonfiguration:
                return "PocketBase-Konfiguration ist unvollständig."
            case .ungueltigeURL:
                return "PocketBase-URL ist ungültig."
            case .authentifizierungFehlgeschlagen:
                return "Anmeldung bei PocketBase fehlgeschlagen."
            case .uploadFehlgeschlagen(let status, let message):
                return "PocketBase-Upload fehlgeschlagen (\(status)): \(message)"
            case .downloadFehlgeschlagen(let status, let message):
                return "PocketBase-Download fehlgeschlagen (\(status)): \(message)"
            case .keinBackupGefunden:
                return "Kein Backup in PocketBase gefunden."
            case .antwortUngueltig:
                return "PocketBase-Antwort konnte nicht gelesen werden."
            }
        }
    }

    private struct AuthResponse: Decodable {
        let token: String
    }

    private struct ListResponse: Decodable {
        let items: [Record]
    }

    private struct Record: Decodable {
        let id: String
        let created: String?
        let raw: [String: JSONValue]

        enum CodingKeys: CodingKey {
            case id
            case created
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: DynamicCodingKey.self)
            var map: [String: JSONValue] = [:]
            for key in container.allKeys {
                map[key.stringValue] = try container.decode(JSONValue.self, forKey: key)
            }
            raw = map
            id = (map["id"]?.stringValue) ?? ""
            created = map["created"]?.stringValue
        }
    }

    private enum JSONValue: Decodable {
        case string(String)
        case number(Double)
        case bool(Bool)
        case array([JSONValue])
        case object([String: JSONValue])
        case null

        var stringValue: String? {
            if case .string(let value) = self { return value }
            return nil
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                self = .null
            } else if let value = try? container.decode(String.self) {
                self = .string(value)
            } else if let value = try? container.decode(Double.self) {
                self = .number(value)
            } else if let value = try? container.decode(Bool.self) {
                self = .bool(value)
            } else if let value = try? container.decode([String: JSONValue].self) {
                self = .object(value)
            } else if let value = try? container.decode([JSONValue].self) {
                self = .array(value)
            } else {
                throw PocketBaseError.antwortUngueltig
            }
        }
    }

    private struct DynamicCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }

        init?(intValue: Int) {
            self.stringValue = String(intValue)
            self.intValue = intValue
        }
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func uploadBackup(config: PocketBaseBackupConfig, dateiURL: URL) async throws {
        guard config.istVollstaendig else { throw PocketBaseError.ungueltigeKonfiguration }
        let baseURL = try normalisiereBaseURL(config.baseURL)
        let token = try await authentifizieren(baseURL: baseURL, email: config.email, password: config.password)

        let endpoint = baseURL.appendingPathComponent("api/collections/\(config.collection)/records")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let dateiDaten = try Data(contentsOf: dateiURL)
        request.httpBody = baueMultipartBody(
            boundary: boundary,
            dateiDaten: dateiDaten,
            dateiName: dateiURL.lastPathComponent,
            fileFieldName: config.fileFieldName
        )

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw PocketBaseError.antwortUngueltig }
        guard (200..<300).contains(http.statusCode) else {
            throw PocketBaseError.uploadFehlgeschlagen(status: http.statusCode, message: "Server hat den Upload abgelehnt.")
        }
    }

    func ladeNeuestesBackup(config: PocketBaseBackupConfig) async throws -> URL {
        guard config.istVollstaendig else { throw PocketBaseError.ungueltigeKonfiguration }
        let baseURL = try normalisiereBaseURL(config.baseURL)
        let token = try await authentifizieren(baseURL: baseURL, email: config.email, password: config.password)

        let recordsEndpoint = baseURL.appendingPathComponent("api/collections/\(config.collection)/records")
        var comps = URLComponents(url: recordsEndpoint, resolvingAgainstBaseURL: false)
        comps?.queryItems = [
            URLQueryItem(name: "sort", value: "-created"),
            URLQueryItem(name: "perPage", value: "1")
        ]

        guard let listURL = comps?.url else { throw PocketBaseError.ungueltigeURL }

        var listRequest = URLRequest(url: listURL)
        listRequest.httpMethod = "GET"
        listRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (listData, listResponse) = try await session.data(for: listRequest)
        guard let listHTTP = listResponse as? HTTPURLResponse else { throw PocketBaseError.antwortUngueltig }
        guard (200..<300).contains(listHTTP.statusCode) else {
            throw PocketBaseError.downloadFehlgeschlagen(status: listHTTP.statusCode, message: "Abruf der Datensätze fehlgeschlagen.")
        }

        let list = try JSONDecoder().decode(ListResponse.self, from: listData)
        guard let record = list.items.first, !record.id.isEmpty else {
            throw PocketBaseError.keinBackupGefunden
        }

        guard let fileName = record.raw[config.fileFieldName]?.stringValue, !fileName.isEmpty else {
            throw PocketBaseError.keinBackupGefunden
        }

        let fileURL = baseURL
            .appendingPathComponent("api/files")
            .appendingPathComponent(config.collection)
            .appendingPathComponent(record.id)
            .appendingPathComponent(fileName)

        var downloadRequest = URLRequest(url: fileURL)
        downloadRequest.httpMethod = "GET"
        downloadRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (fileData, fileResponse) = try await session.data(for: downloadRequest)
        guard let fileHTTP = fileResponse as? HTTPURLResponse else { throw PocketBaseError.antwortUngueltig }
        guard (200..<300).contains(fileHTTP.statusCode) else {
            throw PocketBaseError.downloadFehlgeschlagen(status: fileHTTP.statusCode, message: "Datei-Download fehlgeschlagen.")
        }

        let fallbackName = "PocketBase_Backup_\(zeitstempel()).hausverwaltung"
        let dateiname = fileName.lowercased().hasSuffix(".hausverwaltung") ? fileName : fallbackName
        let zielURL = FileManager.default.temporaryDirectory.appendingPathComponent(dateiname)
        try fileData.write(to: zielURL, options: .atomic)
        return zielURL
    }

    private func authentifizieren(baseURL: URL, email: String, password: String) async throws -> String {
        let authURL = baseURL.appendingPathComponent("api/collections/users/auth-with-password")
        var request = URLRequest(url: authURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ["identity": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw PocketBaseError.antwortUngueltig }
        guard (200..<300).contains(http.statusCode) else {
            throw PocketBaseError.authentifizierungFehlgeschlagen
        }

        let auth = try JSONDecoder().decode(AuthResponse.self, from: data)
        guard !auth.token.isEmpty else { throw PocketBaseError.authentifizierungFehlgeschlagen }
        return auth.token
    }

    private func normalisiereBaseURL(_ string: String) throws -> URL {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme, !scheme.isEmpty else {
            throw PocketBaseError.ungueltigeURL
        }
        return url
    }

    private func baueMultipartBody(
        boundary: String,
        dateiDaten: Data,
        dateiName: String,
        fileFieldName: String
    ) -> Data {
        var body = Data()
        let lineBreak = "\r\n"

        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"name\"\(lineBreak)\(lineBreak)".data(using: .utf8)!)
        body.append("Backup \(zeitstempel())\(lineBreak)".data(using: .utf8)!)

        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fileFieldName)\"; filename=\"\(dateiName)\"\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\(lineBreak)\(lineBreak)".data(using: .utf8)!)
        body.append(dateiDaten)
        body.append(lineBreak.data(using: .utf8)!)
        body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)
        return body
    }

    private func zeitstempel() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
}
