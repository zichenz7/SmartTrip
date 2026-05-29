import SwiftUI

struct ResultView: View {
    let destination: String
    let days: String
    let lodgingStatus: String
    let lodgingArea: String
    let preferences: [String]
    let tripPlan: TripPlan?

    @State private var dayAdjustmentModes: [Int: AdjustmentMode] = [:]
    @State private var expandedTransportDays: Set<Int> = []

    private var plan: TripPlan {
        tripPlan ?? SampleTripData.tripPlan
    }

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

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 8)], alignment: .leading, spacing: 8) {
                summaryPill("强度适中")
                summaryPill("每日可调整")
                ForEach(displayedPreferences, id: \.self) { preference in
                    summaryPill(preference)
                }
            }

            HStack(spacing: 12) {
                metricBox(title: "行程天数", value: "\(days) 天")
                metricBox(title: "主要路线", value: "3 条")
                metricBox(title: "优先地点", value: "\(plan.mustGoPlaces.count) 个")
            }
        }
        .padding(.bottom, 4)
    }

    private var lodgingCard: some View {
        sectionCard(title: "住宿建议", accent: .blue) {
            Text(plan.lodgingAdvice.title)
                .font(.title3)
                .fontWeight(.bold)
            Text(plan.lodgingAdvice.summary)
                .foregroundStyle(.secondary)

            bulletList(plan.lodgingAdvice.reasons)

            if lodgingStatus == "recommend" {
                Divider()
                Text("备选区域")
                    .font(.headline)
                ForEach(plan.lodgingAdvice.backupAreas) { item in
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

    private var displayedPreferences: [String] {
        preferences.isEmpty ? ["自由行"] : preferences
    }

    private var placeCategoryCard: some View {
        sectionCard(title: "地点分类", accent: .green) {
            placeList(title: "必去", places: plan.mustGoPlaces, color: .green)
            Divider()
            placeList(title: "可选", places: plan.optionalPlaces, color: .orange)
            Divider()
            placeList(title: "舍弃", places: plan.skippedPlaces, color: .gray)
        }
    }

    private var itineraryCard: some View {
        sectionCard(title: "每日行程", accent: .purple) {
            ForEach(plan.days) { day in
                dayCard(day)

                if day.day != plan.days.last?.day {
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
        let display = displayPlan(for: day, mode: mode)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Day \(day.day)")
                    .font(.headline)
                Spacer()
                Text(mode == .standard ? display.intensity : mode.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.purple.opacity(0.12))
                    .foregroundStyle(.purple)
                    .clipShape(Capsule())
            }

            Text(display.route)
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack(spacing: 10) {
                compactMetric("交通", display.transportTime)
                compactMetric("步数", display.steps)
            }

            Button {
                toggleTransportDetails(for: day)
            } label: {
                HStack {
                    Text(isTransportExpanded(for: day) ? "收起交通详情" : "查看交通详情")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: isTransportExpanded(for: day) ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .padding(10)
                .background(Color.orange.opacity(0.1))
                .foregroundStyle(.orange)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if isTransportExpanded(for: day) {
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(display.transportDetails, id: \.self) { detail in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundStyle(.orange)
                            Text(detail)
                                .font(.caption)
                        }
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Text(display.advice)
                .font(.subheadline)

            Text("\(mode == .standard ? "当前说明" : "调整说明")：\(display.note)")
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

    private struct DayDisplayPlan {
        let route: String
        let intensity: String
        let transportTime: String
        let transportDetails: [String]
        let steps: String
        let advice: String
        let note: String
    }

    private func displayPlan(for day: DayPlan, mode: AdjustmentMode) -> DayDisplayPlan {
        if let adjustment = adjustmentData(for: day, mode: mode) {
            return DayDisplayPlan(
                route: adjustment.route,
                intensity: adjustment.intensity,
                transportTime: adjustment.transportTime,
                transportDetails: adjustment.transportDetails,
                steps: adjustment.steps,
                advice: adjustment.advice,
                note: adjustment.adjustmentNote
            )
        }

        return DayDisplayPlan(
            route: day.route,
            intensity: day.intensity,
            transportTime: day.transportTime,
            transportDetails: day.transportDetails,
            steps: day.steps,
            advice: day.advice,
            note: "当前为标准行程。下面的按钮可以按临时状态切换这一天的路线。"
        )
    }

    private func isTransportExpanded(for day: DayPlan) -> Bool {
        expandedTransportDays.contains(day.day)
    }

    private func toggleTransportDetails(for day: DayPlan) {
        if expandedTransportDays.contains(day.day) {
            expandedTransportDays.remove(day.day)
        } else {
            expandedTransportDays.insert(day.day)
        }
    }

    private func adjustmentData(for day: DayPlan, mode: AdjustmentMode) -> DayAdjustment? {
        guard let adjustments = day.adjustments else {
            return nil
        }

        switch mode {
        case .standard:
            return nil
        case .rain:
            return adjustments.rain
        case .late:
            return adjustments.late
        case .tired:
            return adjustments.tired
        case .shopping:
            return adjustments.shopping
        case .photo:
            return adjustments.photo
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
                preferences: ["美食", "购物", "拍照", "轻松"],
                tripPlan: SampleTripData.tripPlan
            )
        }
    }
}
