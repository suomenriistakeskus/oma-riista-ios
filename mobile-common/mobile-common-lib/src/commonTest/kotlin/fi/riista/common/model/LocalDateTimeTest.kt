package fi.riista.common.model

import fi.riista.common.dto.toLocalDateTime
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class LocalDateTimeTest {

    @Test
    fun testParsingLocalDateTimes() {
        assertEquals(LocalDateTime(2021, 1, 1, 6, 0, 0), "2021-01-01T06:00".toLocalDateTime())
        assertEquals(LocalDateTime(2021, 1, 1, 6, 0, 0), "2021-01-01T06:00:00".toLocalDateTime())
        assertEquals(LocalDateTime(2021, 5, 30, 7, 30, 0), "2021-05-30T07:30".toLocalDateTime())
        assertEquals(LocalDateTime(2021, 5, 30, 7, 30, 0), "2021-05-30T07:30:00".toLocalDateTime())
        assertEquals(LocalDateTime(2021, 12, 31, 8, 45, 30), "2021-12-31T08:45:30".toLocalDateTime())
    }

    @Test
    fun testConvertingToString() {
        assertEquals("2021-01-01T06:00", LocalDateTime(2021, 1, 1, 6, 0, 0).toString())
        assertEquals("2021-05-30T07:30", LocalDateTime(2021, 5, 30, 7, 30, 0).toString())
        assertEquals("2021-12-31T08:45:30", LocalDateTime(2021, 12, 31, 8, 45, 30).toString())
    }

    @Test
    fun testMinutesUntil() {
        // pure minutes i.e. replicate LocalTimeTest functionality
        // - dates are equal, they should not have an effect
        assertEquals(0, datetime().minutesUntil(datetime()))
        assertEquals(0, datetime().minutesUntil(datetime(second = 59)))
        assertEquals(1, datetime().minutesUntil(datetime(minute = 1)))
        assertEquals(1, datetime().minutesUntil(datetime(minute = 1, second = 59)))
        assertEquals(59, datetime().minutesUntil(datetime(minute = 59, second = 59)))
        assertEquals(59, datetime(hour = 1).minutesUntil(datetime(hour = 1, minute = 59, second = 59)))
        assertEquals(59, datetime(hour = 23).minutesUntil(datetime(hour = 23, minute = 59, second = 59)))
        assertEquals(60, datetime(hour = 0).minutesUntil(datetime(hour = 1)))
        assertEquals(119, datetime(hour = 0).minutesUntil(datetime(hour = 1, minute = 59, second = 59)))
        assertEquals(1439, datetime(hour = 0).minutesUntil(datetime(hour = 23, minute = 59, second = 59)))

        assertEquals(minutesIn(1) + 0,
                     datetime(dayOfMonth = 1).minutesUntil(datetime(dayOfMonth = 2, second = 59)))
        assertEquals(minutesIn(1) + 1,
                     datetime(dayOfMonth = 1).minutesUntil(datetime(dayOfMonth = 2, minute = 1)))
        assertEquals(minutesIn(1) + 1439,
                     datetime(dayOfMonth = 1, hour = 0).minutesUntil(datetime(dayOfMonth = 2, hour = 23, minute = 59, second = 59)))

        assertEquals(minutesIn(2) + 0,
                     datetime(dayOfMonth = 1).minutesUntil(datetime(dayOfMonth = 3)))
        assertEquals(minutesIn(2) + 1439,
                     datetime(dayOfMonth = 1, hour = 0).minutesUntil(datetime(dayOfMonth = 3, hour = 23, minute = 59, second = 59)))

        assertEquals(minutesIn(31) + 0,
                     datetime(monthNumber = 1, dayOfMonth = 1).minutesUntil(datetime(monthNumber = 2, dayOfMonth = 1)))
    }

    @Test
    fun testComparison() {
        val earlier = datetime(hour = 12)
        val later = datetime(hour = 13)
        assertTrue(earlier < later, "<")
        assertTrue(later > earlier, ">")
        assertEquals(earlier, earlier, "== 1")
        assertEquals(later, later, "== 2")
    }

    @Test
    fun testCoercingToEarlier() {
        val earlier = datetime(hour = 12)
        val later = datetime(hour = 13)
        assertEquals(earlier, later.coerceAtMost(earlier), "at least")
        assertEquals(earlier, earlier.coerceAtMost(later), "at most")
    }

    @Test
    fun testCoercingToLater() {
        val earlier = datetime(hour = 12)
        val later = datetime(hour = 13)
        assertEquals(later, later.coerceAtLeast(earlier), "at most")
        assertEquals(later, earlier.coerceAtLeast(later), "at least")
    }

    @Test
    fun testChangingIndividualTimeComponents() {
        assertEquals(datetime(hour = 11), datetime().changeTime(hour = 11))
        assertEquals(datetime(minute = 11), datetime().changeTime(minute = 11))
        assertEquals(datetime(second = 11), datetime().changeTime(second = 11))
    }

    private fun datetime(year: Int = 2021, monthNumber: Int = 1, dayOfMonth: Int = 1,
                         hour: Int = 12, minute: Int = 0, second: Int = 0) =
        LocalDateTime(year, monthNumber, dayOfMonth, hour, minute, second)

    private fun minutesIn(days: Int): Int {
        return days * 24 * 60
    }
}
