package com.requestlabs.traveller;

final class ParseConfiguration {
    private static final String ERROR_MESSAGE =
            "Traveller Parse configuration is missing; replace Constants.java placeholders locally.";

    private ParseConfiguration() {
    }

    static String configuredValue(String value, String placeholder) {
        if (value == null) {
            throw new IllegalStateException(ERROR_MESSAGE);
        }

        String configuredValue = value.trim();
        if (configuredValue.length() == 0 || placeholder.equals(configuredValue)) {
            throw new IllegalStateException(ERROR_MESSAGE);
        }
        return configuredValue;
    }
}
