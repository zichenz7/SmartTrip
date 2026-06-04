import SwiftUI
import PhotosUI
import UIKit
import Vision

struct PasteGuideView: View {
    let destination: String
    let days: String
    let lodgingStatus: String
    let lodgingArea: String
    let travelType: String
    let preferences: [String]

    @State private var showResult = false
    @State private var isGenerating = false
    @State private var generatedPlan: TripPlan?
    @State private var errorMessage = ""
    @State private var inputMode: GuideInputMode = .screenshot
    @State private var generationProgress = 0.0
    @State private var generationStatus = ""
    @State private var guideText = ""
    @State private var recognizedGuideText = ""
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedScreenshots: [UIImage] = []
    @State private var selectedScreenshotTexts: [String] = []
    @State private var isRecognizingText = false
    @State private var previewedScreenshotIndex: Int?
    @State private var isUpdatingPhotoSelection = false

    private enum GuideInputMode: String, CaseIterable, Identifiable {
        case screenshot = "导入截图"
        case paste = "粘贴文字"
        case recommend = "直接推荐"

        var id: String { rawValue }
    }

    private var activeGuideText: String {
        switch inputMode {
        case .screenshot:
            return recognizedGuideText
        case .paste:
            return guideText
        case .recommend:
            return ""
        }
    }

