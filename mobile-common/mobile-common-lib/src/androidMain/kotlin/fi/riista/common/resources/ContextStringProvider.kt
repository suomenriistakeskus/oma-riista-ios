package fi.riista.common.resources

import android.content.Context

/**
 * A [StringProvider] that gets the string from the specified [context].
 *
 * The common library [RR.string] is mapped to android string resource id by
 * the given [StringIdMapper]
 */
class ContextStringProvider(
    private val context: Context,
    private val stringIdMapper: StringIdMapper,
): StringProvider {
    override fun getString(stringId: RR.string): String {
        return context.getString(stringIdMapper.mapToStringResourceId(stringId))
    }

    override fun getFormattedString(stringFormatId: RR.stringFormat, arg: String): String {
        return context.getString(
            stringIdMapper.mapToStringFormatResourceId(stringFormatId), arg
        )
    }

    override fun getFormattedString(stringFormatId: RR.stringFormat, arg1: String, arg2: String): String {
        return context.getString(
            stringIdMapper.mapToStringFormatResourceId(stringFormatId), arg1, arg2
        )
    }

    override fun getQuantityString(pluralsId: RR.plurals, quantity: Int, arg: Int): String {
        return context.resources.getQuantityString(
            stringIdMapper.mapToPluralsResourceId(pluralsId), quantity, arg)
    }
}