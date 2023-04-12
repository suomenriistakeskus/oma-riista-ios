package fi.riista.common.domain.harvest.validation

import fi.riista.common.domain.harvest.model.CommonHarvestData
import fi.riista.common.domain.harvest.model.HarvestConstants
import fi.riista.common.domain.harvest.ui.CommonHarvestField
import fi.riista.common.domain.model.CommonLocation
import fi.riista.common.domain.model.GameAge
import fi.riista.common.domain.model.Gender
import fi.riista.common.domain.model.Species
import fi.riista.common.domain.permit.model.CommonPermit
import fi.riista.common.logging.getLogger
import fi.riista.common.model.isWithinPeriods
import fi.riista.common.ui.dataField.FieldSpecification
import fi.riista.common.util.LocalDateTimeProvider
import fi.riista.common.util.isNullOr


object CommonHarvestValidator {
    enum class Error {
        MISSING_LOCATION,
        MISSING_PERMIT_INFORMATION,
        MISSING_SPECIES,
        INVALID_SPECIES,
        SPECIES_NOT_WITHIN_PERMIT,
        INVALID_SPECIMEN_AMOUNT,
        MISSING_SPECIMENS,
        MISSING_DATE_AND_TIME,
        DATE_NOT_WITHIN_PERMIT, // either group hunting permit or common permit depending on context
        DATETIME_IN_FUTURE,
        MISSING_HUNTING_DAY,
        TIME_NOT_WITHIN_HUNTING_DAY,
        MISSING_DEER_HUNTING_TYPE,
        MISSING_DEER_HUNTING_OTHER_TYPE_DESCRIPTION,
        MISSING_ACTOR,
        MISSING_GENDER,
        MISSING_AGE,
        MISSING_ALONE,
        MISSING_NOT_EDIBLE,
        MISSING_WEIGHT_ESTIMATED,
        MISSING_WEIGHT_MEASURED,
        MISSING_FITNESS_CLASS,
        MISSING_ANTLERS_LOST,
        MISSING_ANTLERS_TYPE,
        MISSING_ANTLERS_WIDTH,
        MISSING_ANTLER_POINTS_LEFT,
        MISSING_ANTLER_POINTS_RIGHT,
        MISSING_ANTLERS_GIRTH,
        MISSING_ANTLER_SHAFT_WIDTH,
        MISSING_ANTLERS_LENGTH,
        MISSING_ANTLERS_INNER_WIDTH,
        MISSING_ADDITIONAL_INFORMATION,
        MISSING_DESCRIPTION,
        MISSING_WEIGHT,
        MISSING_WILD_BOAR_FEEDING_PLACE,
        MISSING_GREY_SEAL_HUNTING_METHOD,
        MISSING_TAIGA_BEAN_GOOSE,
    }

    private val logger by getLogger(CommonHarvestValidator::class)

