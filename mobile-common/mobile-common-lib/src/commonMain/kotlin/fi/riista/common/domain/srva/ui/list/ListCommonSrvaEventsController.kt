package fi.riista.common.domain.srva.ui.list

import co.touchlab.stately.ensureNeverFrozen
import fi.riista.common.domain.model.Species
import fi.riista.common.domain.srva.SrvaContext
import fi.riista.common.logging.getLogger
import fi.riista.common.metadata.MetadataProvider
import fi.riista.common.ui.controller.ControllerWithLoadableModel
import fi.riista.common.ui.controller.HasUnreproducibleState
import fi.riista.common.ui.controller.ViewModelLoadStatus
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.serialization.Serializable

class ListCommonSrvaEventsController(
    private val metadataProvider: MetadataProvider,
    private val srvaContext: SrvaContext,
    private val listOnlySrvaEventsWithImages: Boolean, // true for gallery
) : ControllerWithLoadableModel<ListCommonSrvaEventsViewModel>(),
    HasUnreproducibleState<ListCommonSrvaEventsController.FilterState> {

    init {
        ensureNeverFrozen()
    }

    private val allSrvaSpecies: List<Species> by lazy {
        metadataProvider.srvaMetadata.species + Species.Other
    }

    /**
     * Pending filter to be applied once view model is loaded. Only taken into account if viewmodel
     * has not been loaded when [loadViewModel] is called.
     *
     * Same thing could probably be achieved using [restoredFilterState] but that is conceptually
     * not meant for this purpose.
     */
    private var pendingFilter: FilterState? = null

    private var restoredFilterState: FilterState? = null

    override fun createLoadViewModelFlow(refresh: Boolean): Flow<ViewModelLoadStatus<ListCommonSrvaEventsViewModel>> = flow {
        // store the previously loaded viewmodel in case were just refreshing srvas. We want to keep
        // the current filtering after all.
        val previouslyLoadedViewModel = getLoadedViewModelOrNull()

        emit(ViewModelLoadStatus.Loading)

        srvaContext.srvaEventProvider.fetch(refresh = refresh)

        val allSrvaEvents = srvaContext.srvaEventProvider.srvaEvents
        if (allSrvaEvents == null) {
            emit(ViewModelLoadStatus.LoadFailed)
            return@flow
        }
        val srvaEventYears = srvaContext.getSrvaYears().sortedDescending()

        @Suppress("IfThenToElvis") // code is easier to read this way
        val viewModel = if (previouslyLoadedViewModel != null) {
            previouslyLoadedViewModel.copy(
                allSrvaEvents = allSrvaEvents,
                srvaEventYears = srvaEventYears,
                srvaSpecies = allSrvaSpecies
            ).filterEvents() // re-apply filtering based on current filters
        } else {
            ListCommonSrvaEventsViewModel(
                allSrvaEvents = allSrvaEvents,
                srvaEventYears = srvaEventYears,
                srvaSpecies = allSrvaSpecies,
                filterYear = null,
                filterSpecies = null,
                filteredSrvaEvents = allSrvaEvents,
            ).filterEvents(
                withYear = restoredFilterState?.year ?: pendingFilter?.year,
                withSpecies = restoredFilterState?.species ?: pendingFilter?.species,
            )
        }

        pendingFilter = null
        restoredFilterState = null

        emit(ViewModelLoadStatus.Loaded(viewModel))
    }

    fun setFilters(year: Int, species: List<Species>) {
        val currentViewModel = getLoadedViewModelOrNull() ?: kotlin.run {
            logger.v { "Cannot filter now, no viewmodel. Adding as a pending filter." }
            pendingFilter = FilterState(
                year = year,
                species = species
            )
            return
        }

        updateViewModel(
            viewModel = currentViewModel.filterEvents(
                withYear = year,
                withSpecies = species
            )
        )

    }

    fun setYearFilter(year: Int) {
        val currentViewModel = getLoadedViewModelOrNull() ?: kotlin.run {
            logger.v { "Cannot filter year now, no viewmodel. Adding as a pending filter." }
            pendingFilter = FilterState(
                year = year,
                species = pendingFilter?.species,
            )
            return
        }

        updateViewModel(
            viewModel = currentViewModel.filterEvents(withYear = year)
        )
    }

    fun setSpeciesFilter(species: List<Species>) {
        val currentViewModel = getLoadedViewModelOrNull() ?: kotlin.run {
            logger.v { "Cannot filter species now, no viewmodel. Adding as a pending filter." }
            pendingFilter = FilterState(
                year = pendingFilter?.year,
                species = species,
            )
            return
        }

        updateViewModel(
            viewModel = currentViewModel.filterEvents(withSpecies = species)
        )
    }

    fun clearAllFilters() {
        val currentViewModel = getLoadedViewModelOrNull() ?: kotlin.run {
            logger.v { "Cannot clear filters now, no viewmodel. Clearing pending filter." }
            pendingFilter = null
            return
        }

        updateViewModel(
            viewModel = ListCommonSrvaEventsViewModel(
                allSrvaEvents = currentViewModel.allSrvaEvents,
                srvaEventYears = currentViewModel.srvaEventYears,
                srvaSpecies = currentViewModel.srvaSpecies,
                filterYear = null,
                filterSpecies = null,
                filteredSrvaEvents = currentViewModel.allSrvaEvents,
            )
        )
    }

    private fun ListCommonSrvaEventsViewModel.filterEvents(
        withYear: Int? = filterYear,
        withSpecies: List<Species>? = filterSpecies,
    ): ListCommonSrvaEventsViewModel {
        return ListCommonSrvaEventsViewModel(
            allSrvaEvents = this.allSrvaEvents,
            srvaEventYears = this.srvaEventYears,
            srvaSpecies = this.srvaSpecies,

            filterYear = withYear,
            filterSpecies = withSpecies,
            filteredSrvaEvents = allSrvaEvents.filter { srvaEvent ->
                if (listOnlySrvaEventsWithImages && srvaEvent.images.primaryImage == null) {
                    return@filter false
                }

                if (withYear != null && srvaEvent.pointOfTime.year != withYear) {
                    return@filter false
                }

                if (withSpecies != null && withSpecies.isNotEmpty() && srvaEvent.species !in withSpecies) {
                    return@filter false
                }

                return@filter true
            }
        )
    }

    override fun getUnreproducibleState(): FilterState? {
        return getLoadedViewModelOrNull()?.let { viewModel ->
            FilterState(
                year = viewModel.filterYear,
                species = viewModel.filterSpecies,
            )
        }
    }

    override fun restoreUnreproducibleState(state: FilterState) {
        restoredFilterState = state
    }

    @Serializable
    data class FilterState(
        internal val year: Int?,
        internal val species: List<Species>?,
    )

    companion object {
        private val logger by getLogger(ListCommonSrvaEventsController::class)
    }
}