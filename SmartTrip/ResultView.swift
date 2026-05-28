import SwiftUI

struct ResultView: View {
    let destination: String
    let days: String
    let lodgingStatus: String
    let lodgingArea: String
    let preferences: [String]

    @State private var dayAdjustmentModes: [Int: AdjustmentMode] = [:]

    private enum AdjustmentMode: String {
        case standard = "标准行程"
        case rain = "下雨了"
        case late = "起晚了"
        case tired = "太累了"
        case shopping = "想购物"
        case photo = "想拍照"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryHeader
                lodgingCard
                placeCategoryCard
                itineraryCard
            }
            .padding(20)
        }
        .navigationTitle("结果")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("\(destination) \(days) 日方案")
                .font(.largeTitle)
                .fontWeight(.bold)

            HStack(spacing: 10) {
                summaryPill("强度适中")
                summaryPill("每日可调整")
                summaryPill(preferences.first ?? "自由行")
            }

            HStack(spacing: 12) {
                metricBox(title: "行程天数", value: "\(days) 天")
                metricBox(title: "主要路线", value: "3 条")
                metricBox(title: "优先地点", value: "\(SampleTripData.mustGoPlaces.count) 个")
            }
        }
        .padding(.bottom, 4)
    }

    private var lodgingCard: some View {
        sectionCard(title: "住宿建议", accent: .blue) {
            if lodgingStatus == "decided" {
                Text("\(lodgingArea.isEmpty ? "当前住宿区域" : lodgingArea)：适合")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("交通方便，适合围绕你的攻略地点生成路线。")
                    .foregroundStyle(.secondary)
            } else {
                Text(SampleTripData.lodgingAdvice.title)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(SampleTripData.lodgingAdvice.summary)
                    .foregroundStyle(.secondary)
            }

            bulletList(SampleTripData.lodgingAdvice.reasons)

            if lodgingStatus == "recommend" {
                Divider()
                Text("备选区域")
                    .font(.headline)
                ForEach(SampleTripData.lodgingAdvice.backupAreas) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text(item.area)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                            .frame(width: 44, alignment: .leading)
                        Text(item.reason)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var placeCategoryCard: some View {
        sectionCard(title: "地点分类", accent: .green) {
            placeList(title: "必去", places: SampleTripData.mustGoPlaces, color: .green)
            Divider()
            placeList(title: "可选", places: SampleTripData.optionalPlaces, color: .orange)
            Divider()
            placeList(title: "舍弃", places: SampleTripData.skippedPlaces, color: .gray)
        }
    }

    private var itineraryCard: some View {
        sectionCard(title: "每日行程", accent: .purple) {
            ForEach(SampleTripData.days) { day in
                dayCard(day)

                if day.day != SampleTripData.days.last?.day {
                    Spacer(minLength: 2)
                }
            }
        }
    }

    private func sectionCard<Content: View>(title: String, accent: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(accent)
                    .frame(width: 4, height: 18)

                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func bulletList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundStyle(.blue)
                    Text(item)
                        .font(.subheadline)
                }
            }
        }
    }

    private func placeList(title: String, places: [PlaceItem], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(color.opacity(0.14))
                .foregroundStyle(color)
                .clipShape(Capsule())

            ForEach(places) { place in
                VStack(alignment: .leading, spacing: 3) {
                    Text(place.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(place.reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func dayCard(_ day: DayPlan) -> some View {
        let mode = adjustmentMode(for: day)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Day \(day.day)")
                    .font(.headline)
                Spacer()
                Text(mode == .standard ? day.intensity : mode.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.purple.opacity(0.12))
                    .foregroundStyle(.purple)
                    .clipShape(Capsule())
            }

            Text(adjustedRoute(for: day, mode: mode))
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack(spacing: 10) {
                compactMetric("交通", day.transportTime)
                compactMetric("步数", day.steps)
            }

            Text(adjustedAdvice(for: day, mode: mode))
                .font(.subheadline)

            Text("调整说明：\(adjustedAlternative(for: day, mode: mode))")
                .font(.subheadline)
                .foregroundStyle(.blue)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("调整这一天")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 76))], spacing: 8) {
                    adjustmentButton("标准版", mode: .standard, day: day)
                    adjustmentButton("下雨了", mode: .rain, day: day)
                    adjustmentButton("起晚了", mode: .late, day: day)
                    adjustmentButton("太累了", mode: .tired, day: day)
                    adjustmentButton("想购物", mode: .shopping, day: day)
                    adjustmentButton("想拍照", mode: .photo, day: day)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.16), lineWidth: 1)
        )
    }

    private func summaryPill(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .foregroundStyle(.blue)
            .clipShape(Capsule())
    }

    private func metricBox(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func compactMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    private func adjustmentMode(for day: DayPlan) -> AdjustmentMode {
        dayAdjustmentModes[day.day, default: .standard]
    }

    private func adjustedRoute(for day: DayPlan, mode: AdjustmentMode) -> String {
        switch mode {
        case .standard:
            return day.route
        case .rain:
            switch day.day {
            case 1: return "浅草寺 -> 东京晴空塔商场 -> 银座"
            case 2: return "筑地市场 -> 涩谷商场区"
            default: return "明治神宫短停 -> 代官山咖啡 -> 新宿"
            }
        case .late:
            switch day.day {
            case 1: return "浅草寺 -> 东京晴空塔"
            case 2: return "筑地市场 -> 涩谷"
            default: return "代官山 -> 新宿"
            }
        case .tired:
            switch day.day {
            case 1: return "浅草寺 -> 东京晴空塔"
            case 2: return "涩谷周边慢逛"
            default: return "新宿附近活动"
            }
        case .shopping:
            switch day.day {
            case 1: return "浅草寺 -> 东京晴空塔 -> 银座购物"
            case 2: return "筑地市场 -> 涩谷购物"
            default: return "代官山 -> 新宿购物"
            }
        case .photo:
            switch day.day {
            case 1: return "浅草寺 -> 东京晴空塔夜景"
            case 2: return "筑地市场 -> 东京塔外拍 -> 涩谷路口"
            default: return "明治神宫 -> 代官山街拍"
            }
        }
    }

    private func adjustedAdvice(for day: DayPlan, mode: AdjustmentMode) -> String {
        switch mode {
        case .standard:
            return day.advice
        case .rain:
            return "尽量把户外步行压缩到换乘和短暂停留，优先选择有室内空间的地点。"
        case .late:
            return "从中午开始也能走完，先去最核心地点，不再追求打卡数量。"
        case .tired:
            return "今天以少换乘、少步行为优先，保留一个主目标就够了。"
        case .shopping:
            return "把晚上时间留给商场和街区，不要把购物安排得太碎。"
        case .photo:
            return "优先卡傍晚和夜景时间，减少普通购物点停留。"
        }
    }

    private func adjustedAlternative(for day: DayPlan, mode: AdjustmentMode) -> String {
        switch mode {
        case .standard:
            return day.easyAlternative
        case .rain:
            return "如果雨很大，就把户外点缩短，只保留室内商场、咖啡和观景。"
        case .late:
            return "直接删除当天最后一个地点，把节奏放慢。"
        case .tired:
            return "只留住宿区域附近的一个核心活动，其他地点改成下次。"
        case .shopping:
            return "删掉一个景点，把时间让给涩谷、新宿或银座。"
        case .photo:
            return "只保留最出片的路线，把普通逛街点后移。"
        }
    }

    private func adjustmentButton(_ title: String, mode: AdjustmentMode, day: DayPlan) -> some View {
        let isSelected = adjustmentMode(for: day) == mode

        return Button {
            dayAdjustmentModes[day.day] = mode
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.blue : Color.blue.opacity(0.12))
                .foregroundStyle(isSelected ? Color.white : Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ResultView(
                destination: "东京",
                days: "3",
                lodgingStatus: "recommend",
                lodgingArea: "",
                preferences: ["美食", "购物", "拍照", "轻松"]
            )
        }
    }
}
