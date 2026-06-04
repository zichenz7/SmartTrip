import SwiftUI

struct ResultView: View {
    let destination: String
    let days: String
    let lodgingStatus: String
    let lodgingArea: String
    let travelType: String
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
                foodCard
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
            Text("\(destination) \(days) 日行程")
                .font(.largeTitle)
                .fontWeight(.bold)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 8)], alignment: .leading, spacing: 8) {
                summaryPill("每日可调整")
                if !trimmedTravelType.isEmpty {
                    summaryPill(trimmedTravelType)
                }
                ForEach(displayedPreferences, id: \.self) { preference in
                    summaryPill(preference)
                }
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
        let cleanedPreferences = preferences
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return cleanedPreferences.isEmpty ? ["自由行"] : Array(Set(cleanedPreferences)).sorted()
    }

    private var trimmedTravelType: String {
        travelType.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var foodRecommendations: [PlaceItem] {
        let explicitFoodPlaces = plan.foodPlaces ?? []
        let inferredFoodPlaces = (plan.mustGoPlaces + plan.optionalPlaces)
            .filter { isFoodPlace($0) }

        return uniquePlaces(explicitFoodPlaces + inferredFoodPlaces)
    }

    private var foodPlaceNames: Set<String> {
        Set(foodRecommendations.map(\.name))
    }

    private var scenicMustGoPlaces: [PlaceItem] {
        plan.mustGoPlaces.filter { !foodPlaceNames.contains($0.name) && !isFoodPlace($0) }
    }

    private var scenicOptionalPlaces: [PlaceItem] {
        plan.optionalPlaces.filter { !foodPlaceNames.contains($0.name) && !isFoodPlace($0) }
    }

    private var scenicSkippedPlaces: [PlaceItem] {
        plan.skippedPlaces.filter { !foodPlaceNames.contains($0.name) && !isFoodPlace($0) }
    }

    private var foodCard: some View {
        sectionCard(title: "美食推荐", accent: .orange) {
            if foodRecommendations.isEmpty {
                Text("暂未识别到明确的美食地点。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(foodRecommendations) { place in
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
    }

    private var placeCategoryCard: some View {
        sectionCard(title: "地点分类", accent: .green) {
            placeList(title: "必去", places: scenicMustGoPlaces, color: .green)
            Divider()
            placeList(title: "可选", places: scenicOptionalPlaces, color: .orange)
            Divider()
            placeList(title: "舍弃", places: scenicSkippedPlaces, color: .gray)
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

    private func isFoodPlace(_ place: PlaceItem) -> Bool {
        let text = "\(place.name) \(place.reason)"
        let foodKeywords = [
            "餐", "饭", "吃", "美食", "小吃", "早餐", "午餐", "晚餐",
            "咖啡", "甜品", "海鲜", "汉堡", "市场", "夜市", "居酒屋",
            "拉面", "寿司", "烤肉", "冰淇淋", "蛋堡"
        ]

        return foodKeywords.contains { text.contains($0) }
    }

    private func uniquePlaces(_ places: [PlaceItem]) -> [PlaceItem] {
        var seenNames: Set<String> = []

        return places.filter { place in
            if seenNames.contains(place.name) {
                return false
            }

            seenNames.insert(place.name)
            return true
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
                    if !shouldOnlyShowStandardButton(for: day) {
                        adjustmentButton("下雨了", mode: .rain, day: day)
                        if shouldShowLateButton(for: day) {
                            adjustmentButton("起晚了", mode: .late, day: day)
                        }
                        adjustmentButton("太累了", mode: .tired, day: day)
                        adjustmentButton("想购物", mode: .shopping, day: day)
                        adjustmentButton("想拍照", mode: .photo, day: day)
                    }
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
        let mode = dayAdjustmentModes[day.day, default: .standard]
        if shouldOnlyShowStandardButton(for: day) {
            return .standard
        }

        if mode == .late && !shouldShowLateButton(for: day) {
            return .standard
        }

        return mode
    }

    private func shouldOnlyShowStandardButton(for day: DayPlan) -> Bool {
        isPureArrivalDay(day) || isPureDepartureDay(day)
    }

    private func isPureArrivalDay(_ day: DayPlan) -> Bool {
        guard day.day == 1 else {
            return false
        }

        if isHotelAirportOnlyRoute(day.route) {
            return true
        }

        let text = "\(day.route) \(day.advice) \(day.easyAlternative)"
        let hasAirport = containsAirportSignal(text)
        let hasHotel = containsHotelSignal(text)
        let placeCount = routePlaces(from: day.route).count
        let hasExtraActivity = containsNonTransferActivitySignal(text)

        return hasAirport && hasHotel && placeCount <= 2 && !hasExtraActivity
    }

    private func isPureDepartureDay(_ day: DayPlan) -> Bool {
        guard day.day == plan.days.last?.day else {
            return false
        }

        if isHotelAirportOnlyRoute(day.route) {
            return true
        }

        let text = "\(day.route) \(day.advice) \(day.easyAlternative)"
        let hasAirport = containsAirportSignal(text)
        let placeCount = routePlaces(from: day.route).count
        let hasExtraActivity = containsNonTransferActivitySignal(text)

        return hasAirport && placeCount <= 2 && !hasExtraActivity
    }

    private func containsAirportSignal(_ text: String) -> Bool {
        ["机场", "航班", "登机", "离境", "出境", "入境", "落地", "抵达", "到达"].contains { text.contains($0) }
    }

    private func containsHotelSignal(_ text: String) -> Bool {
        ["酒店", "住宿", "入住", "check-in", "Check-in", "check in", "Check in"].contains { text.contains($0) }
    }

    private func isHotelAirportOnlyRoute(_ route: String) -> Bool {
        let places = routePlaces(from: route)
        guard places.count == 2 else {
            return false
        }

        let first = places[0]
        let second = places[1]
        return (containsHotelSignal(first) && containsAirportSignal(second))
            || (containsAirportSignal(first) && containsHotelSignal(second))
    }

    private func containsNonTransferActivitySignal(_ text: String) -> Bool {
        [
            "景点", "公园", "花园", "博物馆", "美术馆", "商场", "购物", "市场", "市集",
            "海滩", "沙滩", "灯光秀", "夜景", "拍照", "游览", "逛"
        ].contains { text.contains($0) }
    }

    private func shouldShowLateButton(for day: DayPlan) -> Bool {
        let text = "\(day.route) \(day.advice) \(day.easyAlternative)"
        let arrivalKeywords = [
            "机场", "入境", "抵达", "到达", "落地", "航班",
            "check-in", "Check-in", "入住", "酒店"
        ]

        let looksLikeArrivalDay = day.day == 1 && arrivalKeywords.contains { text.contains($0) }
        return !looksLikeArrivalDay
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
        if let adjustment = adjustmentData(for: day, mode: mode),
           isUsableAdjustment(adjustment, for: day) {
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

        if mode != .standard {
            return fallbackDisplayPlan(for: day, mode: mode)
        }

        let standardNote = shouldOnlyShowStandardButton(for: day)
            ? "这一天主要是机场和酒店之间的移动，不需要临时调整。"
            : "当前为标准行程。下面的按钮可以按临时状态切换这一天的路线。"

        return DayDisplayPlan(
            route: day.route,
            intensity: day.intensity,
            transportTime: day.transportTime,
            transportDetails: day.transportDetails,
            steps: day.steps,
            advice: day.advice,
            note: standardNote
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

    private func isUsableAdjustment(_ adjustment: DayAdjustment, for day: DayPlan) -> Bool {
        let standardText = normalizedComparisonText(day.route + day.advice)
        let adjustmentText = normalizedComparisonText(adjustment.route + adjustment.advice + adjustment.adjustmentNote)
        let routeChanged = normalizedComparisonText(adjustment.route) != normalizedComparisonText(day.route)
        let hasMeaningfulNote = !adjustment.adjustmentNote.contains("当前为标准行程")

        return !adjustment.route.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !adjustmentText.isEmpty
            && adjustmentText != standardText
            && (routeChanged || hasMeaningfulNote)
    }

    private func normalizedComparisonText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "→", with: "->")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func fallbackDisplayPlan(for day: DayPlan, mode: AdjustmentMode) -> DayDisplayPlan {
        let routePlaces = routePlaces(from: day.route)
        let shortenedPlaces = Array(routePlaces.prefix(max(2, min(routePlaces.count, 3))))
        let route = fallbackRoute(from: routePlaces, shortenedPlaces: shortenedPlaces, mode: mode)
        let details = fallbackTransportDetails(for: route)

        switch mode {
        case .standard:
            return displayPlan(for: day, mode: .standard)
        case .rain:
            return DayDisplayPlan(
                route: route,
                intensity: "轻松",
                transportTime: estimatedTransportTime(for: details),
                transportDetails: details,
                steps: "约6000步",
                advice: "下雨时减少户外停留，优先选择室内景点、商场、咖啡店或酒店附近活动。",
                note: "AI 没有返回可用的下雨方案，App 已自动切换为少户外、少移动的兜底路线。"
            )
        case .late:
            return DayDisplayPlan(
                route: route,
                intensity: "轻松",
                transportTime: estimatedTransportTime(for: details),
                transportDetails: details,
                steps: "约5000步",
                advice: "起晚后不要补齐所有地点，只保留当天最核心的 1-2 个安排，避免后面继续赶路。",
                note: "AI 没有返回可用的起晚方案，App 已自动删减为半日可完成路线。"
            )
        case .tired:
            return DayDisplayPlan(
                route: route,
                intensity: "轻松",
                transportTime: estimatedTransportTime(for: details),
                transportDetails: details,
                steps: "约4000步",
                advice: "今天以恢复体力为主，保留近距离活动，中间留出休息或回酒店时间。",
                note: "AI 没有返回可用的轻松方案，App 已自动减少地点和步行量。"
            )
        case .shopping:
            return DayDisplayPlan(
                route: shoppingFallbackRoute(from: routePlaces),
                intensity: "适中",
                transportTime: estimatedTransportTime(for: details),
                transportDetails: details,
                steps: "约8000步",
                advice: "把当天节奏调整为购物优先，景点只保留顺路或附近的核心点。",
                note: "AI 没有返回可用的购物方案，App 已自动把这一天切换为购物优先。"
            )
        case .photo:
            return DayDisplayPlan(
                route: route,
                intensity: day.intensity,
                transportTime: estimatedTransportTime(for: details),
                transportDetails: details,
                steps: day.steps,
                advice: "今天按拍照优先安排，尽量保留视野好、夜景好或城市特色明显的地点。",
                note: "AI 没有返回可用的拍照方案，App 已自动把这一天切换为拍照优先。"
            )
        }
    }

    private func routePlaces(from route: String) -> [String] {
        route
            .replacingOccurrences(of: "→", with: "->")
            .components(separatedBy: "->")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func fallbackRoute(from places: [String], shortenedPlaces: [String], mode: AdjustmentMode) -> String {
        guard !shortenedPlaces.isEmpty else {
            return "酒店附近轻松活动"
        }

        switch mode {
        case .rain, .late, .tired:
            return shortenedPlaces.joined(separator: " -> ")
        case .shopping:
            return shoppingFallbackRoute(from: places)
        case .photo:
            return places.isEmpty ? shortenedPlaces.joined(separator: " -> ") : places.joined(separator: " -> ")
        case .standard:
            return places.joined(separator: " -> ")
        }
    }

    private func shoppingFallbackRoute(from places: [String]) -> String {
        if let shoppingPlace = places.first(where: { place in
            ["商场", "购物", "市集", "市场", "街", "mall", "Mall"].contains { place.contains($0) }
        }) {
            return shoppingPlace
        }

        return places.prefix(max(1, min(places.count, 2))).joined(separator: " -> ")
    }

    private func fallbackTransportDetails(for route: String) -> [String] {
        let places = routePlaces(from: route)
        guard places.count >= 2 else {
            return ["酒店 -> \(route)：约15分钟", "\(route) -> 酒店：约15分钟"]
        }

        return zip(places, places.dropFirst()).map { start, end in
            "\(start) -> \(end)：约15分钟"
        }
    }

    private func estimatedTransportTime(for details: [String]) -> String {
        let totalMinutes = max(details.count * 15, 15)
        if totalMinutes < 60 {
            return "约\(totalMinutes)分钟"
        }

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return minutes == 0 ? "约\(hours)小时" : "约\(hours)小时\(minutes)分钟"
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
                travelType: "情侣游",
                preferences: ["美食", "购物", "拍照", "轻松"],
                tripPlan: SampleTripData.tripPlan
            )
        }
    }
}
