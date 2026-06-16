package com.requestlabs.traveller;

public final class TaskDescriptionNormalizerTest {
    public static void main(String[] args) {
        assertNormalized("", null, "null descriptions");
        assertNormalized("", "", "empty descriptions");
        assertNormalized("", " \t\n ", "whitespace-only descriptions");
        assertNormalized("Buy milk", "  Buy milk  ", "ASCII descriptions");
        assertNormalized("café 東京", "  café 東京  ", "Unicode descriptions");
    }

    private static void assertNormalized(String expected, String input, String caseName) {
        String actual = TaskDescriptionNormalizer.normalize(input);
        if(!expected.equals(actual)) {
            throw new AssertionError(caseName + ": expected <" + expected + "> but was <" + actual + ">");
        }
    }
}
