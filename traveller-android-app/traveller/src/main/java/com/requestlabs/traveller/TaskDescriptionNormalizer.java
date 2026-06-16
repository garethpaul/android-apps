package com.requestlabs.traveller;

final class TaskDescriptionNormalizer {
    private TaskDescriptionNormalizer() {
    }

    static String normalize(String description) {
        return description == null ? "" : description.trim();
    }
}
