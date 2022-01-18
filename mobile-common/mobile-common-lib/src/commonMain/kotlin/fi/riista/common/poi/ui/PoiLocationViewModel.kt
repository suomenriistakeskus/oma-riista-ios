package fi.riista.common.poi.ui

import fi.riista.common.model.ETRMSGeoLocation

data class PoiLocationsViewModel(
    val selectedIndex: Int,
    val poiLocations: List<PoiLocationViewModel>,
) {
    /**
     * Return true if other model is otherwise identical except selectedIndex.
     */
    fun hasSamePoiLocations(other: PoiLocationsViewModel): Boolean {
        return poiLocations == other.poiLocations
    }
}

data class PoiLocationViewModel(
    val groupVisibleId: Int,
    val groupDescription: String?,
    val id: Long,
    val visibleId: Int,
    val description: String?,
    val location: ETRMSGeoLocation,
)
