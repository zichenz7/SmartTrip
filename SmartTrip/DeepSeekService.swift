//
//  DeepSeekService.swift
//  SmartTrip
//
//  Created by 竺子宸 on 2026/5/29.
//

import Foundation

struct DeepSeekService {
    func generateTripSummary(destination: String, days: String, guideText: String) async throws -> String {
        let plan = try await generateTripPlan(
            destination: destination,
            days: days,
            lodgingStatus: "recommend",
            lodgingArea: "",
            preferences: [],
            guideText: guideText
        )
        let data = try JSONEncoder().encode(plan)
        return String(data: data, encoding: .utf8) ?? "AI 已返回结构化结果"
    }

    func generateTripPlan(
        destination: String,
        days: String,
        lodgingStatus: String,
        lodgingArea: String,
        preferences: [String],
        guideText: String
    ) async throws -> TripPlan {
        guard let apiKey = ProcessInfo.processInfo.environment["DEEPSEEK_API_KEY"],
              !apiKey.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }

        let url = URL(string: "https://api.deepseek.com/chat/completions")!
        try await validateGuideMatchesDestination(
            destination: destination,
            guideText: guideText,
            apiKey: apiKey,
            url: url
        )

        let prompt = """
        请根据下面的旅行攻略，生成一个适合 iOS App 展示的结构化旅行规划。

        目的地：\(destination)
        天数：\(days)
        住宿状态：\(lodgingStatus == "decided" ? "用户已经订好/决定住宿" : "用户还没决定住宿，需要推荐")
        已知住宿区域：\(lodgingArea.isEmpty ? "无" : lodgingArea)
        旅行偏好：\(preferences.isEmpty ? "无特别偏好" : preferences.joined(separator: "、"))

        攻略内容：
        \(guideText)

        只返回 JSON，不要 Markdown，不要解释，不要代码块。
        JSON 必须完全符合下面结构，字段名不能改：
        {
          "lodgingAdvice": {
            "title": "推荐住宿：区域名",
            "summary": "一句话总结",
            "reasons": ["理由1", "理由2", "理由3"],
            "backupAreas": [
              { "area": "备选区域", "reason": "推荐原因" }
            ]
          },
          "mustGoPlaces": [
            { "name": "地点名", "reason": "为什么必去" }
          ],
          "optionalPlaces": [
            { "name": "地点名", "reason": "为什么可选" }
          ],
          "skippedPlaces": [
            { "name": "地点名", "reason": "为什么建议舍弃" }
          ],
          "days": [
            {
              "day": 1,
              "route": "地点A -> 地点B -> 地点C",
              "intensity": "轻松/适中/偏满",
              "transportTime": "从住宿地出发并完成当天路线的总交通时间",
              "transportDetails": ["住宿地/推荐住宿区 -> 地点A：交通方式 + 约几分钟", "地点A -> 地点B：交通方式 + 约几分钟"],
              "steps": "预计步数",
              "advice": "当天建议",
              "easyAlternative": "当天轻松替代方案",
              "adjustments": {
                "rain": {
                  "route": "下雨时的完整路线",
                  "intensity": "轻松/适中/偏满",
                  "transportTime": "下雨时预计交通时间",
                  "transportDetails": ["下雨方案每段交通方式和时间"],
                  "steps": "下雨时预计步数",
                  "advice": "下雨时当天建议",
                  "adjustmentNote": "说明从标准版删掉/保留/替换了什么"
                },
                "late": {
                  "route": "起晚时的完整路线",
                  "intensity": "轻松/适中/偏满",
                  "transportTime": "起晚时预计交通时间",
                  "transportDetails": ["起晚方案每段交通方式和时间"],
                  "steps": "起晚时预计步数",
                  "advice": "起晚时当天建议",
                  "adjustmentNote": "说明从标准版删掉/保留/替换了什么"
                },
                "tired": {
                  "route": "太累时的完整路线",
                  "intensity": "轻松/适中/偏满",
                  "transportTime": "太累时预计交通时间",
                  "transportDetails": ["太累方案每段交通方式和时间"],
                  "steps": "太累时预计步数",
                  "advice": "太累时当天建议",
                  "adjustmentNote": "说明从标准版删掉/保留/替换了什么"
                },
                "shopping": {
                  "route": "想购物时的完整路线",
                  "intensity": "轻松/适中/偏满",
                  "transportTime": "想购物时预计交通时间",
                  "transportDetails": ["购物方案每段交通方式和时间"],
                  "steps": "想购物时预计步数",
                  "advice": "想购物时当天建议",
                  "adjustmentNote": "说明从标准版删掉/保留/替换了什么"
                },
                "photo": {
                  "route": "想拍照时的完整路线",
                  "intensity": "轻松/适中/偏满",
                  "transportTime": "想拍照时预计交通时间",
                  "transportDetails": ["拍照方案每段交通方式和时间"],
                  "steps": "想拍照时预计步数",
                  "advice": "想拍照时当天建议",
                  "adjustmentNote": "说明从标准版删掉/保留/替换了什么"
                }
              }
            }
          ]
        }

        days 数组数量必须等于用户输入的天数。
        攻略内容中出现的每个地点必须且只能出现在 mustGoPlaces、optionalPlaces、skippedPlaces 三类之一。
        lodgingStatus 是 decided 时，必须以已知住宿区域作为行程锚点来规划，不要机械照抄攻略路线。
        lodgingStatus 是 decided 时，必须客观评价已知住宿区域是否适合这份攻略；如果不适合，不要写“适合”，要说明问题，并在 daily route 中减少跨城折返或替换部分景点。
        lodgingStatus 是 decided 时，如果攻略里的某个远距离景点和住宿区域附近资源属于同类型体验，应优先保留住宿区域附近体验，并把远距离重复景点放入 skippedPlaces。例如用户住在 Newport Beach 时，Santa Monica 这类远距离海滩不一定要去，可以用 Newport Beach 本身替代。
        lodgingStatus 是 decided 时，route 和 transportDetails 必须从已知住宿区域出发；如果当天路线离住宿区域太远，必须减少地点或改为同区域附近地点。
        lodgingStatus 是 recommend 时，给出最适合的推荐住宿区域和备选区域。
        preferences 会影响路线内容：选择“美食”时，每天至少加入一个适合用餐/小吃/咖啡的安排；选择“购物”时加入购物街区或商场；选择“拍照”时加入拍照点；选择“轻松”或“不想太赶”时降低景点数量、步数和移动距离。
        transportTime 必须是从住宿区域或推荐住宿区域出发、完成当天所有路线的总交通时间，不是单个景点之间的时间。
        transportDetails 必须列出当天每一段交通：住宿地/推荐住宿区到第一个地点、地点之间移动、最后是否返回住宿地；每段都要写交通方式和预计分钟数。
        每个 adjustments 版本必须是一套完整且自洽的当天方案：route、transportTime、transportDetails、steps、advice、adjustmentNote 必须互相一致。
        adjustmentNote 说删掉、不去、替换掉的地点，绝对不能继续出现在同一个版本的 route、transportDetails 或 advice 中。
        adjustmentNote 说新增、保留的地点，必须出现在同一个版本的 route 中。
        easyAlternative 只是标准版的备用建议，不代表标准版当前路线已经调整；标准版 route、advice、transportDetails 不要和 easyAlternative 写成互相矛盾的当前状态。
        late 表示用户起晚了，应该减少地点数量或压缩行程，不要只改说明。
        tired 表示用户很累，应该显著降低步数和移动距离。
        rain 表示下雨，应该减少户外停留，优先室内/商场/咖啡/观景台。
        """

