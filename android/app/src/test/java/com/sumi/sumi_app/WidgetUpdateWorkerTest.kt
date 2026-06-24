package com.sumi.sumi_app

import org.junit.Assert.assertEquals
import org.junit.Test

class WidgetUpdateWorkerTest {

    @Test
    fun `timeAgo returns empty string for invalid input`() {
        val result = WidgetUpdateWorkerTestUtil().timeAgo("not-a-date")
        assertEquals("", result)
    }

    @Test
    fun `timeAgo returns minutes ago`() {
        val now = java.time.Instant.now()
        val fiveMinAgo = now.minusSeconds(5 * 60).toString()
        val result = WidgetUpdateWorkerTestUtil().timeAgo(fiveMinAgo)
        org.junit.Assert.assertTrue(result.endsWith("m ago"))
    }

    @Test
    fun `timeAgo returns hours ago`() {
        val now = java.time.Instant.now()
        val threeHoursAgo = now.minusSeconds(3 * 3600).toString()
        val result = WidgetUpdateWorkerTestUtil().timeAgo(threeHoursAgo)
        assertEquals("3h ago", result)
    }

    @Test
    fun `timeAgo returns days ago`() {
        val now = java.time.Instant.now()
        val twoDaysAgo = now.minusSeconds(2 * 86400).toString()
        val result = WidgetUpdateWorkerTestUtil().timeAgo(twoDaysAgo)
        org.junit.Assert.assertTrue(result.endsWith("d ago"))
    }

    @Test
    fun `parseItems returns empty list for empty data`() {
        val items = WidgetUpdateWorkerTestUtil().parseItems("""{"data": []}""")
        assertEquals(0, items.size)
    }

    @Test
    fun `parseItems parses manga with english title`() {
        val json = """
        {
            "data": [{
                "id": "abc-123",
                "attributes": {
                    "title": {"en": "One Piece"},
                    "lastChapter": "1100",
                    "updatedAt": "2024-01-01T00:00:00Z"
                },
                "relationships": []
            }]
        }
        """.trimIndent()

        val items = WidgetUpdateWorkerTestUtil().parseItems(json)
        assertEquals(1, items.size)
        assertEquals("abc-123", items[0].id)
        assertEquals("One Piece", items[0].title)
        assertEquals("1100", items[0].lastChapter)
    }

    @Test
    fun `parseItems handles multiple manga`() {
        val json = """
        {
            "data": [
                {"id": "1", "attributes": {"title": {"en": "A"}}, "relationships": []},
                {"id": "2", "attributes": {"title": {"en": "B"}}, "relationships": []}
            ]
        }
        """.trimIndent()

        val items = WidgetUpdateWorkerTestUtil().parseItems(json)
        assertEquals(2, items.size)
        assertEquals("A", items[0].title)
        assertEquals("B", items[1].title)
    }
}
