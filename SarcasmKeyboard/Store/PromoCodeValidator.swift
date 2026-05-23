import CryptoKit
import Foundation

enum PromoCodeValidator {
    enum Result {
        case valid, invalid, alreadyPro
    }

    static func redeem(_ raw: String, isPro: Bool) -> Result {
        guard !isPro else { return .alreadyPro }
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalized.isEmpty else { return .invalid }
        let hash = SHA256.hash(data: Data(normalized.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
        return validHashes.contains(hash) ? .valid : .invalid
    }

    // SHA256 hashes of the plaintext codes. Safe to commit — cannot be reversed.
    private static let validHashes: Set<String> = [
        "676599b1939a2278ad2bc92a5c007dea4af57d624f5f645d9ac1493533add5c9",
        "784a32f4fbdb52151119757bd9a9409cfa3d139dd6d1c228aeb9c16d5f31d02f",
        "254ef8b91594b29f42b3ee360feb455299b56eec42435ce76fd7a750fc868012",
        "c3f6c9f618002b978a9c363002cbb90f7e8107f8020cb2e9094fc6b23335e655",
        "a9f59ec7d485f49130d1994b1f88cccb3571e24418c349c49d222b65c862ec7b",
        "1632d36af6d44f2f03163e639c2858e75aab05c5831371a95632892e765a2788",
        "bd2b8bc66a9b1f3024cbec1054479fb2c9e0e782aac30a49274831eff1da42ce",
        "1eccf72f3208f93023e6b6a1a9b65e48f81442fa0b6b7b3115c67fea7ca06785",
        "b301fa446f6914ac169ca358ea7f0e8703c839a749a4af29444c72d47e8ccf57",
        "a962b869445ac84db5719bca5b68eeced138d50d0bab5472751b7467ab8b4f6a",
        "e181b738f347c91b05376beec695cdf994fb72dbb1c53962804d1a3cf3e14505",
        "7b10cc0c248f5afffb2f02df30ebdc7f218904db3c397686a2384ea3a40d6ad1",
        "b66990455a0521475a90b52637eb128b6d64fa4383390dc7cc84c5c11beee04b",
        "9e102c5f0bf2cc4de2ef0127611e3402c38c61e9fdecfac64d45fc86537bad37",
        "2453dccb328ae88b97495ba02864889033f05198f61e08178c9675c30e30f2da",
        "a6c525cabceb1646024c7588939862231205740cca52f1b01ffb807dcc75b1c2",
        "0d7e4d9914495d4ac90475083449620d292afc1087f4104fee15bfe4559e3801",
        "93a0e371aa70dd1409a3238457e31c31a433fdfad43a400528ce05d0711bf67e",
        "f40517d399dd46f62e6a91c69d527986cde1c5277ebc7878c20cb3667687b29b",
        "aab3347232c347c5391aa61508ce0ed30a01504687882269cd50dffbbdb56680",
        "9ff4c569100c9c67a7fd8e737aef49d2e5831b73bd844bac5e3da90288fafe84",
        "15ba2e07cbf170d76d5bd1380f7686a1b9ca42db38c520f7706f4d656f987b3a",
        "c53e83a16b958892e94a0312d1a45592d456767be5ab4f707e75d76b664aefa3",
        "1e79b75f38ddfe3528eb586765891222e71bdfc43ec437d32c35aedb372131d1",
        "cc69f72cebc2739083e2d01992c4706a0bca9ba5406a371c7ebb125c23694472",
    ]
}
