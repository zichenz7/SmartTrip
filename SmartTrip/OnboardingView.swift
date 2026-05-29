import SwiftUI

struct OnboardingView: View {
    private let steps = [
        OnboardingStep(
            iconName: "1.circle.fill",
            title: "填写旅行基础信息",
            description: "先输入目的地、旅行天数、住宿状态和偏好。住宿已经定好时，建议填具体区域，AI 会围绕这个位置规划。"
        ),
        OnboardingStep(
            iconName: "2.circle.fill",
            title: "粘贴你收藏的攻略",
            description: "把小红书、公众号、网页里看到的攻略文字粘进来。内容越具体，AI 越容易识别景点、美食、购物和拍照点。"
        ),
        OnboardingStep(
            iconName: "3.circle.fill",
            title: "生成结构化行程",
            description: "点击生成后，AI 会整理住宿建议、地点分类、每日路线、交通时间和步数，不用自己从长攻略里慢慢筛。"
        ),
        OnboardingStep(
            iconName: "4.circle.fill",
            title: "按当天情况一键调整",
            description: "到结果页后，每一天都可以单独切换下雨、起晚、太累、购物、拍照等版本，不会影响其他天。"
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("新手使用教学")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("按照下面 4 步走，就能从一篇普通旅行攻略生成可调整的每日行程。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(steps) { step in
                        stepCard(step)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("使用小提示")
                        .font(.title3)
                        .fontWeight(.bold)

                    tipRow("如果已经订好酒店，住宿区域要尽量写清楚，例如 Newport Beach、新宿、银座。")
                    tipRow("攻略里可以同时包含景点、美食、商场和拍照点，AI 会自动分类。")
                    tipRow("结果页的交通时间是估算值，适合先做路线判断，实际出行前还要用地图确认。")
                }
                .padding(16)
                .background(Color.blue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(24)
        }
        .navigationTitle("教学")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stepCard(_ step: OnboardingStep) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: step.iconName)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 6) {
                Text(step.title)
                    .font(.headline)
                Text(step.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.blue)
                .padding(.top, 3)
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct OnboardingStep: Identifiable {
    let id = UUID()
    let iconName: String
    let title: String
    let description: String
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            OnboardingView()
        }
    }
}
