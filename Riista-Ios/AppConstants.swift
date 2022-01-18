import Foundation
import GoogleMaps
import RiistaCommon

// Same constants may be defined in Objective-C code (RiistaSettings etc.). Check when adding or modifying if
// duplicates can be removed.
@objc @objcMembers class AppConstants: NSObject {

    /**
     * The default app language to be used.
     *
     * Synchronize with RiistaSettings RiistaDefaultAppLanguage
     */
    static let defaultLanguage: Language = Language.en

    @objc(AppFont) @objcMembers class Font: NSObject {
        static let Name = "Open Sans"

        // font sizes
        static let LabelTiny = CGFloat(12)
        static let LabelSmall = CGFloat(14)
        static let LabelMedium = CGFloat(16)
        static let LabelLarge = CGFloat(18)
        static let LabelXLarge = CGFloat(20)
        static let LabelXXLarge = CGFloat(22)
        static let LabelHuge = CGFloat(24)
        static let ButtonSmall = CGFloat(14)
        static let ButtonMedium = CGFloat(16)
        static let ButtonLarge = CGFloat(18)
        static let NavigationBarTitle = CGFloat(18)
        static let Headline = CGFloat(18)
    }

    @objc(MapConstants) @objcMembers class Map: NSObject {
        static let MinZoom: Float = 4.0
        // apparentally having zoom level 16.0 causes map to fetch tiles using zoom level 17
        // - maybe zoom level is actually 16.0000000<something> and that causes the issue if
        //   zoom level is rounded up
        static let MaxZoom: Float = 15.95

        static let DefaultZoomToLevel: Float = 15.0
    }

    @objc(DefaultMapLocation) @objcMembers class DefaultMapLocation: NSObject {
        // center of Finland
        static let Latitude = 64.10
        static let Longitude = 25.48
        static let Zoom: Float = 5.5

        static public func toGMSCameraUpdate() -> GMSCameraUpdate {
            return GMSCameraUpdate.setTarget(CLLocationCoordinate2D(latitude: Latitude,
                                                                    longitude: Longitude),
                                             zoom: Zoom)
        }
    }

    static let HuntingYearStartMonth = 8

    struct SpeciesCode {
        static let Moose = 47503
        static let FallowDeer = 47484;
        static let WhiteTailedDeer = 47629;
        static let WildForestDeer = 200556;
        static let RoeDeer = 47507;

        static let Bear = 47348;
        static let Wolf = 46549;
        static let Wolverine = 47212;
        static let Lynx = 46615;

        static let WildBoar = 47926;
        static let EuropeanBeaver = 48251;
        static let Otter = 47169;
        static let Polecat = 47240;

        static let RingedSeal = 200555;
        static let GreySeal = 47282;

        static let BeanGoose = 26287;               // Metsähanhi
        static let CommonEider = 26419;             // Haahka
        static let Coot = 27381;                    // Nokikana
        static let Garganey = 26388;                // Heinätavi
        static let Goosander = 26442;               // Isokoskelo
        static let GreylagGoose = 26291;            // Merihanhi
        static let LongTailedDuck = 26427;          // Alli
        static let Pintail = 26382;                 // Jouhisorsa
        static let Pochard = 26407;                 // Punasotka
        static let RedBreastedMergander = 26440;    // Tukkakoskelo
        static let Shoveler = 26394;                // Lapasorsa
        static let TuftedDuck = 26415;              // Tukkasotka
        static let Wigeon = 26360;                  // Haapana

    }

    static let SrvaOtherCode = 999999

    static let HarvestMaxAmount = 9999
    static let ObservationMaxAmount = 9999
    static let SrvaMaxAmount = 999

    static let HarvestMaxAmountLength = 4
    static let ObservationMaxAmountLength = 4
    static let SrvaMaxAmountLength = 3

    static let MaxImageSizeDimen = 1024

    struct UI {
        static let DefaultButtonHeight: CGFloat = 60
        static let ButtonHeightSmall: CGFloat = 50
        static let DefaultToggleHeight: CGFloat = 50
        static let DefaultHorizontalInset: CGFloat = 12
        static let DefaultVerticalInset: CGFloat = 12

        // Just horizontal edge insets
        static let DefaultHorizontalEdgeInsets = UIEdgeInsets(top: 0, left: DefaultHorizontalInset,
                                                              bottom: 0, right: DefaultHorizontalInset)

        // All edge insets
        static let DefaultEdgeInsets = UIEdgeInsets(top: DefaultVerticalInset,
                                                    left: DefaultHorizontalInset,
                                                    bottom: DefaultVerticalInset,
                                                    right: DefaultHorizontalInset)
    }

    struct Animations {
        static let durationShort: Double = 0.15
        static let durationDefault: Double = 0.3
    }

    struct OccupationType {
        static let ShootingTestOfficial = "AMPUMAKOKEEN_VASTAANOTTAJA"
        static let Coordinator = "TOIMINNANOHJAAJA"
    }

    @objc enum AreaType: Int {
        case Moose
        case Pienriista
        case Valtionmaa
        case Rhy
        case GameTriangles
        case Seura
    }
}