    internal fun validate(
        harvest: CommonHarvestData,
        permit: CommonPermit?,
        localDateTimeProvider: LocalDateTimeProvider,
        displayedFields: List<FieldSpecification<CommonHarvestField>>,
    ): List<Error> {
        val specimen = harvest.specimens.getOrNull(0)

        val missingSpecimenError = if (specimen == null) {
            listOf(Error.MISSING_SPECIMENS)
        } else {
            emptyList()
        }

        return missingSpecimenError + displayedFields.mapNotNull { fieldSpecification ->
            when (fieldSpecification.fieldId) {
                CommonHarvestField.LOCATION -> {
                    fieldSpecification.ifRequired {
                        Error.MISSING_LOCATION.takeIf {
                            harvest.location is CommonLocation.Unknown
                        }
                    }
                }
                // either SELECT_PERMIT or PERMIT_INFORMATION would be ok here
                CommonHarvestField.SELECT_PERMIT ->
                    fieldSpecification.ifRequired {
                        Error.MISSING_PERMIT_INFORMATION.takeIf {
                            harvest.permitNumber == null
                        }
                    }
                CommonHarvestField.SPECIES_CODE,
                CommonHarvestField.SPECIES_CODE_AND_IMAGE ->
                    when (harvest.species) {
                        is Species.Known -> Error.SPECIES_NOT_WITHIN_PERMIT.takeIf {
                            permit != null && permit.isAvailableForSpecies(harvest.species).not()
                        }
                        Species.Other -> Error.INVALID_SPECIES // other species not allowed for harvests
                        Species.Unknown -> Error.MISSING_SPECIES.takeIf { fieldSpecification.isRequired() }
                    }
                CommonHarvestField.DATE_AND_TIME -> {
                    fieldSpecification.ifRequired {
                        @Suppress("SENSELESS_COMPARISON")
                        when {
                            // field is non-nullable currently but let's keep validation anyway in case
                            // field ever becomes nullable
                            harvest.pointOfTime == null -> Error.MISSING_DATE_AND_TIME
                            permit != null && !harvest.isWithinPermitValidityPeriods(permit) -> Error.DATE_NOT_WITHIN_PERMIT
                            harvest.pointOfTime > localDateTimeProvider.now() -> Error.DATETIME_IN_FUTURE
                            else -> null
                        }
                    }
                }
                CommonHarvestField.SPECIMEN_AMOUNT ->
                    fieldSpecification.ifRequired {
                        val specimenAmount = harvest.amount ?: 0
                        Error.INVALID_SPECIMEN_AMOUNT.takeIf {
                            specimenAmount == 0 || harvest.specimens.isEmpty()
                                    || specimenAmount > HarvestConstants.MAX_SPECIMEN_AMOUNT
                        }
                    }

                CommonHarvestField.SPECIMENS ->
                    fieldSpecification.ifRequired {
                        Error.MISSING_SPECIMENS.takeIf {
                            // TODO: Validating specimens (i.e. they need to have valid values)
                            harvest.specimens.isEmpty()
                        }
                    }
                CommonHarvestField.DEER_HUNTING_TYPE -> {
                    fieldSpecification.ifRequired {
                        Error.MISSING_DEER_HUNTING_TYPE.takeIf {
                            harvest.deerHuntingType.rawBackendEnumValue == null
                        }
                    }
                }
                CommonHarvestField.DEER_HUNTING_OTHER_TYPE_DESCRIPTION -> {
                    fieldSpecification.ifRequired {
                        Error.MISSING_DEER_HUNTING_OTHER_TYPE_DESCRIPTION.takeIf {
                            harvest.deerHuntingOtherTypeDescription == null
                        }
                    }
                }
                CommonHarvestField.ACTOR -> {
                    fieldSpecification.ifRequired {
                        Error.MISSING_ACTOR.takeIf {
                            harvest.actorInfo.personWithHunterNumber == null
                        }
                    }
                }
                CommonHarvestField.GENDER -> {
                    fieldSpecification.ifRequired {
                        Error.MISSING_GENDER.takeIf {
                            // require known gender
                            specimen != null && specimen.gender?.value.isNullOr(Gender.UNKNOWN)
                        }
                    }
                }
                CommonHarvestField.AGE -> {
                    fieldSpecification.ifRequired {
                        Error.MISSING_AGE.takeIf {
                            // require known age
                            specimen != null && specimen.age?.value.isNullOr(GameAge.UNKNOWN)
                        }
                    }
                }
                CommonHarvestField.ALONE -> {
                    fieldSpecification.ifRequired {
                        Error.MISSING_ALONE.takeIf {
                            specimen != null && specimen.alone == null
                        }
                    }
                }
                CommonHarvestField.NOT_EDIBLE -> {
                    fieldSpecification.ifRequired {
                        Error.MISSING_NOT_EDIBLE.takeIf {
                            specimen != null && specimen.notEdible == null
                        }
                    }
                }
                CommonHarvestField.WEIGHT_ESTIMATED -> {
                    fieldSpecification.ifRequired {
                        Error.MISSING_WEIGHT_ESTIMATED.takeIf {
                            specimen != null && specimen.weightEstimated == null
                        }
                    }
                }
                CommonHarvestField.WEIGHT_MEASURED -> {
                    fieldSpecification.ifRequired {
                        Error.MISSING_WEIGHT_MEASURED.takeIf {
                            specimen != null && specimen.weightMeasured == null
                        }
                    }
                }
                CommonHarvestField.FITNESS_CLASS -> {
                    fieldSpecification.ifRequired {
                        Error.MISSING_FITNESS_CLASS.takeIf {
                            specimen != null && specimen.fitnessClass?.rawBackendEnumValue == null
                        }
                    }

                }
                CommonHarvestField.ANTLERS_LOST -> {
                    fieldSpecification.ifRequired {
                        Error.MISSING_ANTLERS_LOST.takeIf {
                            specimen != null && specimen.antlersLost == null
                        }
                    }
                }
                CommonHarvestField.ANTLERS_TYPE -> {
                    fieldSpecification.ifRequired {
                        Error.MISSING_ANTLERS_TYPE.takeIf {
                            specimen != null && specimen.antlersType?.rawBackendEnumValue == null
                        }
                    }
                }
                CommonHarvestField.ANTLERS_WIDTH -> {
                    fieldSpecification.ifRequired {
                        Error.MISSING_ANTLERS_WIDTH.takeIf {
                            specimen != null && specimen.antlersWidth == null
                        }
                    }
                }
                CommonHarvestField.ANTLER_POINTS_LEFT -> {
                    fieldSpecification.ifRequired {
                        Error.MISSING_ANTLER_POINTS_LEFT.takeIf {
                            specimen != null && specimen.antlerPointsLeft == null
                        }
                    }
                }
                CommonHarvestField.ANTLER_POINTS_RIGHT -> {
                    fieldSpecification.ifRequired {
                        Error.MISSING_ANTLER_POINTS_RIGHT.takeIf {
                            specimen != null && specimen.antlerPointsRight == null
                        }
                    }
                }
                CommonHarvestField.ANTLERS_GIRTH -> {
                    fieldSpecification.ifRequired {
                        Error.MISSING_ANTLERS_GIRTH.takeIf {
                            specimen != null && specimen.antlersGirth == null
                        }
                    }
                }
                CommonHarvestField.ANTLER_SHAFT_WIDTH -> {
                    fieldSpecification.ifRequired {
                        Error.MISSING_ANTLER_SHAFT_WIDTH.takeIf {
                            specimen != null && specimen.antlerShaftWidth == null
                        }
                    }
                }
                CommonHarvestField.ANTLERS_LENGTH -> {
                    fieldSpecification.ifRequired {
                        Error.MISSING_ANTLERS_LENGTH.takeIf {
                            specimen != null && specimen.antlersLength == null
                        }
                    }
                }
                CommonHarvestField.ANTLERS_INNER_WIDTH -> {
                    fieldSpecification.ifRequired {
                        Error.MISSING_ANTLERS_INNER_WIDTH.takeIf {
                            specimen != null && specimen.antlersInnerWidth == null
                        }
                    }
                }
                CommonHarvestField.ADDITIONAL_INFORMATION -> {
                    fieldSpecification.ifRequired {
                        Error.MISSING_ADDITIONAL_INFORMATION.takeIf {
                            specimen != null && specimen.additionalInfo == null
                        }
                    }
                }
                CommonHarvestField.DESCRIPTION ->
                    fieldSpecification.ifRequired {
                        Error.MISSING_DESCRIPTION.takeIf {
                            harvest.description == null
                        }
                    }
                CommonHarvestField.WEIGHT ->
                    fieldSpecification.ifRequired {
                        Error.MISSING_WEIGHT.takeIf {
                            specimen != null && specimen.weight == null
                        }
                    }
                CommonHarvestField.WILD_BOAR_FEEDING_PLACE ->
                    fieldSpecification.ifRequired {
                        Error.MISSING_WILD_BOAR_FEEDING_PLACE.takeIf {
                            harvest.feedingPlace == null
                        }
                    }
                CommonHarvestField.GREY_SEAL_HUNTING_METHOD ->
                    fieldSpecification.ifRequired {
                        Error.MISSING_GREY_SEAL_HUNTING_METHOD.takeIf {
                            harvest.greySealHuntingMethod.rawBackendEnumValue == null
                        }
                    }
                CommonHarvestField.IS_TAIGA_BEAN_GOOSE ->
                    fieldSpecification.ifRequired {
                        Error.MISSING_TAIGA_BEAN_GOOSE.takeIf {
                            harvest.taigaBeanGoose == null
                        }
                    }

                // explicitly add the ones which don't need any validation
                CommonHarvestField.HARVEST_REPORT_STATE,
                CommonHarvestField.ACTOR_HUNTER_NUMBER,
                CommonHarvestField.ACTOR_HUNTER_NUMBER_INFO_OR_ERROR,
                CommonHarvestField.ANTLER_INSTRUCTIONS,
                CommonHarvestField.ADDITIONAL_INFORMATION_INSTRUCTIONS,
                CommonHarvestField.ERROR_DATE_NOT_WITHIN_PERMIT,
                CommonHarvestField.ERROR_DATETIME_IN_FUTURE,
                CommonHarvestField.ERROR_TIME_NOT_WITHIN_HUNTING_DAY,
                CommonHarvestField.HUNTING_DAY_AND_TIME,
                CommonHarvestField.HEADLINE_SHOOTER,
                CommonHarvestField.AUTHOR,
                CommonHarvestField.HEADLINE_SPECIMEN,
                CommonHarvestField.PERMIT_INFORMATION,
                CommonHarvestField.PERMIT_REQUIRED_NOTIFICATION -> {
                    null
                }
            }
        }.also { errors ->
            if (errors.isEmpty()) {
                logger.v { "Harvest is valid!" }
            } else {
                logger.d { "Harvest validation errors: $errors" }
            }
        }
    }

    private fun CommonHarvestData.isWithinPermitValidityPeriods(permit: CommonPermit): Boolean {
        // no species amounts --> harvest cannot be within permit validity periods
        val speciesAmounts = permit.getSpeciesAmountFor(species) ?: return false

        return pointOfTime.date.isWithinPeriods(speciesAmounts.validityPeriods)
    }
}
