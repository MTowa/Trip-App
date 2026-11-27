import Foundation
import Testing
import UIKit
@testable import Trip_App

@MainActor
struct DestinationCatalogTests {
    @Test func decodesCityWithoutCover() throws {
        let catalog = try DestinationCatalog.decode(data())
        let city = try #require(catalog.destination(id: "jp-kyoto"))
        #expect(city.displayName == "京都")
        #expect(city.cover == nil)
        #expect(catalog.destination(id: "unknown") == nil)
    }

    @Test func rejectsDuplicateCities() throws {
        let json = """
        {"schemaVersion":1,"destinations":[\(city),\(city)]}
        """
        #expect(throws: DestinationCatalog.ValidationError.duplicateID("jp-kyoto")) {
            try DestinationCatalog.decode(Data(json.utf8))
        }
    }

    @Test func rejectsUnsupportedSchema() throws {
        #expect(throws: DestinationCatalog.ValidationError.unsupportedVersion) {
            try DestinationCatalog.decode(data(version: 2))
        }
    }

    @Test func rejectsInvalidTimeZone() throws {
        let invalid = String(decoding: data(), as: UTF8.self)
            .replacingOccurrences(of: "Asia/Tokyo", with: "Unknown/City")
        #expect(throws: DestinationCatalog.ValidationError.invalidDestination("jp-kyoto")) {
            try DestinationCatalog.decode(Data(invalid.utf8))
        }
    }

    @Test func decodesCoverAttribution() throws {
        let cover = """
        {"assetName":"CoverKyoto","fileName":"jp-kyoto.jpg","attribution":{
        "creator":"Example Photographer","sourceURL":"https://example.com/photo",
        "license":"Example license","credit":"Photo: Example Photographer"}}
        """
        let json = String(decoding: data(), as: UTF8.self)
            .replacingOccurrences(of: "\"cover\":null", with: "\"cover\":\(cover)")
        let catalog = try DestinationCatalog.decode(Data(json.utf8))
        #expect(catalog.destinations.first?.cover?.assetName == "CoverKyoto")
        #expect(catalog.destinations.first?.cover?.attribution.creator == "Example Photographer")
    }

    @Test func rejectsIncompleteAttribution() throws {
        let cover = """
        {"assetName":"CoverKyoto","fileName":"jp-kyoto.jpg","attribution":{
        "creator":"","sourceURL":"https://example.com/photo","license":"","credit":""}}
        """
        let json = String(decoding: data(), as: UTF8.self)
            .replacingOccurrences(of: "\"cover\":null", with: "\"cover\":\(cover)")
        #expect(throws: DestinationCatalog.ValidationError.invalidCover("jp-kyoto")) {
            try DestinationCatalog.decode(Data(json.utf8))
        }
    }

    @Test func symbolsAndDemoAssetsAreBundled() {
        let symbols = TripTab.allCases.map(\.symbol) + TripSection.allCases.map(\.symbol)
            + ["person.crop.circle.fill", "person.2.fill", "globe", "suitcase"]
        for symbol in symbols {
            #expect(UIImage(systemName: symbol) != nil, "Missing symbol: \(symbol)")
        }
        #expect(UIImage(named: "DemoCoverParis") != nil)
        #expect(UIImage(named: "DemoCoverKyoto") != nil)
        #expect(UIImage(named: "UnregisteredDestinationCover") == nil)
    }

    private var city: String {
        """
        {"id":"jp-kyoto","displayName":"京都","countryCode":"JP",
        "timeZoneIdentifier":"Asia/Tokyo","cover":null}
        """
    }

    private func data(version: Int = 1) -> Data {
        Data("""
        {"schemaVersion":\(version),"destinations":[\(city)]}
        """.utf8)
    }
}