        let body = ChatRequest(
            model: "deepseek-v4-flash",
            messages: [
                Message(role: "system", content: "你是一个擅长自由行规划的中文旅行助手。你只输出合法 JSON。"),
                Message(role: "user", content: prompt)
            ],
            thinking: Thinking(type: "disabled"),
            responseFormat: ResponseFormat(type: "json_object"),
            stream: false
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ChatResponse.self, from: data)
        let content = response.choices.first?.message.content ?? ""
        let jsonText = cleanedJSONText(content)
        let jsonData = Data(jsonText.utf8)

        return try JSONDecoder().decode(TripPlan.self, from: jsonData)
    }

    private func validateGuideMatchesDestination(
        destination: String,
        guideText: String,
        apiKey: String,
        url: URL
    ) async throws {
        let prompt = """
        判断下面的旅行攻略内容是否和用户输入的目的地相关。

        用户输入目的地：\(destination)

        攻略内容：
        \(guideText)

        只返回 JSON，不要 Markdown，不要解释，不要代码块。
        JSON 必须符合：
        {
          "isMatched": true,
          "detectedDestination": "你从攻略中识别出的目的地",
          "reason": "一句话原因"
        }

        判断规则：
        如果攻略主要内容明显属于另一个城市、地区或国家，isMatched 必须为 false。
        如果攻略内容无法判断目的地，isMatched 必须为 false。
        只有攻略主要内容确实围绕用户输入目的地，或者属于该目的地的常见别名/上级区域/周边区域，isMatched 才能为 true。
        例子：用户输入“东京”，攻略主要写“洛杉矶、Santa Monica、Newport Beach”，必须返回 false。
        例子：用户输入“洛杉矶”，攻略主要写“LA、Santa Monica、Hollywood、Newport Beach”，可以返回 true。
        """

        let body = ChatRequest(
            model: "deepseek-v4-flash",
            messages: [
                Message(role: "system", content: "你是一个严格的旅行目的地匹配检查器。你只输出合法 JSON。"),
                Message(role: "user", content: prompt)
            ],
            thinking: Thinking(type: "disabled"),
            responseFormat: ResponseFormat(type: "json_object"),
            stream: false
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ChatResponse.self, from: data)
        let content = response.choices.first?.message.content ?? ""
        let jsonText = cleanedJSONText(content)
        let validation = try JSONDecoder().decode(GuideDestinationValidation.self, from: Data(jsonText.utf8))

        if !validation.isMatched {
            throw SmartTripError.destinationMismatch(
                destination: destination,
                detectedDestination: validation.detectedDestination,
                reason: validation.reason
            )
        }
    }

    private func cleanedJSONText(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if result.hasPrefix("```json") {
            result.removeFirst("```json".count)
        } else if result.hasPrefix("```") {
            result.removeFirst("```".count)
        }

        if result.hasSuffix("```") {
            result.removeLast("```".count)
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct ChatRequest: Encodable {
    let model: String
    let messages: [Message]
    let thinking: Thinking
    let responseFormat: ResponseFormat
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case thinking
        case responseFormat = "response_format"
        case stream
    }
}

struct Message: Codable {
    let role: String
    let content: String
}

struct Thinking: Encodable {
    let type: String
}

struct ResponseFormat: Encodable {
    let type: String
}

struct ChatResponse: Decodable {
    let choices: [Choice]
}

struct Choice: Decodable {
    let message: Message
}

struct GuideDestinationValidation: Decodable {
    let isMatched: Bool
    let detectedDestination: String
    let reason: String
}

enum SmartTripError: LocalizedError {
    case destinationMismatch(destination: String, detectedDestination: String, reason: String)

    var errorDescription: String? {
        switch self {
        case .destinationMismatch(let destination, let detectedDestination, let reason):
            let detected = detectedDestination.isEmpty ? "其他目的地" : detectedDestination
            return "目的地不匹配：你填写的是「\(destination)」，但攻略看起来主要是「\(detected)」。\(reason)"
        }
    }
}
