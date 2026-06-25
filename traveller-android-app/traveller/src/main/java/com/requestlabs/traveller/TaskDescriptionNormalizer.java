package com.requestlabs.traveller;

final class TaskDescriptionNormalizer {
    private TaskDescriptionNormalizer() {
    }

    static String normalize(String description) {
        if(description == null) {
            return "";
        }

        int start = 0;
        int end = description.length();
        while(start < end && isTaskWhitespace(description.charAt(start))) {
            start++;
        }
        while(start < end && isTaskWhitespace(description.charAt(end - 1))) {
            end--;
        }
        return description.substring(start, end);
    }

    private static boolean isTaskWhitespace(char value) {
        return value <= ' ' || Character.isWhitespace(value) || Character.isSpaceChar(value);
    }
}
