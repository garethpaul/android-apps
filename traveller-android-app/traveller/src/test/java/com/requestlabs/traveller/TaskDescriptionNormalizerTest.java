package com.requestlabs.traveller;

public final class TaskDescriptionNormalizerTest {
    public static void main(String[] args) {
        assertNormalized("", null, "null descriptions");
        assertNormalized("", "", "empty descriptions");
        assertNormalized("", " \t\n ", "whitespace-only descriptions");
        assertNormalized("", "\u00a0\u2003\u3000", "Unicode whitespace-only descriptions");
        assertNormalized("Buy milk", "  Buy milk  ", "ASCII descriptions");
        assertNormalized("café 東京", "  café 東京  ", "Unicode descriptions");
        assertNormalized("café 東京", "\u00a0\u2003café 東京\u3000", "Unicode boundary whitespace");
        assertNormalized("Plan\u00a0trip", "Plan\u00a0trip", "interior Unicode spacing");
        assertNormalized("Buy milk", "\u0000Buy milk\u001f", "legacy trim control characters");
    }

    private static void assertNormalized(String expected, String input, String caseName) {
        String actual = TaskDescriptionNormalizer.normalize(input);
        if(!expected.equals(actual)) {
            throw new AssertionError(caseName + ": expected <" + expected + "> but was <" + actual + ">");
        }
    }
}
