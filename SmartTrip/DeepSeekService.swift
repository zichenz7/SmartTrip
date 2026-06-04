//
//  DeepSeekService.swift
//  SmartTrip
//
//  Created by 竺子宸 on 2026/5/29.
//

import Foundation

struct DeepSeekService {
    private var proxyChatCompletionsURL: URL? {
        let candidates = [
            ProcessInfo.processInfo.environment["SMARTTRIP_API_BASE_URL"],
            Bundle.main.object(forInfoDictionaryKey: "SMARTTRIP_API_BASE_URL") as? String,
            "https://smarttrai-proxy-dylsdjcmfp.cn-shanghai.fcapp.run",
            "https://smarttrip.zichenz7.workers.dev"
        ]

        guard let baseURLString = candidates
            .compactMap({ $0?.trimmingCharacters(in: .whitespacesAndNewlines) })
            .first(where: { !$0.isEmpty && !$0.contains("YOUR_WORKER_URL") }),
              let baseURL = URL(string: baseURLString) else {
            return nil
        }

        return baseURL.appendingPathComponent("chat/completions")
    }

    private var smartTripAppToken: String? {
        [
            ProcessInfo.processInfo.environment["SMARTTRIP_APP_TOKEN"],
            Bundle.main.object(forInfoDictionaryKey: "SMARTTRIP_APP_TOKEN") as? String
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .first { !$0.isEmpty && !$0.contains("YOUR_APP_TOKEN") }
    }

    func generateTripSummary(destination: String, days: String, guideText: String) async throws -> String {
        let plan = try await generateTripPlan(
            destination: destination,
            days: days,
            lodgingStatus: "recommend",
            lodgingArea: "",
            travelType: "",
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
        travelType: String,
        preferences: [String],
        guideText: String
    ) async throws -> TripPlan {
        let trimmedGuideText = guideText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasGuideText = !trimmedGuideText.isEmpty

        if hasGuideText {
            try await validateGuideMatchesDestination(
                destination: destination,
                guideText: trimmedGuideText
            )
        }

        let planningModeDescription = hasGuideText
            ? "请根据下面 2-3 篇用户喜欢的旅行攻略，整合生成一个适合 iOS App 展示的结构化旅行规划。"
            : "用户没有提供攻略内容。请根据目的地、天数、住宿状态、旅游类型和旅行偏好，直接生成一个适合 iOS App 展示的结构化旅行规划。"
        let planningGoalDescription = hasGuideText
            ? "核心目标不是照抄某一篇攻略，而是把多篇攻略中用户感兴趣的内容去重、筛选、合并成一条更适合用户自己的行程。"
            : "核心目标是给用户一份可以直接参考的初版行程：地点选择要经典、顺路、不过度拥挤，并明显体现用户的旅行偏好。"
        let guideSectionTitle = hasGuideText ? "多篇攻略内容" : "攻略内容"
        let guideSectionContent = hasGuideText ? trimmedGuideText : "用户未提供攻略，请直接推荐。"

        let prompt = """
        \(planningModeDescription)
        \(planningGoalDescription)

        目的地：\(destination)
        天数：\(days)
        住宿状态：\(lodgingStatus == "decided" ? "用户已经订好/决定住宿" : "用户还没决定住宿，需要推荐")
        已知住宿区域：\(lodgingArea.isEmpty ? "无" : lodgingArea)
        旅游类型：\(travelType.isEmpty ? "未指定" : travelType)
        旅行偏好：\(preferences.isEmpty ? "无特别偏好" : preferences.joined(separator: "、"))

        \(guideSectionTitle)：
        \(guideSectionContent)

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
          "foodPlaces": [
            { "name": "餐厅/小吃/咖啡店/美食区域名", "reason": "推荐吃什么或适合哪一餐" }
          ],
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
              "transportDetails": ["住宿地/推荐住宿区 -> 地点A：交通方式，约几分钟", "地点A -> 地点B：交通方式，约几分钟"],
              "steps": "预计步数",
              "advice": "当天建议",
              "easyAlternative": "当天轻松替代方案",
              "adjustments": {
                "rain": {
                  "route": "下雨时的完整路线",
                  "intensity": "轻松/适中/偏满",
                  "transportTime": "下雨时预计交通时间",
                  "transportDetails": ["住宿地/推荐住宿区 -> 地点A：交通方式，约几分钟", "地点A -> 地点B：交通方式，约几分钟"],
                  "steps": "下雨时预计步数",
                  "advice": "下雨时当天建议",
                  "adjustmentNote": "说明从标准版删掉/保留/替换了什么"
                },
                "late": {
                  "route": "起晚时的完整路线",
                  "intensity": "轻松/适中/偏满",
                  "transportTime": "起晚时预计交通时间",
                  "transportDetails": ["住宿地/推荐住宿区 -> 地点A：交通方式，约几分钟", "地点A -> 地点B：交通方式，约几分钟"],
                  "steps": "起晚时预计步数",
                  "advice": "起晚时当天建议",
                  "adjustmentNote": "说明从标准版删掉/保留/替换了什么"
                },
                "tired": {
                  "route": "太累时的完整路线",
                  "intensity": "轻松/适中/偏满",
                  "transportTime": "太累时预计交通时间",
                  "transportDetails": ["住宿地/推荐住宿区 -> 地点A：交通方式，约几分钟", "地点A -> 地点B：交通方式，约几分钟"],
                  "steps": "太累时预计步数",
                  "advice": "太累时当天建议",
                  "adjustmentNote": "说明从标准版删掉/保留/替换了什么"
                },
                "shopping": {
                  "route": "想购物时的完整路线",
                  "intensity": "轻松/适中/偏满",
                  "transportTime": "想购物时预计交通时间",
                  "transportDetails": ["住宿地/推荐住宿区 -> 地点A：交通方式，约几分钟", "地点A -> 地点B：交通方式，约几分钟"],
                  "steps": "想购物时预计步数",
                  "advice": "想购物时当天建议",
                  "adjustmentNote": "说明从标准版删掉/保留/替换了什么"
                },
                "photo": {
                  "route": "想拍照时的完整路线",
                  "intensity": "轻松/适中/偏满",
                  "transportTime": "想拍照时预计交通时间",
                  "transportDetails": ["住宿地/推荐住宿区 -> 地点A：交通方式，约几分钟", "地点A -> 地点B：交通方式，约几分钟"],
                  "steps": "想拍照时预计步数",
                  "advice": "想拍照时当天建议",
                  "adjustmentNote": "说明从标准版删掉/保留/替换了什么"
                }
              }
            }
          ]
        }

        多攻略整合规则：
        先分别理解每篇攻略提到的景点、美食、购物点、住宿建议和路线倾向，再合并生成最终方案。
        多篇攻略重复出现、或不同攻略都强烈推荐的地点，优先放入 mustGoPlaces。
        只在单篇攻略出现但和用户偏好高度匹配、交通顺路或体验独特的地点，可以放入 mustGoPlaces 或 optionalPlaces。
        多篇攻略里互相重复、同质化或距离过远的地点，不要全部塞进行程；选择更符合住宿位置、天数和偏好的那个，其余放入 optionalPlaces 或 skippedPlaces。
        如果攻略 A 和攻略 B 的路线方向冲突，必须按“少折返、同区域合并、每天移动距离合理”的原则重组路线，不要机械拼接。
        如果不同攻略推荐了同类型体验，例如多个海滩、多个观景台、多个购物区，必须根据住宿位置、用户偏好和交通成本做取舍。
        如果用户没有提供攻略内容，不要提到“攻略一/攻略二”，也不要假装用户提供了攻略；必须基于目的地常规旅行经验、用户天数、住宿状态、旅游类型和旅行偏好直接推荐。
        如果用户没有提供攻略内容，mustGoPlaces 应优先放该目的地经典且适合首次旅行的地点，optionalPlaces 放适合加选但不是必须的地点，skippedPlaces 放因为距离远、时间不够、和偏好不匹配或体验重复而暂不建议的地点。
        行程应该体现用户偏好：用户选了美食/购物/拍照/轻松时，最终每天路线和 mustGoPlaces/foodPlaces 都要能看出这些偏好，而不是只在总结里提到。
        旅游类型会影响路线节奏和场景取舍：单人游重视安全、交通清晰和独处友好；情侣游重视氛围、拍照和晚间体验；朋友结伴重视互动、弹性和聚餐；毕业旅行重视打卡、预算和纪念感；公司团建重视集体移动、低风险和共同活动；家庭亲子重视少折腾、休息、卫生间/推车友好和儿童可参与；无障碍旅行重视少台阶、少换乘、电梯/无障碍通道和步行距离控制。
        最终结果要像一份“整合后的个人行程”，不要写“攻略一/攻略二建议”这种分析报告口吻。

        days 数组数量必须等于用户输入的天数。
        foodPlaces 只放餐厅、小吃、咖啡、市场、美食街、甜品店等吃喝相关地点。
        mustGoPlaces、optionalPlaces、skippedPlaces 主要放景点、街区、商场、观景点、博物馆、海滩、公园等非餐饮地点。
        同一个地点不要同时出现在 foodPlaces 和 mustGoPlaces/optionalPlaces/skippedPlaces 中；如果一个地点既是市场又是吃饭点，优先放入 foodPlaces。
        攻略内容中出现的主要非餐饮地点必须且只能出现在 mustGoPlaces、optionalPlaces、skippedPlaces 三类之一；明显 OCR 噪音、广告词、无关店名可以忽略。
        lodgingStatus 是 decided 时，必须以已知住宿区域作为行程锚点来规划，不要机械照抄攻略路线。
        lodgingStatus 是 decided 时，必须客观评价已知住宿区域是否适合这份攻略；如果不适合，不要写“适合”，要说明问题，并在 daily route 中减少跨城折返或替换部分景点。
        lodgingStatus 是 decided 时，如果攻略里的某个远距离景点和住宿区域附近资源属于同类型体验，应优先保留住宿区域附近体验，并把远距离重复景点放入 skippedPlaces。例如用户住在 Newport Beach 时，Santa Monica 这类远距离海滩不一定要去，可以用 Newport Beach 本身替代。
        lodgingStatus 是 decided 时，route 和 transportDetails 必须从已知住宿区域出发；如果当天路线离住宿区域太远，必须减少地点或改为同区域附近地点。
        lodgingStatus 是 recommend 时，给出最适合的推荐住宿区域和备选区域。
        preferences 会影响路线内容：选择“美食”时，每天至少加入一个适合用餐/小吃/咖啡的安排；选择“购物”时加入购物街区或商场；选择“拍照”时加入拍照点；选择“轻松”时降低景点数量、步数和移动距离。
        transportTime 必须是从住宿区域或推荐住宿区域出发、完成当天所有路线的总交通时间，不是单个景点之间的时间。
        transportDetails 必须列出当天每一段交通：住宿地/推荐住宿区到第一个地点、地点之间移动、最后是否返回住宿地；每段都要写交通方式和预计分钟数。
        transportTime 必须和 transportDetails 每段时间相加后的总和一致，不能大于或小于明细时间总和。例如明细是 10 分钟 + 5 分钟 + 10 分钟，transportTime 必须写约 25 分钟，不能写约 40 分钟。
        transportDetails 里禁止使用 “+” 连接交通方式和时间；必须写成“地铁，约40分钟”“步行，约10分钟”这种自然中文。
        transportDetails 必须让用户不看其他版本也能独立理解；禁止写“同标准版”“同上”“不变”“参考标准版”“与标准版一致”等占位内容。
        所有 adjustments 的 transportDetails 也必须写完整具体的每段交通方式和预计分钟数，即使某一段和标准版相同，也要重新完整写出来。
        每个 adjustments 版本必须是一套完整且自洽的当天方案：route、transportTime、transportDetails、steps、advice、adjustmentNote 必须互相一致。
        每一天都必须返回完整的 adjustments 对象，并且 rain、late、tired、shopping、photo 五个键都不能缺失。
        rain、late、tired、shopping、photo 五个调整版本的 route/advice/adjustmentNote 不能全部和标准版相同；至少要在路线、地点数量、停留重点或建议上体现该按钮对应的变化。
        禁止在任何 adjustment 的 adjustmentNote 中写“当前为标准行程”“标准行程不变”“与标准版相同”等表达。
        adjustmentNote 说删掉、不去、替换掉的地点，绝对不能继续出现在同一个版本的 route、transportDetails 或 advice 中。
        adjustmentNote 说新增、保留的地点，必须出现在同一个版本的 route 中。
        easyAlternative 只是标准版的备用建议，不代表标准版当前路线已经调整；标准版 route、advice、transportDetails 不要和 easyAlternative 写成互相矛盾的当前状态。
        late 表示用户起晚了，应该减少地点数量或压缩行程，不要只改说明。
        如果某一天本身是下午/晚上抵达、机场入境、酒店 check-in 或航班决定的半日行程，late 调整不要写成“起晚了”，应当和标准版保持合理的半日节奏，避免出现不符合场景的描述。
        如果第一天只有“机场 -> 酒店/住宿”这种纯抵达安排，标准版只写机场到酒店，不要强行加入购物、拍照、下雨、太累等调整逻辑。
        如果最后一天只有“酒店/住宿 -> 机场”这种纯离开安排，标准版只写去机场，不要强行加入购物、拍照、下雨、太累等调整逻辑。
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

        let response = try await sendChatRequest(body)
        let content = response.choices.first?.message.content ?? ""
        let jsonText = cleanedJSONText(content)
        let jsonData = Data(jsonText.utf8)
        let plan = try JSONDecoder().decode(TripPlan.self, from: jsonData)
        let normalizedPlan = normalizedTransportTimes(in: plan)

        return normalizedPlan
    }

    private func validateGuideMatchesDestination(
        destination: String,
        guideText: String
    ) async throws {
        let prompt = """
        判断下面的多篇旅行攻略内容是否和用户输入的目的地相关。

        用户输入目的地：\(destination)

        多篇攻略内容：
        \(guideText)

        只返回 JSON，不要 Markdown，不要解释，不要代码块。
        JSON 必须符合：
        {
          "isMatched": true,
          "detectedDestination": "你从攻略中识别出的目的地",
          "reason": "一句话原因"
        }

        判断规则：
        如果这些攻略的主要内容明显属于另一个城市、地区或国家，isMatched 必须为 false。
        如果多篇攻略中混入了与用户目的地完全无关的主要攻略，isMatched 必须为 false，并在 reason 中说明混入了哪个目的地。
        如果攻略内容无法判断目的地，isMatched 必须为 false。
        只有多篇攻略主要内容都确实围绕用户输入目的地，或者属于该目的地的常见别名/上级区域/周边区域，isMatched 才能为 true。
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

        let response = try await sendChatRequest(body)
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

    private func sendChatRequest(_ body: ChatRequest) async throws -> ChatResponse {
        let requestData = try JSONEncoder().encode(body)
        let url: URL
        var request: URLRequest

        if let proxyChatCompletionsURL {
            url = proxyChatCompletionsURL
            request = URLRequest(url: url)
            if let smartTripAppToken {
                request.setValue(smartTripAppToken, forHTTPHeaderField: "X-SmartTrip-Token")
            }
        } else if let apiKey = ProcessInfo.processInfo.environment["DEEPSEEK_API_KEY"],
                  !apiKey.isEmpty {
            url = URL(string: "https://api.deepseek.com/chat/completions")!
            request = URLRequest(url: url)
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        } else {
            throw SmartTripError.backendNotConfigured
        }

        request.httpMethod = "POST"
        request.timeoutInterval = 180
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            throw SmartTripError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "服务器返回 \(httpResponse.statusCode)"
            throw SmartTripError.serverError(message)
        }

        return try JSONDecoder().decode(ChatResponse.self, from: data)
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

    private func normalizedTransportTimes(in plan: TripPlan) -> TripPlan {
        TripPlan(
            lodgingAdvice: plan.lodgingAdvice,
            foodPlaces: plan.foodPlaces,
            mustGoPlaces: plan.mustGoPlaces,
            optionalPlaces: plan.optionalPlaces,
            skippedPlaces: plan.skippedPlaces,
            days: plan.days.map(normalizedTransportTimes)
        )
    }

    private func normalizedTransportTimes(in day: DayPlan) -> DayPlan {
        let details = normalizedTransportDetails(
            day.transportDetails,
            route: day.route,
            totalTime: day.transportTime,
            standardDetails: nil
        )

        return DayPlan(
            day: day.day,
            route: day.route,
            intensity: day.intensity,
            transportTime: correctedTransportTime(day.transportTime, details: details),
            transportDetails: details,
            steps: day.steps,
            advice: day.advice,
            easyAlternative: day.easyAlternative,
            adjustments: day.adjustments.map { normalizedTransportTimes(in: $0, standardDetails: details) }
        )
    }

    private func normalizedTransportTimes(in adjustments: DayAdjustments, standardDetails: [String]) -> DayAdjustments {
        DayAdjustments(
            rain: normalizedTransportTimes(in: adjustments.rain, standardDetails: standardDetails),
            late: normalizedTransportTimes(in: adjustments.late, standardDetails: standardDetails),
            tired: normalizedTransportTimes(in: adjustments.tired, standardDetails: standardDetails),
            shopping: normalizedTransportTimes(in: adjustments.shopping, standardDetails: standardDetails),
            photo: normalizedTransportTimes(in: adjustments.photo, standardDetails: standardDetails)
        )
    }

    private func normalizedTransportTimes(in adjustment: DayAdjustment, standardDetails: [String]) -> DayAdjustment {
        let details = normalizedTransportDetails(
            adjustment.transportDetails,
            route: adjustment.route,
            totalTime: adjustment.transportTime,
            standardDetails: standardDetails
        )

        return DayAdjustment(
            route: adjustment.route,
            intensity: adjustment.intensity,
            transportTime: correctedTransportTime(adjustment.transportTime, details: details),
            transportDetails: details,
            steps: adjustment.steps,
            advice: adjustment.advice,
            adjustmentNote: adjustment.adjustmentNote
        )
    }

    private func normalizedTransportDetails(
        _ details: [String],
        route: String,
        totalTime: String,
        standardDetails: [String]?
    ) -> [String] {
        let fallbackDetails = synthesizedTransportDetails(route: route, totalTime: totalTime)
        let fallbackBySegment: [String: String] = Dictionary(uniqueKeysWithValues: fallbackDetails.compactMap { detail in
            segmentKey(in: detail).map { ($0, detail) }
        })
        let standardBySegment: [String: String] = Dictionary(uniqueKeysWithValues: (standardDetails ?? []).compactMap { detail in
            guard !isPlaceholderTransportDetail(detail),
                  let key = segmentKey(in: detail) else {
                return nil
            }

            return (key, detail)
        })

        let normalizedDetails = details.enumerated().compactMap { index, detail -> String? in
            let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedDetail.isEmpty else {
                return nil
            }

            guard isPlaceholderTransportDetail(trimmedDetail) else {
                return normalizedTransportDetailText(trimmedDetail)
            }

            if let key = segmentKey(in: trimmedDetail),
               let standardDetail = standardBySegment[key] {
                return normalizedTransportDetailText(standardDetail)
            }

            if let key = segmentKey(in: trimmedDetail),
               let fallbackDetail = fallbackBySegment[key] {
                return normalizedTransportDetailText(fallbackDetail)
            }

            if index < fallbackDetails.count {
                return normalizedTransportDetailText(fallbackDetails[index])
            }

            return nil
        }

        return normalizedDetails.isEmpty ? fallbackDetails.map(normalizedTransportDetailText) : normalizedDetails
    }

    private func normalizedTransportDetailText(_ detail: String) -> String {
        detail
            .replacingOccurrences(of: " + 约", with: "，约")
            .replacingOccurrences(of: "+ 约", with: "，约")
            .replacingOccurrences(of: " +约", with: "，约")
            .replacingOccurrences(of: "+约", with: "，约")
            .replacingOccurrences(of: " + ", with: "，")
    }

    private func isPlaceholderTransportDetail(_ detail: String) -> Bool {
        let blockedPhrases = ["同标准版", "同上", "不变", "参考标准版", "与标准版一致"]
        return blockedPhrases.contains { detail.contains($0) }
    }

    private func synthesizedTransportDetails(route: String, totalTime: String) -> [String] {
        let segments = routeSegments(from: route)
        guard !segments.isEmpty else {
            return []
        }

        let totalMinutes = maxMinutes(in: totalTime) ?? max(segments.count * 15, 15)
        let baseMinutes = max(totalMinutes / segments.count, 1)
        let remainingMinutes = max(totalMinutes - baseMinutes * segments.count, 0)

        return segments.enumerated().map { index, segment in
            let minutes = baseMinutes + (index == segments.count - 1 ? remainingMinutes : 0)
            return "\(segment)：约\(minutes)分钟"
        }
    }

    private func routeSegments(from route: String) -> [String] {
        let places = route
            .replacingOccurrences(of: "→", with: "->")
            .components(separatedBy: "->")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard places.count >= 2 else {
            return []
        }

        return zip(places, places.dropFirst()).map { "\($0) -> \($1)" }
    }

    private func segmentKey(in detail: String) -> String? {
        let segment = detail
            .components(separatedBy: CharacterSet(charactersIn: "：:"))
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let segment,
              !segment.isEmpty,
              segment.contains("->") || segment.contains("→") else {
            return nil
        }

        return segment
            .replacingOccurrences(of: "→", with: "->")
            .replacingOccurrences(of: " ", with: "")
    }

    private func correctedTransportTime(_ totalTime: String, details: [String]) -> String {
        let detailMinutes = details.compactMap { maxMinutes(in: $0) }
        guard !detailMinutes.isEmpty,
              let totalMinutes = maxMinutes(in: totalTime) else {
            return totalTime
        }

        let detailTotal = detailMinutes.reduce(0, +)
        if abs(totalMinutes - detailTotal) > 5 {
            return formattedTransportTime(detailTotal)
        }

        return totalTime
    }

    private func formattedTransportTime(_ minutes: Int) -> String {
        if minutes < 60 {
            return "约\(minutes)分钟"
        }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if remainingMinutes == 0 {
            return "约\(hours)小时"
        }

        return "约\(hours)小时\(remainingMinutes)分钟"
    }

    private func maxMinutes(in text: String) -> Int? {
        let hourMinutes = maxNumber(before: "小时", in: text).map { Int(($0 * 60).rounded()) } ?? 0
        let minutePart = maxNumber(before: "分钟", in: text).map { Int($0.rounded()) } ?? 0

        if hourMinutes > 0 || minutePart > 0 {
            return hourMinutes + minutePart
        }

        return nil
    }

    private func maxNumber(before suffix: String, in text: String) -> Double? {
        let pattern = #"(\d+(?:\.\d+)?)(?:\s*[-–~至到]\s*(\d+(?:\.\d+)?))?\s*\#(suffix)"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        let numbers = matches.compactMap { match -> Double? in
            if match.range(at: 2).location != NSNotFound {
                return Double(nsText.substring(with: match.range(at: 2)))
            }

            return Double(nsText.substring(with: match.range(at: 1)))
        }

        return numbers.max()
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
    case backendNotConfigured
    case serverError(String)
    case destinationMismatch(destination: String, detectedDestination: String, reason: String)
    case incompleteTransportDetails
    case inconsistentTransportTime
    case networkError(URLError)

    var errorDescription: String? {
        switch self {
        case .backendNotConfigured:
            return "AI 服务还没有配置完成，请稍后再试。"
        case .serverError(let message):
            return "AI 服务暂时不可用，请稍后再试。\(message)"
        case .destinationMismatch(let destination, let detectedDestination, let reason):
            let detected = detectedDestination.isEmpty ? "其他目的地" : detectedDestination
            return "目的地不匹配：你填写的是「\(destination)」，但攻略看起来主要是「\(detected)」。\(reason)"
        case .incompleteTransportDetails:
            return "AI 返回的交通详情不完整，请重新生成一次。"
        case .inconsistentTransportTime:
            return "AI 返回的总交通时间和交通明细不一致，请重新生成一次。"
        case .networkError(let error):
            switch error.code {
            case .timedOut:
                return "这次生成时间太长，请重新生成一次。截图攻略内容较多时，可以先减少截图数量，或改用「直接推荐」。"
            case .notConnectedToInternet:
                return "当前网络不可用，请连接网络后再试。"
            case .networkConnectionLost:
                return "网络连接中断了，请稍后重新生成一次。"
            default:
                return "网络请求失败，请稍后再试。\(error.localizedDescription)"
            }
        }
    }
}