    private var canGenerateTrip: Bool {
        if inputMode == .recommend {
            return true
        }

        return !activeGuideText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isBusy: Bool {
        isGenerating || isRecognizingText
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("导入攻略")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("导入 2-3 篇你喜欢的攻略截图、直接粘贴多篇攻略文字，或者让 AI 根据你的目的地和偏好直接推荐行程。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("导入方式", selection: $inputMode) {
                    ForEach(GuideInputMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(isBusy)

                if inputMode == .screenshot {
                    screenshotInputSection
                } else if inputMode == .paste {
                    TextEditor(text: $guideText)
                        .frame(minHeight: 260)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    directRecommendationSection
                }

                if !canGenerateTrip {
                    Text(inputMode == .screenshot ? "请先选择攻略截图" : "请先粘贴攻略内容")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if isGenerating {
                    generationProgressView
                }

                Button {
                    Task {
                        isGenerating = true
                        generationProgress = 0.08
                        generationStatus = inputMode == .recommend ? "正在理解你的旅行需求" : "正在理解攻略内容"
                        errorMessage = ""
                        generatedPlan = nil
                        let progressTask = Task {
                            await animateGenerationProgress()
                        }

                        do {
                            generatedPlan = try await DeepSeekService().generateTripPlan(
                                destination: destination,
                                days: days,
                                lodgingStatus: lodgingStatus,
                                lodgingArea: lodgingArea,
                                travelType: travelType,
                                preferences: preferences,
                                guideText: activeGuideText
                            )
                            progressTask.cancel()
                            generationProgress = 1.0
                            generationStatus = "行程已生成"
                            showResult = true
                        } catch {
                            progressTask.cancel()
                            errorMessage = generationErrorMessage(for: error)
                        }

                        isGenerating = false
                    }
                } label: {
                    Text(isGenerating ? "生成中..." : "生成行程")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canGenerateTrip && !isBusy ? Color.blue : Color.gray.opacity(0.35))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canGenerateTrip || isBusy)
                .navigationDestination(isPresented: $showResult) {
                    ResultView(
                        destination: destination,
                        days: days,
                        lodgingStatus: lodgingStatus,
                        lodgingArea: lodgingArea,
                        travelType: travelType,
                        preferences: preferences,
                        tripPlan: generatedPlan
                    )
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
            .padding(24)
        }
        .navigationTitle("攻略")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPhotoItems) { _, newItems in
            if isUpdatingPhotoSelection {
                isUpdatingPhotoSelection = false
                return
            }

            Task {
                await loadSelectedScreenshots(newItems)
            }
        }
        .sheet(isPresented: screenshotPreviewBinding) {
            screenshotPreviewSheet
        }
    }

    private var screenshotInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 6, matching: .images) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text(isRecognizingText ? "识别截图中..." : selectedScreenshots.isEmpty ? "选择 2-3 篇攻略截图" : "重新选择攻略截图")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundStyle(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isBusy)

            if !selectedScreenshots.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("已选择 \(selectedScreenshots.count) 张截图，AI 会合并整合")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if !recognizedGuideText.isEmpty {
                            Label("已识别", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }

                    Text("点击图片查看大图，点右上角删除单张。")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(selectedScreenshots.enumerated()), id: \.offset) { index, image in
                                screenshotThumbnail(image: image, index: index)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    HStack(spacing: 12) {
                        PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 6, matching: .images) {
                            Label("编辑图片", systemImage: "pencil")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .disabled(isBusy)

                        Button(role: .destructive) {
                            clearSelectedScreenshots()
                        } label: {
                            Label("清空", systemImage: "trash")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .disabled(isBusy)
                    }
                    .padding(.top, 2)
                }
            }
        }
    }

    private var directRecommendationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 6) {
                    Text("不导入攻略，直接生成")
                        .font(.headline)

                    Text("AI 会根据目的地、天数、住宿状态、旅游类型和旅行偏好，直接推荐一份可执行行程。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func screenshotThumbnail(image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Button {
                previewedScreenshotIndex = index
            } label: {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 92, height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.18), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Button {
                removeSelectedScreenshot(at: index)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Color.black.opacity(0.65))
                    .clipShape(Circle())
            }
            .padding(5)
            .disabled(isBusy)
        }
    }

    private var screenshotPreviewBinding: Binding<Bool> {
        Binding {
            previewedScreenshotIndex != nil
        } set: { isPresented in
            if !isPresented {
                previewedScreenshotIndex = nil
            }
        }
    }

    private var screenshotPreviewSheet: some View {
        NavigationStack {
            Group {
                if let index = previewedScreenshotIndex,
                   selectedScreenshots.indices.contains(index) {
                    ZoomableImageView(image: selectedScreenshots[index])
                        .ignoresSafeArea(edges: .bottom)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("关闭") {
                                    previewedScreenshotIndex = nil
                                }
                            }

                            ToolbarItem(placement: .topBarTrailing) {
                                Button(role: .destructive) {
                                    removeSelectedScreenshot(at: index)
                                    previewedScreenshotIndex = nil
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                } else {
                    Text("图片不存在")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("攻略截图")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var generationProgressView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ProgressView()
                    .controlSize(.small)
                Text(generationStatus)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(Int(generationProgress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: generationProgress)
                .tint(.blue)

                Text(inputMode == .recommend ? "AI 正在根据你的目的地和偏好生成行程，请保持当前页面。" : "AI 正在对比并整合多篇攻略，请保持当前页面。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @MainActor
    private func animateGenerationProgress() async {
        let steps: [(Double, String, UInt64)] = inputMode == .recommend ? [
            (0.18, "正在理解目的地和旅行天数", 700_000_000),
            (0.32, "正在匹配旅游类型和偏好", 1_200_000_000),
            (0.48, "正在筛选景点和美食", 1_200_000_000),
            (0.64, "正在整合成每日路线", 1_400_000_000),
            (0.78, "正在计算交通和步数", 1_400_000_000),
            (0.9, "正在检查结果是否一致", 1_600_000_000)
        ] : [
            (0.18, "正在识别目的地和攻略是否匹配", 700_000_000),
            (0.32, "正在提取多篇攻略的共同推荐", 1_200_000_000),
            (0.48, "正在去重筛选景点和美食", 1_200_000_000),
            (0.64, "正在整合成每日路线", 1_400_000_000),
            (0.78, "正在计算交通和步数", 1_400_000_000),
            (0.9, "正在检查结果是否一致", 1_600_000_000)
        ]

        for step in steps {
            guard !Task.isCancelled else {
                return
            }

            try? await Task.sleep(nanoseconds: step.2)

            guard !Task.isCancelled else {
                return
            }

            generationProgress = max(generationProgress, step.0)
            generationStatus = step.1
        }

        generationStatus = "正在完成最后整理"

        while !Task.isCancelled && generationProgress < 0.99 {
            try? await Task.sleep(nanoseconds: 900_000_000)

            guard !Task.isCancelled else {
                return
            }

            generationProgress = min(generationProgress + 0.01, 0.99)
        }
    }

    private func generationErrorMessage(for error: Error) -> String {
        if error is DecodingError {
            return "生成失败：AI 返回格式不稳定，请重新生成一次。"
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return "生成失败：这次生成时间太长，请重新生成一次。截图攻略内容较多时，可以先减少截图数量，或改用「直接推荐」。"
            case .notConnectedToInternet:
                return "生成失败：当前网络不可用，请连接网络后再试。"
            case .networkConnectionLost:
                return "生成失败：网络连接中断了，请稍后重新生成一次。"
            default:
                break
            }
        }

        return "生成失败：\(error.localizedDescription)"
    }

    @MainActor
    private func loadSelectedScreenshots(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else {
            selectedScreenshots = []
            selectedScreenshotTexts = []
            recognizedGuideText = ""
            return
        }

        isRecognizingText = true
        errorMessage = ""
        selectedScreenshots = []
        selectedScreenshotTexts = []

        do {
            var images: [UIImage] = []
            var recognizedTexts: [String] = []

            for item in items {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    throw URLError(.cannotDecodeContentData)
                }

                images.append(image)
                let recognizedText = try await recognizeText(from: image)
                recognizedTexts.append(recognizedText)
            }

            selectedScreenshots = images
            selectedScreenshotTexts = recognizedTexts

            if recognizedTexts.allSatisfy({ $0.isEmpty }) {
                errorMessage = "没有识别到文字，请换更清晰的截图，或手动粘贴攻略。"
            } else {
                rebuildRecognizedGuideText()
            }
        } catch {
            errorMessage = "截图识别失败：\(error.localizedDescription)"
        }

        isRecognizingText = false
    }

    private func removeSelectedScreenshot(at index: Int) {
        guard selectedScreenshots.indices.contains(index) else {
            return
        }

        selectedScreenshots.remove(at: index)

        if selectedScreenshotTexts.indices.contains(index) {
            selectedScreenshotTexts.remove(at: index)
        }

        if selectedPhotoItems.indices.contains(index) {
            isUpdatingPhotoSelection = true
            selectedPhotoItems.remove(at: index)
        }

        if selectedScreenshots.isEmpty {
            recognizedGuideText = ""
            selectedScreenshotTexts = []
            previewedScreenshotIndex = nil
        } else {
            rebuildRecognizedGuideText()
            if let previewedScreenshotIndex,
               previewedScreenshotIndex >= selectedScreenshots.count {
                self.previewedScreenshotIndex = selectedScreenshots.count - 1
            }
        }
    }

    private func clearSelectedScreenshots() {
        isUpdatingPhotoSelection = true
        selectedPhotoItems = []
        selectedScreenshots = []
        selectedScreenshotTexts = []
        recognizedGuideText = ""
        previewedScreenshotIndex = nil
        errorMessage = ""
    }

    private func rebuildRecognizedGuideText() {
        recognizedGuideText = selectedScreenshotTexts
            .enumerated()
            .filter { !$0.element.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { index, text in
                "攻略截图 \(index + 1)：\n\(text)"
            }
            .joined(separator: "\n\n")
    }

    private func recognizeText(from image: UIImage) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            guard let cgImage = image.cgImage else {
                throw URLError(.cannotDecodeContentData)
            }

            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage)
            try handler.perform([request])

            let lines = request.results?
                .compactMap { $0.topCandidates(1).first?.string }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty } ?? []

            return lines.joined(separator: "\n")
        }.value
    }
}

private struct ZoomableImageView: View {
    let image: UIImage

    @State private var scale = 1.0
    @State private var lastScale = 1.0

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
        }
        .background(Color.black.opacity(0.92))
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    scale = min(max(lastScale * value, 1.0), 4.0)
                }
                .onEnded { _ in
                    lastScale = scale
                }
        )
        .onTapGesture(count: 2) {
            if scale > 1.0 {
                scale = 1.0
                lastScale = 1.0
            } else {
                scale = 2.0
                lastScale = 2.0
            }
        }
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
                travelType: "情侣游",
                preferences: ["美食", "购物", "拍照", "轻松"]
            )
        }
    }
}
