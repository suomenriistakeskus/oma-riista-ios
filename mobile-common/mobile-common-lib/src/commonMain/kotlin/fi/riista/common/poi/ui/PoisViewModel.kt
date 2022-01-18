package fi.riista.common.poi.ui

import fi.riista.common.poi.model.PoiLocationGroup

data class PoisViewModel(
    val pois: PoiViewModel?
)

data class PoiViewModel(
    val filter: PoiFilter,
    val filteredPois: List<PoiLocationGroup>,
    val allPois: List<PoiLocationGroup>,
)
