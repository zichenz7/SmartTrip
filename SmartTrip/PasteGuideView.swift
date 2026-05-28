import SwiftUI

struct PasteGuideView: View {
    let destination: String
    let days: String
    let lodgingStatus: String
    let lodgingArea: String
    let preferences: [String]

    @State private var showResult = false
    @State private var guideText = """
东京三日游攻略：浅草寺、晴空塔、筑地市场、东京塔、涩谷、明治神宫、代官山都很值得去。想吃海鲜可以去筑地，想购物可以去涩谷和银座。
"""

    private var canGenerateTrip: Bool {
        !guideText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("粘贴攻略")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("粘贴一篇你收藏的旅行攻略，AI 会帮你整理地点、推荐住宿区域，并生成行程。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextEditor(text: $guideText)
                    .frame(minHeight: 260)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if !canGenerateTrip {
                    Text("请先粘贴一篇攻略")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    showResult = true
                } label: {
                    Text("生成行程")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canGenerateTrip ? Color.blue : Color.gray.opacity(0.35))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canGenerateTrip)
                .navigationDestination(isPresented: $showResult) {
                    ResultView(
                        destination: destination,
                        days: days,
                        lodgingStatus: lodgingStatus,
                        lodgingArea: lodgingArea,
                        preferences: preferences
                    )
                }
            }
            .padding(24)
        }
        .navigationTitle("攻略")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PasteGuideView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PasteGuideView(
                destination: "东京",
                days: "3",
                lodgingStatus: "recommend",
                lodgingArea: "",
                preferences: ["美食", "购物", "拍照", "轻松"]
            )
        }
    }
}
