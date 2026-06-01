public with sharing class UIUtilityService {

    // Column sizing for responsive layouts
    public static String getColSize(Integer columns) {
        switch on columns {
            when 1 { return 'slds-size_1-of-1'; }
            when 2 { return 'slds-size_1-of-2'; }
            when 3 { return 'slds-size_1-of-3'; }
            when 4 { return 'slds-size_1-of-4'; }
            when 5 { return 'slds-size_1-of-5'; }
            when 6 { return 'slds-size_1-of-6'; }
            when else { return 'slds-size_1-of-1'; }
        }
    }

    public static String getResponsiveClass(Integer smallCols, Integer mediumCols, Integer largeCols) {
        return 'slds-size_1-of-' + smallCols + 
               ' slds-medium-size_1-of-' + mediumCols + 
               ' slds-large-size_1-of-' + largeCols;
    }

    public enum ColorTheme {
        LIGHT, DARK, HIGH_CONTRAST
    }

    public static String getThemeClass(ColorTheme theme) {
        switch on theme {
            when DARK { return 'slds-theme_dark'; }
            when HIGH_CONTRAST { return 'slds-theme_alt-inverse'; }
            when else { return ''; }
        }
    }

    public static String getCardThemeClass(String variant) {
        switch on variant {
            when 'success' { return 'slds-theme_success slds-theme_alert-texture'; }
            when 'warning' { return 'slds-theme_warning slds-theme_alert-texture'; }
            when 'error' { return 'slds-theme_error slds-theme_alert-texture'; }
            when 'info' { return 'slds-theme_info slds-theme_alert-texture'; }
            when else { return ''; }
        }
    }

    public static String getAriaLabel(String label, String value) {
        return label + ': ' + value;
    }

    public static String getAriaDescription(String description) {
        return 'aria-describedby="' + description + '"';
    }

    public static String getAriaLive(Boolean polite) {
        return polite ? 'aria-live="polite"' : 'aria-live="assertive"';
    }
}
