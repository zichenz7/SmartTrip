//
//  ContentView.swift
//  SmartTrip
//
//  Created by Joe on 2026/5/27.
//

import SwiftUI



struct ContentView: View {
    @State private var destination = "东京"
        @State private var days = "3"
        @State private var lodgingStatus = "recommend"
        @State private var lodgingArea = ""
        @State private var selectedPreferences: Set<String> = ["美食", "购物", "拍照", "轻松"]

        let preferences = ["美食", "购物", "拍照", "轻松"]
    var body: some View {
        NavigationStack {
                   ScrollView {
                       VStack(alignment: .leading, spacing: 24) {
                           Text("新建旅行")
                               .font(.largeTitle)
                               .fontWeight(.bold)

                           VStack(alignment: .leading, spacing: 12) {
                               Text("目的地")
                                   .font(.headline)

                               TextField("例如：东京", text: $destination)
                                   .textFieldStyle(.roundedBorder)
                           }

                           VStack(alignment: .leading, spacing: 12) {
                               Text("天数")
                                   .font(.headline)

                               TextField("例如：3", text: $days)
                                   .textFieldStyle(.roundedBorder)
                                   .keyboardType(.numberPad)
                           }

                           VStack(alignment: .leading, spacing: 12) {
                               Text("住宿状态")
                                   .font(.headline)

                               Picker("住宿状态", selection: $lodgingStatus) {
                                   Text("我已经订好/决定住宿位置").tag("decided")
                                   Text("我还没决定，帮我推荐").tag("recommend")
                               }
                               .pickerStyle(.segmented)

                               if lodgingStatus == "decided" {
                                   TextField("例如：新宿", text: $lodgingArea)
                                       .textFieldStyle(.roundedBorder)
                               }
                           }

                           VStack(alignment: .leading, spacing: 12) {
                               Text("旅行偏好")
                                   .font(.headline)

                               LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 12) {
                                   ForEach(preferences, id: \.self) { preference in
                                       Button {
                                           if selectedPreferences.contains(preference) {
                                               selectedPreferences.remove(preference)
                                           } else {
                                               selectedPreferences.insert(preference)
                                           }
                                       } label: {
                                           Text(preference)
                                               .font(.subheadline)
                                               .fontWeight(.medium)
                                               .frame(maxWidth: .infinity)
                                               .padding(.vertical, 10)
                                               .background(
                                                   selectedPreferences.contains(preference)
                                                   ? Color.blue.opacity(0.15)
                                                   : Color.gray.opacity(0.12)
                                               )
                                               .foregroundStyle(
                                                   selectedPreferences.contains(preference)
                                                   ? Color.blue
                                                   : Color.primary
                                               )
                                               .clipShape(RoundedRectangle(cornerRadius: 10))
                                       }
                                   }
                               }
                           }

                           NavigationLink {
                               PasteGuideView(
                                       destination: destination,
                                       days: days,
                                       lodgingStatus: lodgingStatus,
                                       lodgingArea: lodgingArea,
                                       preferences: Array(selectedPreferences).sorted()
                                   )
                           } label: {
                               Text("下一步")
                                   .font(.headline)
                                   .frame(maxWidth: .infinity)
                                   .padding()
                                   .background(Color.blue)
                                   .foregroundStyle(.white)
                                   .clipShape(RoundedRectangle(cornerRadius: 14))
                           }
                           .padding(.top, 12)
                       }
                       .padding(24)
                   }
               }
    }
}

#Preview {
    ContentView()
}
