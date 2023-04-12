package fi.riista.common.domain.observation.ui.list

import co.touchlab.stately.ensureNeverFrozen
import fi.riista.common.domain.model.Species
import fi.riista.common.domain.model.getHuntingYear
import fi.riista.common.domain.observation.ObservationContext
import fi.riista.common.logging.getLogger
import fi.riista.common.metadata.MetadataProvider
import fi.riista.common.ui.controller.ControllerWithLoadableModel
import fi.riista.common.ui.controller.HasUnreproducibleState
import fi.riista.common.ui.controller.ViewModelLoadStatus
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.serialization.Serializable

class ListCommonObservationsController(
    private val metadataProvider: MetadataProvider,
    private val observationContext: ObservationContext,
    private val listOnlyObservationsWithImages: Boolean, // true for gallery
) : ControllerWithLoadableModel<ListCommonObservationsViewModel>(),
    HasUnreproducibleState<ListCommonObservationsController.FilterState> {

    init {
        ensureNeverFrozen()
    }

    private val allObservationSpecies: List<Species> by lazy {
        metadataProvider.observationMetadata.speciesMetadata.keys.map { Species.Known(it) }
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

    override fun createLoadViewModelFlow(refresh: Boolean): Flow<ViewModelLoadStatus<ListCommonObservationsViewModel>> = flow {
        // store the previously loaded viewmodel in case were just refreshing observations. We want to keep
        // the current filtering after all.
        val previouslyLoadedViewModel = getLoadedViewModelOrNull()

        emit(ViewModelLoadStatus.Loading)

        observationContext.observationProvider.fetch(refresh = refresh)

        val allObservations = observationContext.observationProvider.observations
        if (allObservations == null) {
            emit(ViewModelLoadStatus.LoadFailed)
            return@flow
        }
        val observationHuntingYears = observationContext.getObservationHuntingYears().sortedDescending()

        @Suppress("IfThenToElvis") // code is easier to read this way
        val viewModel = if (previouslyLoadedViewModel != null) {
            previouslyLoadedViewModel.copy(
                allObservations = allObservations,
                observationHuntingYears = observationHuntingYears,
                observationSpecies = allObservationSpecies
            ).filterEvents() // re-apply filtering based on current filters
        } else {
            ListCommonObservationsViewModel(
                allObservations = allObservations,
                observationHuntingYears = observationHuntingYears,
                observationSpecies = allObservationSpecies,
                filterHuntingYear = null,
                filterSpecies = null,
                filteredObservations = allObservations,
            ).filterEvents(
                withHuntingYear = restoredFilterState?.huntingYear ?: pendingFilter?.huntingYear,
                withSpecies = restoredFilterState?.species ?: pendingFilter?.species,
            )
        }

        pendingFilter = null
        restoredFilterState = null

        emit(ViewModelLoadStatus.Loaded(viewModel))
    }

    fun setFilters(huntingYear: Int, species: List<Species>) {
        val currentViewModel = getLoadedViewModelOrNull() ?: kotlin.run {
            logger.v { "Cannot filter now, no viewmodel. Adding as a pending filter." }
            pendingFilter = FilterState(
                huntingYear = huntingYear,
                species = species
            )
            return
        }

        updateViewModel(
            viewModel = currentViewModel.filterEvents(
                withHuntingYear = huntingYear,
                withSpecies = species
            )
        )

    }

    fun setHuntingYearFilter(huntingYear: Int) {
        val currentViewModel = getLoadedViewModelOrNull() ?: kotlin.run {
            logger.v { "Cannot filter hunting year now, no viewmodel. Adding as a pending filter." }
            pendingFilter = FilterState(
                huntingYear = huntingYear,
                species = pendingFilter?.species,
            )
            return
        }

        updateViewModel(
            viewModel = currentViewModel.filterEvents(withHuntingYear = huntingYear)
        )
    }

    fun setSpeciesFilter(species: List<Species>) {
        val currentViewModel = getLoadedViewModelOrNull() ?: kotlin.run {
            logger.v { "Cannot filter species now, no viewmodel. Adding as a pending filter." }
            pendingFilter = FilterState(
                huntingYear = pendingFilter?.huntingYear,
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
            viewModel = ListCommonObservationsViewModel(
                allObservations = currentViewModel.allObservations,
                observationHuntingYears = currentViewModel.observationHuntingYears,
                observationSpecies = currentViewModel.observationSpecies,
                filterHuntingYear = null,
                filterSpecies = null,
                filteredObservations = currentViewModel.allObservations,
            )
        )
    }

    private fun ListCommonObservationsViewModel.filterEvents(
        withHuntingYear: Int? = filterHuntingYear,
        withSpecies: List<Species>? = filterSpecies,
    ): ListCommonObservationsViewModel {
        return ListCommonObservationsViewModel(
            allObservations = this.allObservations,
            observationHuntingYears = this.observationHuntingYears,
            observationSpecies = this.observationSpecies,

            filterHuntingYear = withHuntingYear,
            filterSpecies = withSpecies,
            filteredObservations = allObservations.filter { observation ->
                if (listOnlyObservationsWithImages && observation.images.primaryImage == null) {
                    return@filter false
                }

                if (withHuntingYear != null && observation.pointOfTime.date.getHuntingYear() != withHuntingYear) {
                    return@filter false
                }

                if (withSpecies != null && withSpecies.isNotEmpty() && observation.species !in withSpecies) {
                    return@filter false
                }

                return@filter true
            }
        )
    }

    override fun getUnreproducibleState(): FilterState? {
        return getLoadedViewModelOrNull()?.let { viewModel ->
            FilterState(
                huntingYear = viewModel.filterHuntingYear,
                species = viewModel.filterSpecies,
            )
        }
    }

    override fun restoreUnreproducibleState(state: FilterState) {
        restoredFilterState = state
    }

    @Serializable
    data class FilterState(
        internal val huntingYear: Int?,
        internal val species: List<Species>?,
    )

    companion object {
        private val logger by getLogger(ListCommonObservationsController::class)
    }
}