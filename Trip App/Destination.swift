import Foundation

/// Stable city metadata, independent of trips and persistence.
struct Destination: Codable, Identifiable, Hashable {
    let id: String
    let displayName: String
    let countryCode: String
    let timeZoneIdentifier: String
    let cover: Cover?

    struct Cover: Codable, Hashable {
        let assetName: String
        let fileName: String
        let attribution: Attribution
    }

    struct Attribution: Codable, Hashable {
        let creator: String
        let sourceURL: URL
        let license: String
        let credit: String
    }
}

/// Decode once at the data boundary, rather than in a view body.
struct DestinationCatalog: Codable {
    let schemaVersion: Int
    let destinations: [Destination]

    enum ValidationError: Error, Equatable {
        case unsupportedVersion
        case duplicateID(String)
        case invalidDestination(String)
        case invalidCover(String)
    }

    static func decode(_ data: Data) throws -> DestinationCatalog {
        let catalog = try JSONDecoder().decode(Self.self, from: data)
        guard catalog.schemaVersion == 1 else {
            throw ValidationError.unsupportedVersion
        }
        var ids = Set<String>()
        for destination in catalog.destinations {
            guard ids.insert(destination.id).inserted else {
                throw ValidationError.duplicateID(destination.id)
            }
            guard !destination.id.isEmpty,
                  !destination.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  destination.countryCode.count == 2,
                  TimeZone(identifier: destination.timeZoneIdentifier) != nil else {
                throw ValidationError.invalidDestination(destination.id)
            }
            if let cover = destination.cover {
                guard !cover.assetName.isEmpty, !cover.fileName.isEmpty,
                      !cover.attribution.creator.isEmpty,
                      !cover.attribution.license.isEmpty,
                      !cover.attribution.credit.isEmpty,
                      cover.attribution.sourceURL.scheme == "https",
                      cover.attribution.sourceURL.host != nil else {
                    throw ValidationError.invalidCover(destination.id)
                }
            }
        }
        return catalog
    }

    func destination(id: String) -> Destination? {
        destinations.first { $0.id == id }
    }
}
