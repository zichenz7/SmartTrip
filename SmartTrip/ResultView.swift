//
//  ResultView.swift
//  SmartTrip
//
//  Created by 竺子宸 on 2026/5/27.
//

import SwiftUI

struct ResultView: View {
    let destination: String
    let days: String
    let lodgingStatus: String
    let lodgingArea: String
    let preferences: [String]

    @State private var adjustmentMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("\(destination) \(days) 日方案")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                lodgingCard
                placeCategoryCard
                itineraryCard
                adjustmentCard
            }
            .padding(20)
        }
        .navigationTitle("结果")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var lodgingCard: some View {
        sectionCard(title: "住宿建议") {
            if lodgingStatus == "decided" {
                Text("\(lodgingArea.isEmpty ? "当前住宿区域" : lodgingArea)：适合")
                    .font(.headline)
                Text("交通方便，适合围绕你的攻略地点生成路线。")
                    .foregroundStyle(.secondary)
            } else {
                Text(SampleTripData.lodgingAdvice.title)
                    .font(.headline)
                Text(SampleTripData.lodgingAdvice.summary)
                    .foregroundStyle(.secondary)
            }

            bulletList(SampleTripData.lodgingAdvice.reasons)

            if lodgingStatus == "recommend" {
                Divider()
                Text("备选区域")
                    .font(.headline)
                ForEach(SampleTripData.lodgingAdvice.backupAreas) { item in
                    Text("\(item.area)：\(item.reason)")
                        .font(.subheadline)
                }
            }
        }
    }

    private var placeCategoryCard: some View {
        sectionCard(title: "地点分类") {
            placeList(title: "必去", places: SampleTripData.mustGoPlaces)
            Divider()
            placeList(title: "可选", places: SampleTripData.optionalPlaces)
            Divider()
            placeList(title: "舍弃", places: SampleTripData.skippedPlaces)
        }
    }

    private var itineraryCard: some View {
        sectionCard(title: "每日行程") {
            ForEach(SampleTripData.days) { day in
                VStack(alignment: .leading, spacing: 8) {
                    Text("Day \(day.day)")
                        .font(.headline)
                    Text(day.route)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("强度：\(day.intensity)  交通：\(day.transportTime)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("步数：\(day.steps)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("建议：\(day.advice)")
                        .font(.subheadline)
                    Text("轻松替代：\(day.easyAlternative)")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }

                if day.day != SampleTripData.days.last?.day {
                    Divider()
                }
            }
        }
    }

    private var adjustmentCard: some View {
        sectionCard(title: "一键调整") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92))], spacing: 10) {
                adjustmentButton("下雨了", message: "已切换为下雨思路：优先安排银座、涩谷、东京晴空塔等室内区域。")
                adjustmentButton("起晚了", message: "已切换为起晚思路：删掉最远或优先级最低的地点。")
                adjustmentButton("太累了", message: "已切换为轻松思路：留在住宿区域附近，只保留一个主要地点。")
                adjustmentButton("想购物", message: "已切换为购物思路：优先安排涩谷、新宿和银座。")
                adjustmentButton("想拍照", message: "已切换为拍照思路：优先安排浅草寺、东京晴空塔和代官山。")
            }

            if !adjustmentMessage.isEmpty {
                Text(adjustmentMessage)
                    .font(.subheadline)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
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
                Text("- \(item)")
                    .font(.subheadline)
            }
        }
    }

    private func placeList(title: String, places: [PlaceItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            ForEach(places) { place in
                Text("\(place.name)：\(place.reason)")
                    .font(.subheadline)
            }
        }
    }

    private func adjustmentButton(_ title: String, message: String) -> some View {
        Button {
            adjustmentMessage = message
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.12))
                .foregroundStyle(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

#Preview {
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
