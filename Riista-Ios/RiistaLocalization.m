#import "RiistaLocalization.h"
#import "RiistaSettings.h"

@interface RiistaLocalization ()

@property (nonatomic, retain) NSDictionary *valueMappings;

@end

@implementation RiistaLocalization

@synthesize valueMappings;

static RiistaLocalization* _sharedInstance = nil;
static NSBundle *_bundle = nil;

+ (RiistaLocalization*)sharedInstance
{
    @synchronized([RiistaLocalization class])
    {
        if (!_sharedInstance){
            // Ignore return value.
            (void) [[self alloc] init];
        }
        return _sharedInstance;
    }
    return nil;
}

+(id)alloc
{
    @synchronized([RiistaLocalization class])
    {
        NSAssert(_sharedInstance == nil, @"Attempted to allocate a second instance of a singleton.");
        _sharedInstance = [super alloc];
        return _sharedInstance;
    }
    // to avoid compiler warning
    return nil;
}


- (id)init
{
    if ((self = [super init]))
    {
        [self setupValueMappings];
        [self setLanguageFromSettings];
    }
    return self;
}

// Acts like NSLocalizedString.
- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)comment
{
    return [_bundle localizedStringForKey:key value:key table:nil];
}

- (NSString *)mappedValueStringForKey:(NSString *)key value:(NSString *)comment
{
    NSString *mappedKey = [self.valueMappings valueForKey:key];
    if (mappedKey == nil) {
        return key;
    }

    return [_bundle localizedStringForKey:mappedKey value:mappedKey table:@"MappedValue"];
}

- (void) setLanguageFromSettings
{
    NSString* languageSetting = [RiistaSettings language];
    [self setLanguage:languageSetting];
}

- (void) setLanguage:(NSString*) newLanguage
{
    NSString *path = nil;
    if ([newLanguage isEqualToString:RiistaDefaultAppLanguage])
    {
        // English localization in Base
        path = [[ NSBundle mainBundle ] pathForResource:@"Base" ofType:@"lproj" ];
    } else {
        path = [[ NSBundle mainBundle ] pathForResource:newLanguage ofType:@"lproj" ];
    }

    if (path == nil)
    {
        //in case the language does not exists
        [self resetLocalization];
    } else {
        _bundle = [NSBundle bundleWithPath:path];
    }
}

// May not be reliable since iOS9. Preferredlanguages not updated for bundles initialized after app start?
// Check functionality if using this.
- (NSString*) getLanguage
{
    NSArray* languages = _bundle.preferredLocalizations;
    NSString *preferredLang = [languages firstObject];

    return preferredLang;
}

// Reset localization to OS default.
- (void) resetLocalization
{
    _bundle = [NSBundle mainBundle];
}

