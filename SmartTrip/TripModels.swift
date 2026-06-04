import Foundation

struct PlaceItem: Identifiable, Codable {
    let id = UUID()
    let name: String
    let reason: String

    enum CodingKeys: String, CodingKey {
        case name
        case reason
    }
}

struct BackupArea: Identifiable, Codable {
    let id = UUID()
    let area: String
    let reason: String

    enum CodingKeys: String, CodingKey {
        case area
        case reason
    }
}

struct LodgingAdvice: Codable {
    let title: String
    let summary: String
    let reasons: [String]
    let backupAreas: [BackupArea]
}

struct DayPlan: Identifiable, Codable {
    let id = UUID()
    let day: Int
    let route: String
    let intensity: String
    let transportTime: String
    let transportDetails: [String]
    let steps: String
    let advice: String
    let easyAlternative: String
    let adjustments: DayAdjustments?

    enum CodingKeys: String, CodingKey {
        case day
        case route
        case intensity
        case transportTime
        case transportDetails
        case steps
        case advice
        case easyAlternative
        case adjustments
    }
}

struct TripPlan: Codable {
    let lodgingAdvice: LodgingAdvice
    let foodPlaces: [PlaceItem]?
    let mustGoPlaces: [PlaceItem]
    let optionalPlaces: [PlaceItem]
    let skippedPlaces: [PlaceItem]
    let days: [DayPlan]
}

struct DayAdjustment: Codable {
    let route: String
    let intensity: String
    let transportTime: String
    let transportDetails: [String]
    let steps: String
    let advice: String
    let adjustmentNote: String
}

struct DayAdjustments: Codable {
    let rain: DayAdjustment
    let late: DayAdjustment
    let tired: DayAdjustment
    let shopping: DayAdjustment
    let photo: DayAdjustment
}

struct SampleTripData {
    static let lodgingAdvice = LodgingAdvice(
        title: "推荐住宿：新宿",
        summary: "适合作为东京 3 日游基地",
        reasons: [
            "交通方便，去涩谷、明治神宫、代官山比较顺。",
            "晚上吃饭和购物选择多。",
            "去浅草和晴空塔稍远，但可以集中安排一天。"
        ],
        backupAreas: [
            BackupArea(area: "涩谷", reason: "更适合购物和夜生活。"),
            BackupArea(area: "银座", reason: "更适合高预算购物和筑地市场。"),
            BackupArea(area: "浅草", reason: "更适合传统东京氛围，但去涩谷较远。")
        ]
    )

    static let mustGoPlaces = [
        PlaceItem(name: "浅草寺", reason: "东京经典地标，适合拍照。"),
        PlaceItem(name: "东京晴空塔", reason: "夜景好，适合傍晚安排。"),
        PlaceItem(name: "涩谷", reason: "购物和年轻潮流街区。"),
        PlaceItem(name: "明治神宫", reason: "安静，适合轻松散步。"),
        PlaceItem(name: "代官山", reason: "适合咖啡、街拍和慢逛。")
    ]

    static let foodPlaces = [
        PlaceItem(name: "筑地市场", reason: "适合早餐和海鲜小吃。"),
        PlaceItem(name: "新宿思出横丁", reason: "适合晚餐和居酒屋氛围。"),
        PlaceItem(name: "代官山咖啡店", reason: "适合下午休息和轻食。")
    ]

    static let optionalPlaces = [
        PlaceItem(name: "银座", reason: "购物体验好，但和涩谷、新宿有重复。"),
        PlaceItem(name: "东京塔", reason: "适合外拍，不一定需要登塔。"),
        PlaceItem(name: "秋叶原", reason: "适合动漫和电器兴趣。"),
        PlaceItem(name: "上野公园", reason: "樱花季或想看博物馆时更适合。")
    ]

    static let skippedPlaces = [
        PlaceItem(name: "皇居", reason: "3 天游优先级较低。"),
        PlaceItem(name: "代代木公园", reason: "和明治神宫体验重复。"),
        PlaceItem(name: "表参道", reason: "和涩谷、代官山的购物街区体验重复。")
    ]

    static let days = [
        DayPlan(
            day: 1,
            route: "浅草寺 -> 东京晴空塔 -> 银座",
            intensity: "适中",
            transportTime: "90-110 分钟",
            transportDetails: [
                "住宿地 -> 浅草寺：地铁约 30 分钟",
                "浅草寺 -> 东京晴空塔：步行或地铁约 15-20 分钟",
                "东京晴空塔 -> 银座：地铁约 35 分钟"
            ],
            steps: "12000-15000 步",
            advice: "东京晴空塔适合傍晚去，银座不要逛太晚。",
            easyAlternative: "删掉银座，只保留浅草寺和东京晴空塔。",
            adjustments: nil
        ),
        DayPlan(
            day: 2,
            route: "筑地市场 -> 东京塔 -> 涩谷",
            intensity: "适中",
            transportTime: "65-85 分钟",
            transportDetails: [
                "住宿地 -> 筑地市场：地铁约 25 分钟",
                "筑地市场 -> 东京塔：地铁加步行约 25 分钟",
                "东京塔 -> 涩谷：地铁约 25 分钟"
            ],
            steps: "11000-14000 步",
            advice: "筑地市场尽量上午去，东京塔可以只外拍。",
            easyAlternative: "删掉东京塔，增加涩谷闲逛时间。",
            adjustments: nil
        ),
        DayPlan(
            day: 3,
            route: "明治神宫 -> 代官山 -> 新宿",
            intensity: "轻松",
            transportTime: "35-50 分钟",
            transportDetails: [
                "住宿地 -> 明治神宫：地铁约 15 分钟",
                "明治神宫 -> 代官山：地铁约 20 分钟",
                "代官山 -> 新宿：地铁约 15 分钟"
            ],
            steps: "8000-11000 步",
            advice: "最后一天安排轻松一点，方便买伴手礼。",
            easyAlternative: "如果很累，直接在新宿附近活动。",
            adjustments: nil
        )
    ]

    static let tripPlan = TripPlan(
        lodgingAdvice: lodgingAdvice,
        foodPlaces: foodPlaces,
        mustGoPlaces: mustGoPlaces,
        optionalPlaces: optionalPlaces,
        skippedPlaces: skippedPlaces,
        days: days
    )
}
