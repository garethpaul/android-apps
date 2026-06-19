package com.requestlabs.traveller;

public final class ParseConfigurationTest {
    private static final String PLACEHOLDER = "parse-placeholder";

    public static void main(String[] args) {
        assertEquals("application-id", ParseConfiguration.configuredValue(
                "  application-id  ", PLACEHOLDER));
        assertEquals("client key", ParseConfiguration.configuredValue(
                "  client key\t", PLACEHOLDER));

        assertRejected(null);
        assertRejected("");
        assertRejected(" \t\n");
        assertRejected(PLACEHOLDER);
        assertRejected("  " + PLACEHOLDER + "  ");
    }

    private static void assertRejected(String value) {
        try {
            ParseConfiguration.configuredValue(value, PLACEHOLDER);
            throw new AssertionError("Expected invalid Parse configuration to be rejected");
        } catch (IllegalStateException expected) {
            assertEquals(
                    "Traveller Parse configuration is missing; replace Constants.java placeholders locally.",
                    expected.getMessage());
        }
    }

    private static void assertEquals(String expected, String actual) {
        if (!expected.equals(actual)) {
            throw new AssertionError("Expected <" + expected + "> but was <" + actual + ">");
        }
    }
}