- (void) setupValueMappings
{
    self.valueMappings = [[NSDictionary alloc]
                          initWithObjectsAndKeys:@"observation_unknown", @"UNKNOWN",
                                               @"observation_type_sight", @"NAKO",
                                               @"observation_type_track", @"JALKI",
                                               @"observation_type_excrement", @"ULOSTE",
                                               @"observation_type_sound", @"AANI",
                                               @"observation_type_game_camera", @"RIISTAKAMERA",
                                               @"observation_type_dog", @"KOIRAN_RIISTATYO",
                                               @"observation_type_ground_count", @"MAASTOLASKENTA",
                                               @"observation_type_triangulation_count", @"KOLMIOLASKENTA",
                                               @"observation_type_air_count", @"LENTOLASKENTA",
                                               @"observation_type_carcass", @"HAASKA",
                                               @"observation_type_feeding", @"SYONNOS",
                                               @"observation_type_kelomispuu", @"KELOMISPUU",
                                               @"observation_type_kiimakuoppa", @"KIIMAKUOPPA",
                                               @"observation_type_laying_location", @"MAKUUPAIKKA",
                                               @"observation_type_nest", @"PESA",
                                               @"observation_type_nest_mound", @"PESA_KEKO",
                                               @"observation_type_nest_bank", @"PESA_PENKKA",
                                               @"observation_type_nest_mixed", @"PESA_SEKA",
                                               @"observation_type_dam", @"PATO",
                                               @"observation_type_soidin", @"SOIDIN",
                                               @"observation_type_caves", @"LUOLASTO",
                                               @"observation_type_nesting_islet", @"PESIMALUOTO",
                                               @"observation_type_resting_islet", @"LEPAILYLUOTO",
                                               @"observation_type_nesting_swamp", @"PESIMASUO",
                                               @"observation_type_migration_resting_area", @"MUUTON_AIKAINEN_LEPAILYALUE",
                                               @"observation_type_game_path", @"RIISTANKULKUPAIKKA",
                                               @"observation_type_poikueymparisto", @"POIKUEYMPARISTO",
                                               @"observation_type_vaihtelevarakenteinen_mustikkametsa", @"VAIHTELEVARAKENTEINEN_MUSTIKKAMETSA",
                                               @"observation_type_vaihtelevarakenteinen_mantysekotteinen_metsa", @"VAIHTELEVARAKENTEINEN_MANTYSEKOTTEINEN_METSA",
                                               @"observation_type_hakomamanty", @"HAKOMAMANTY",
                                               @"observation_type_vaihtelevarakenteinen_lehtipuusekotteinen_metsa", @"VAIHTELEVARAKENTEINEN_LEHTIPUUSEKOTTEINEN_METSA",
                                               @"observation_type_ruokailukoivikko", @"RUOKAILUKOIVIKKO",
                                               @"observation_type_leppakuusimetsa_tai_koivukuusimetsä", @"LEPPAKUUSIMETSA_TAI_KOIVUKUUSIMETSA",
                                               @"observation_type_kuusisekotteinen_metsa", @"KUUSISEKOTTEINEN_METSA",
                                               @"observation_type_suon_reunametsa", @"SUON_REUNAMETSA",
                                               @"observation_type_ruokailupajukko_tai_koivikko", @"RUOKAILUPAJUKKO_TAI_KOIVIKKO",
                                               @"observation_type_other", @"MUU",

                                               @"observation_deer_hunting_type_stand_hunting", @"STAND_HUNTING",
                                               @"observation_deer_hunting_type_dog_hunting", @"DOG_HUNTING",
                                               @"observation_deer_hunting_type_other", @"OTHER",

                                               @"observation_age_adult", @"ADULT",
                                               @"observation_age_less_than_year", @"LT1Y",
                                               @"observation_age_less_than_year", @"YOUNG", //SRVA age constant
                                               @"observation_age_year_or_two", @"_1TO2Y",
                                               @"observation_age_eraus", @"ERAUS",
                                               @"srva_age_young", @"YOUNG",

                                               @"observation_state_healthy", @"HEALTHY",
                                               @"observation_state_ill", @"ILL",
                                               @"observation_state_wounded", @"WOUNDED",
                                               @"observation_state_carcass", @"CARCASS",
                                               @"observation_state_dead", @"DEAD",

                                               @"observation_marked_none", @"NOT_MARKED",
                                               @"observation_marked_collar", @"COLLAR_OR_RADIO_TRANSMITTER",
                                               @"observation_marked_ring", @"LEG_RING_OR_WING_TAG",
                                               @"observation_marked_ear", @"EARMARK",

                                               @"harvest_moose_fitness_class_excellent", @"ERINOMAINEN",
                                               @"harvest_moose_fitness_class_normal", @"NORMAALI",
                                               @"harvest_moose_fitness_class_thin", @"LAIHA",
                                               @"harvest_moose_fitness_class_starved", @"NAANTYNYT",

                                               @"harvest_moose_antlers_type_hanko", @"HANKO",
                                               @"harvest_moose_antlers_type_lapio", @"LAPIO",
                                               @"harvest_moose_antlers_type_seka", @"SEKA",

                                               @"harvest_hunting_type_shot", @"SHOT",
                                               @"harvest_hunting_type_captured_alive", @"CAPTURED_ALIVE",
                                               @"harvest_hunting_type_shot_but_lost", @"SHOT_BUT_LOST",

                                               @"srva_accident", @"ACCIDENT",
                                               @"srva_deportation", @"DEPORTATION",
                                               @"srva_sick_animal", @"SICK_ANIMAL", //Not a "real" constant

                                               @"srva_animal_at_food_destination", @"ANIMAL_AT_FOOD_DESTINATION",
                                               @"srva_animal_near_houses", @"ANIMAL_NEAR_HOUSES_AREA",
                                               @"srva_animal_on_ice", @"ANIMAL_ON_ICE",
                                               @"srva_injured_animal", @"INJURED_ANIMAL",
                                               @"srva_other", @"OTHER",
                                               @"srva_railway_accident", @"RAILWAY_ACCIDENT",
                                               @"srva_traffic_accident", @"TRAFFIC_ACCIDENT",

                                               @"srva_method_dog", @"DOG",
                                               @"srva_method_pain_equipment", @"PAIN_EQUIPMENT",
                                               @"srva_method_sound_equipment", @"SOUND_EQUIPMENT",
                                               @"srva_method_traced_with_dog", @"TRACED_WITH_DOG",
                                               @"srva_method_traced_without_dog", @"TRACED_WITHOUT_DOG",

                                               @"srva_accident_site_not_found", @"ACCIDENT_SITE_NOT_FOUND",
                                               @"srva_animal_found_dead", @"ANIMAL_FOUND_DEAD",
                                               @"srva_animal_deported", @"ANIMAL_DEPORTED",
                                               @"srva_animal_found_and_terminated", @"ANIMAL_FOUND_AND_TERMINATED",
                                               @"srva_animal_not_found", @"ANIMAL_NOT_FOUND",
                                               @"srva_animal_terminated", @"ANIMAL_TERMINATED",
                                               @"srva_animal_found_and_not_terminated", @"ANIMAL_FOUND_AND_NOT_TERMINATED",
                                               @"srva_undue_alarm", @"UNDUE_ALARM",
                                               nil];
}

@end
