import SwiftUI
import UIKit

struct SwitchGameRowView: View {
    let name: String
    let bundleID: String
    let icon: UIImage?
    let isInstalled: Bool

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let icon {
                    Image(uiImage: icon)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white.opacity(0.4))
                        )
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    Circle()
                        .fill(isInstalled ? Color.green : Color.orange)
                        .frame(width: 7, height: 7)
                    Text(isInstalled ? "Mở cùng menu patch" : "Chưa cài đặt")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(isInstalled ? Color.green.opacity(0.2) : Color.white.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: "play.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isInstalled ? .green : .white.opacity(0.3))
            }

            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 36, height: 36)
                Text("DS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.blue)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }
}
