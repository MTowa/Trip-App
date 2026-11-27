import SwiftUI
import UIKit

/// Display-only inputs. Storage and navigation remain the caller's responsibility.
struct TripCardView: View {
    let destinationName: String
    let dateText: String
    let coverAssetName: String?
    var companionNames: [String] = []
    var startDateText: String? = nil
    var endDateText: String? = nil
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 8) {
            if let startDateText, let endDateText {
                if dynamicTypeSize.isAccessibilitySize {
                    Text(dateText).font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)
                } else {
                    HStack(spacing: 16) {
                        Text(startDateText)
                        Rectangle().fill(.white.opacity(0.65)).frame(height: 1)
                        Text(endDateText)
                    }
                    .font(.caption.weight(.semibold))
                }
            } else {
                Text(dateText)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            Text(destinationName)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            if !companionNames.isEmpty {
                Label(companionNames.formatted(.list(type: .and)), systemImage: "person.2.fill")
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 114)
        .background {
            DestinationCover(assetName: coverAssetName)
                .overlay(.black.opacity(0.50))
        }
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .accessibilityElement(children: .combine)
    }
}

struct PastTripCardView: View {
    let destinationName: String
    let dateText: String
    let coverAssetName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DestinationCover(assetName: coverAssetName)
                .frame(height: 144)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            Text(destinationName)
                .font(.title2.bold())
                .foregroundStyle(.primary)
                .padding(.horizontal, 6)
            Text(dateText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.bottom, 8)
        }
        .padding(7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("TripCardSurface"))
        .clipShape(RoundedRectangle(cornerRadius: 19))
        .accessibilityElement(children: .combine)
    }
}

/// Missing records and missing asset files both fall back to the same cover.
struct DestinationCover: View {
    let assetName: String?

    var body: some View {
        GeometryReader { geometry in
            if let assetName, let image = UIImage(named: assetName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color("TripCoverStart"), Color("TripCoverEnd")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "globe")
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.25))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding()
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct ProfileAvatarView: View {
    var size: CGFloat = 64
    var body: some View {
        Image(systemName: "person.crop.circle.fill")
            .font(.system(size: size))
            .foregroundStyle(.secondary)
            .accessibilityLabel("プロフィール画像未設定")
    }
}
