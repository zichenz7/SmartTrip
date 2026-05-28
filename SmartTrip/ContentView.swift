import SwiftUI

struct ContentView: View {
    @State private var destination = "东京"
    @State private var days = "3"
    @State private var lodgingStatus = "recommend"
    @State private var lodgingArea = ""
    @State private var selectedPreferences: Set<String> = ["美食", "购物", "拍照", "轻松"]
    @State private var showPasteGuide = false


    private let preferences = ["美食", "购物", "拍照", "轻松", "不想太赶"]

    private var trimmedDestination: String {
        destination.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDays: String {
        days.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedLodgingArea: String {
        lodgingArea.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isFormValid: Bool {
        !trimmedDestination.isEmpty
        && !trimmedDays.isEmpty
        && (lodgingStatus == "recommend" || !trimmedLodgingArea.isEmpty)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("新建旅行")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    inputSection(
                        title: "目的地",
                        placeholder: "例如：东京",
                        text: $destination,
                        validationMessage: trimmedDestination.isEmpty ? "请输入目的地" : nil
                    )
                    inputSection(
                        title: "天数",
                        placeholder: "例如：3",
                        text: $days,
                        validationMessage: trimmedDays.isEmpty ? "请输入旅行天数" : nil
                    )
                    .keyboardType(.numberPad)
                    .onChange(of: days) { _, newValue in
                        days = newValue.filter { $0.isNumber }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("住宿状态")
                            .font(.headline)

                        Picker("住宿状态", selection: $lodgingStatus) {
                            Text("已决定").tag("decided")
                            Text("帮我推荐").tag("recommend")
                        }
                        .pickerStyle(.segmented)

                        if lodgingStatus == "decided" {
                            TextField("例如：新宿", text: $lodgingArea)
                                .textFieldStyle(.roundedBorder)

                            if trimmedLodgingArea.isEmpty {
                                validationText("请输入住宿区域")
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("旅行偏好")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92))], spacing: 12) {
                            ForEach(preferences, id: \.self) { preference in
                                preferenceButton(preference)
                            }
                        }
                    }

                    Button {
                        showPasteGuide = true
                    } label: {
                        Text("下一步")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray.opacity(0.35))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!isFormValid)
                    .padding(.top, 8)
                    .navigationDestination(isPresented: $showPasteGuide) {
                        PasteGuideView(
                            destination: trimmedDestination,
                            days: trimmedDays,
                            lodgingStatus: lodgingStatus,
                            lodgingArea: trimmedLodgingArea,
                            preferences: Array(selectedPreferences).sorted()
                        )
                    }
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func inputSection(
        title: String,
        placeholder: String,
        text: Binding<String>,
        validationMessage: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)

            if let validationMessage {
                validationText(validationMessage)
            }
        }
    }

    private func validationText(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.red)
    }

    private func preferenceButton(_ preference: String) -> some View {
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
                .background(selectedPreferences.contains(preference) ? Color.blue.opacity(0.15) : Color.gray.opacity(0.12))
                .foregroundStyle(selectedPreferences.contains(preference) ? Color.blue : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
