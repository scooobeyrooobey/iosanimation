import Foundation

struct Expedition: Identifiable, Equatable {
    let id: UUID
    let title: String
    let meta: String
    let difficulty: Int
    let shortDescription: String
    let longDescription: String
    /// Center / right / left images of the hero trio (asset names).
    let heroImage: String
    let sideImageRight: String
    let sideImageLeft: String

    init(
        id: UUID = UUID(),
        title: String,
        meta: String,
        difficulty: Int,
        shortDescription: String,
        longDescription: String,
        heroImage: String,
        sideImageRight: String,
        sideImageLeft: String
    ) {
        self.id = id
        self.title = title
        self.meta = meta
        self.difficulty = difficulty
        self.shortDescription = shortDescription
        self.longDescription = longDescription
        self.heroImage = heroImage
        self.sideImageRight = sideImageRight
        self.sideImageLeft = sideImageLeft
    }
}

extension Expedition {
    static let sample = Expedition(
        title: "Chase the Northern Lights Express",
        meta: "11 days, 24 Nov",
        difficulty: 3,
        shortDescription: "Small group tour from Finnish Lapland through coastal Norway to Bergen, in refined Nordic comfort",
        longDescription: """
        Travel high above the Arctic Circle in Finnish Lapland before crossing into Norway’s far north and sailing south along the dramatic Norwegian coastline on a modern Havila coastal ship. Spend three nights in a glass-roof Aurora cabin, stay in a characterful Gamme cabin in Kirkenes, and experience husky sledding, reindeer encounters and an Arctic king crab safari before arriving in historic Bergen.

        Thoughtfully paced and guided throughout, this small group journey combines immersive Arctic experiences with refined coastal sailing along Norway’s iconic shoreline.
        """,
        heroImage: "card1",
        sideImageRight: "card2",
        sideImageLeft: "card3"
    )

    /// Demo feed — distinct UUIDs per entry so hero / scroll identity work.
    static let samples: [Expedition] = [
        Expedition(
            title: "Patagonia Glacier Traverse",
            meta: "8 days, 14 Mar",
            difficulty: 4,
            shortDescription: "Cross the Southern Ice Field with a seasoned mountain guide and camp beneath the Torres del Paine",
            longDescription: sample.longDescription,
            heroImage: "patagonia1",
            sideImageRight: "patagonia2",
            sideImageLeft: "patagonia3"
        ),
        Expedition(
            title: "Chase the Northern Lights Express",
            meta: "11 days, 24 Nov",
            difficulty: 3,
            shortDescription: "Small group tour from Finnish Lapland through coastal Norway to Bergen, in refined Nordic comfort",
            longDescription: sample.longDescription,
            heroImage: "card1",
            sideImageRight: "card2",
            sideImageLeft: "card3"
        ),
        Expedition(
            title: "Atlas Mountains Summit Trek",
            meta: "6 days, 2 Oct",
            difficulty: 2,
            shortDescription: "Rise before dawn to summit Toubkal, then descend through Berber villages tucked into red-stone valleys",
            longDescription: sample.longDescription,
            heroImage: "card1",
            sideImageRight: "card2",
            sideImageLeft: "card3"
        )
    ]
}
