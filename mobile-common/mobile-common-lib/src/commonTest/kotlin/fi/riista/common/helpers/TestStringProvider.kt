package fi.riista.common.helpers

import fi.riista.common.resources.*

class TestStringProvider: StringProvider {

    override fun getString(stringId: RR.string): String {
        return when (stringId) {
            RR.string.generic_yes -> "yes"
            RR.string.generic_no -> "no"
            RR.string.error_date_not_allowed -> "error_date_not_allowed"
            RR.string.group_hunting_label_club -> "club"
            RR.string.group_hunting_label_season -> "season"
            RR.string.group_hunting_label_species -> "species"
            RR.string.group_hunting_label_hunting_group -> "hunting_group"
            RR.string.group_hunting_error_hunting_has_finished -> "hunting_has_finished"
            RR.string.group_hunting_error_time_not_within_hunting_day -> "error_time_not_within_hunting_day"
            RR.string.group_hunting_harvest_field_hunting_day_and_time -> "hunting_day_and_time"
            RR.string.group_hunting_harvest_field_actor -> "actor"
            RR.string.group_hunting_harvest_field_author -> "author"
            RR.string.group_hunting_harvest_field_deer_hunting_type -> "deer_hunting_type"
            RR.string.group_hunting_harvest_field_deer_hunting_other_type_description -> "deer_hunting_other_type_description"
            RR.string.group_hunting_harvest_field_not_edible -> "not_edible"
            RR.string.group_hunting_harvest_field_weight_estimated -> "weight_estimated"
            RR.string.group_hunting_harvest_field_weight_measured -> "weight_measured"
            RR.string.group_hunting_harvest_field_fitness_class -> "fitness_class"
            RR.string.group_hunting_harvest_field_antlers_type -> "antlers_type"
            RR.string.group_hunting_harvest_field_antlers_width -> "antlers_width"
            RR.string.group_hunting_harvest_field_antler_points_left -> "antler_points_left"
            RR.string.group_hunting_harvest_field_antler_points_right -> "antler_points_right"
            RR.string.group_hunting_harvest_field_antlers_lost -> "antlers_lost"
            RR.string.group_hunting_harvest_field_antlers_girth -> "antlers_girth"
            RR.string.group_hunting_harvest_field_antler_shaft_width -> "antler_shaft_width"
            RR.string.group_hunting_harvest_field_antlers_length -> "antlers_length"
            RR.string.group_hunting_harvest_field_antlers_inner_width -> "antlers_inner_width"
            RR.string.group_hunting_harvest_field_alone -> "alone"
            RR.string.group_hunting_harvest_field_additional_information -> "additional_information"
            RR.string.group_hunting_harvest_field_additional_information_instructions -> "additional_information_instructions"
            RR.string.group_hunting_harvest_field_additional_information_instructions_white_tailed_deer -> "additional_information_instructions_white_tailed_deer"
            RR.string.group_hunting_observation_field_hunting_day_and_time -> "hunting_day_and_time"
            RR.string.group_hunting_observation_field_observation_type -> "observation_type"
            RR.string.group_hunting_observation_field_actor -> "actor"
            RR.string.group_hunting_observation_field_author -> "author"
            RR.string.group_hunting_observation_field_headline_specimen_details -> "specimen_details"
            RR.string.group_hunting_observation_field_mooselike_male_amount -> "male_amount"
            RR.string.group_hunting_observation_field_mooselike_female_amount -> "female_amount"
            RR.string.group_hunting_observation_field_mooselike_female_1calf_amount -> "female_1calf_amount"
            RR.string.group_hunting_observation_field_mooselike_female_2calf_amount -> "female_2calf_amount"
            RR.string.group_hunting_observation_field_mooselike_female_3calf_amount -> "female_3calf_amount"
            RR.string.group_hunting_observation_field_mooselike_female_4calf_amount -> "female_4calf_amount"
            RR.string.group_hunting_observation_field_mooselike_calf_amount -> "calf_amount"
            RR.string.group_hunting_observation_field_mooselike_unknown_specimen_amount -> "unknown_specimen_amount"
            RR.string.group_hunting_observation_field_mooselike_male_amount_within_deer_hunting -> "male_amount_within_deer_hunting"
            RR.string.group_hunting_observation_field_mooselike_female_amount_within_deer_hunting -> "female_amount_within_deer_hunting"
            RR.string.group_hunting_observation_field_mooselike_female_1calf_amount_within_deer_hunting -> "female_1calf_amount_within_deer_hunting"
            RR.string.group_hunting_observation_field_mooselike_female_2calf_amount_within_deer_hunting -> "female_2calf_amount_within_deer_hunting"
            RR.string.group_hunting_observation_field_mooselike_female_3calf_amount_within_deer_hunting -> "female_3calf_amount_within_deer_hunting"
            RR.string.group_hunting_observation_field_mooselike_female_4calf_amount_within_deer_hunting -> "female_4calf_amount_within_deer_hunting"
            RR.string.group_hunting_observation_field_mooselike_calf_amount_within_deer_hunting -> "calf_amount_within_deer_hunting"
            RR.string.group_hunting_observation_field_mooselike_unknown_specimen_amount_within_deer_hunting -> "unknown_specimen_amount_within_deer_hunting"
            RR.string.group_hunting_day_label_start_date_and_time -> "start_date_and_time"
            RR.string.group_hunting_day_label_end_date_and_time -> "end_date_and_time"
            RR.string.group_hunting_day_label_number_of_hunters -> "number_of_hunters"
            RR.string.group_hunting_day_label_hunting_method -> "hunting_method"
            RR.string.group_hunting_day_label_number_of_hounds -> "number_of_hounds"
            RR.string.group_hunting_day_label_snow_depth_centimeters -> "snow_depth_centimeters"
            RR.string.group_hunting_day_label_break_duration_minutes -> "break_duration_minutes"
            RR.string.group_hunting_day_no_breaks -> "no_breaks"
            RR.string.group_hunting_day_error_dates_not_within_permit -> "error_dates_not_within_permit"
            RR.string.group_hunting_message_no_hunting_days_but_can_create -> "no_hunting_days_but_can_create"
            RR.string.group_hunting_message_no_hunting_days -> "no_hunting_days"
            RR.string.group_hunting_message_no_hunting_days_deer -> "no_hunting_days_deer"
            RR.string.group_hunting_method_passilinja_koira_ohjaajineen_metsassa -> "passilinja_koira_ohjaajineen_metsassa"
            RR.string.group_hunting_method_hiipiminen_pysayttavalle_koiralle -> "hiipiminen_pysayttavalle_koiralle"
            RR.string.group_hunting_method_passilinja_ja_tiivis_ajoketju -> "passilinja_ja_tiivis_ajoketju"
            RR.string.group_hunting_method_passilinja_ja_miesajo_jaljityksena -> "passilinja_ja_miesajo_jaljityksena"
            RR.string.group_hunting_method_jaljitys_eli_naakiminen_ilman_passeja -> "jaljitys_eli_naakiminen_ilman_passeja"
            RR.string.group_hunting_method_vaijynta_kulkupaikoilla -> "vaijynta_kulkupaikoilla"
            RR.string.group_hunting_method_vaijynta_ravintokohteilla -> "vaijynta_ravintokohteilla"
            RR.string.group_hunting_method_houkuttelu -> "houkuttelu"
            RR.string.group_hunting_method_muu -> "muu"
            RR.string.group_hunting_proposed_group_harvest_specimen -> "specimen"
            RR.string.group_hunting_proposed_group_harvest_shooter -> "shooter"
            RR.string.group_hunting_proposed_group_harvest_actor -> "actor"
            RR.string.group_member_selection_select_hunter -> "select_hunter"
            RR.string.group_member_selection_select_observer -> "select_observer"
            RR.string.group_member_selection_search_by_name -> "search_by_name"
            RR.string.group_member_selection_name_hint -> "name_hint"
            RR.string.group_hunting_hunter_id -> "hunter_id"
            RR.string.group_hunting_enter_hunter_id -> "enter_hunter_id"
            RR.string.group_hunting_invalid_hunter_id -> "invalid_hunter_id"
            RR.string.group_hunting_searching_hunter_by_id -> "searching_hunter_by_id"
            RR.string.group_hunting_searching_observer_by_id -> "searching_observer_by_id"
            RR.string.group_hunting_hunter_search_failed -> "hunter_search_failed"
            RR.string.group_hunting_observer_search_failed -> "observer_search_failed"
            RR.string.group_hunting_other_hunter -> "other_hunter"
            RR.string.group_hunting_other_observer -> "other_observer"
            RR.string.deer_hunting_type_stand_hunting -> "stand_hunting"
            RR.string.deer_hunting_type_dog_hunting -> "dog_hunting"
            RR.string.deer_hunting_type_other -> "other"
            RR.string.harvest_antler_type_hanko -> "antler_type_hanko"
            RR.string.harvest_antler_type_lapio -> "antler_type_lapio"
            RR.string.harvest_antler_type_seka -> "antler_type_seka"
            RR.string.harvest_fitness_class_erinomainen -> "fitness_class_erinomainen"
            RR.string.harvest_fitness_class_normaali -> "fitness_class_normaali"
            RR.string.harvest_fitness_class_laiha -> "fitness_class_laiha"
            RR.string.harvest_fitness_class_naantynyt -> "fitness_class_naantynyt"
            RR.string.observation_type_nako -> "nako"
            RR.string.observation_type_jalki -> "jalki"
            RR.string.observation_type_uloste -> "uloste"
            RR.string.observation_type_aani -> "aani"
            RR.string.observation_type_riistakamera -> "riistakamera"
            RR.string.observation_type_koiran_riistatyo -> "koiran_riistatyo"
            RR.string.observation_type_maastolaskenta -> "maastolaskenta"
            RR.string.observation_type_kolmiolaskenta -> "kolmiolaskenta"
            RR.string.observation_type_lentolaskenta -> "lentolaskenta"
            RR.string.observation_type_haaska -> "haaska"
            RR.string.observation_type_syonnos -> "syonnos"
            RR.string.observation_type_kelomispuu -> "kelomispuu"
            RR.string.observation_type_kiimakuoppa -> "kiimakuoppa"
            RR.string.observation_type_makuupaikka -> "makuupaikka"
            RR.string.observation_type_pato -> "pato"
            RR.string.observation_type_pesa -> "pesa"
            RR.string.observation_type_pesa_keko -> "pesa_keko"
            RR.string.observation_type_pesa_penkka -> "pesa_penkka"
            RR.string.observation_type_pesa_seka -> "pesa_seka"
            RR.string.observation_type_soidin -> "soidin"
            RR.string.observation_type_luolasto -> "luolasto"
            RR.string.observation_type_pesimaluoto -> "pesimaluoto"
            RR.string.observation_type_lepailyluoto -> "lepailyluoto"
            RR.string.observation_type_pesimasuo -> "pesimasuo"
            RR.string.observation_type_muuton_aikainen_lepailyalue -> "muuton_aikainen_lepailyalue"
            RR.string.observation_type_riistankulkupaikka -> "riistankulkupaikka"
            RR.string.observation_type_poikueymparisto -> "poikueymparisto"
            RR.string.observation_type_vaihtelevarakenteinen_mustikkametsa -> "vaihtelevarakenteinen_mustikkametsa"
            RR.string.observation_type_kuusisekoitteinen_metsa -> "kuusisekoitteinen_metsa"
            RR.string.observation_type_vaihtelevarakenteinen_mantysekoitteinen_metsa -> "vaihtelevarakenteinen_mantysekoitteinen_metsa"
            RR.string.observation_type_vaihtelevarakenteinen_lehtipuusekoitteinen_metsa -> "vaihtelevarakenteinen_lehtipuusekoitteinen_metsa"
            RR.string.observation_type_suon_reunametsa -> "suon_reunametsa"
            RR.string.observation_type_hakomamanty -> "hakomamanty"
            RR.string.observation_type_ruokailukoivikko -> "ruokailukoivikko"
            RR.string.observation_type_leppakuusimetsa_tai_koivikuusimetsa -> "leppakuusimetsa_tai_koivikuusimetsa"
            RR.string.observation_type_ruokailupajukko_tai_koivikko -> "ruokailupajukko_tai_koivikko"
            RR.string.observation_type_muu -> "muu"
            RR.string.hunting_club_membership_invitations -> "membership_invitations"
            RR.string.hunting_club_memberships -> "memberships"
            RR.string.poi_location_group_type_sighting_place -> "sighting_place"
            RR.string.poi_location_group_type_mineral_lick -> "mineral_lick"
            RR.string.poi_location_group_type_feeding_place -> "feeding_place"
            RR.string.poi_location_group_type_other -> "other"
            else -> throw RuntimeException("Unexpected stringId ($stringId) requested")
        }
    }

    override fun getFormattedString(stringFormatId: RR.stringFormat, arg: String): String {
        return when (stringFormatId) {
            RR.stringFormat.group_hunting_label_permit_formatted -> "permit: $arg"
            else -> throw RuntimeException("Unexpected stringFormatId ($stringFormatId) requested")
        }
    }

    override fun getFormattedString(stringFormatId: RR.stringFormat, arg1: String, arg2: String): String {
        return when (stringFormatId) {
            RR.stringFormat.generic_hours_and_minutes_format -> "%s %s"
            else -> throw RuntimeException("Unexpected stringFormatId ($stringFormatId) requested")
        }
    }

    override fun getQuantityString(pluralsId: RR.plurals, quantity: Int, arg: Int): String {
        return when (pluralsId) {
            RR.plurals.hours -> if (quantity == 1) {
                "$arg hour"
            } else {
                "$arg hours"
            }
            RR.plurals.minutes -> if (quantity == 1) {
                "$arg minute"
            } else {
                "$arg minutes"
            }
            else -> throw RuntimeException("Unexpected pluralsId ($pluralsId) requested")
        }
    }

    companion object {
        val INSTANCE = TestStringProvider()
    }
}