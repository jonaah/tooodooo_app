import 'package:flutter/material.dart';

// A central place for app theme definitions to avoid magic numbers and hardcoded styles
class AppTheme {
  // App colors
  static const Color primaryColor = Color(0xFF0D1B2A); // Dark gray for app bar
  static const Color backgroundColor = Color(0xFF879FB7); // Background color
  static const Color textColor = Color(0xFFE0E1DD); // Light text color
  static const Color secondaryTextColor = Color(0xFFFFF7F7); // Lighter text color for subtitles
  static const Color darkTextColor = Color(0xFF1B263B); // Darker text color for contrast
  static const Color accentColor = Color(0xFF5299D3); // Blue accent instead of amber/yellow
  static const Color dividerColor = Color(0xFFE5E5E5); // Divider color (same as accent)
  static const Color calendarBackgroundColor = Color(0x778DA9FF); // Calendar background color

  // Priority colors - Green to Red progression
  static Color getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Color(0xFF81DA83).withOpacity(0.75); // Lowest priority - green
      case 2:
        return Color(0xFF63C8BF).withOpacity(0.75); // Low priority - teal
      case 3:
        return Color(0xFF6A96DC).withOpacity(0.75); // Medium priority - blue
      case 4:
        return Color(0xFFF87C47).withOpacity(0.75); // High priority - orange
      case 5:
        return Color(0xFFFF554C).withOpacity(0.75); // Highest priority - red
      default:
        return Colors.grey[500]!.withOpacity(0.75); // No priority assigned
    }
  }
  
  // Get color based on task priority for calendar - using the same progression
  static Color getCalendarTaskColor(int priority) {
    switch (priority) {
      case 1:
        return Color(0xFF99D89A); // Lowest priority
      case 2:
        return Color(0xFF7DDCD3); // Low priority
      case 3:
        return Color(0xFF6A96DC); // Medium priority
      case 4:
        return Color(0xFFFA7842); // High priority
      case 5:
        return Color(0xFFFF544C); // Highest priority
      default:
        return Colors.grey[500]!; // Default
    }
  }
  
  // Get text color for priority based backgrounds (ensure readable text)
  static Color getTextColorForPriority(int priority) {
    // For all priorities, white text provides good contrast
    return Colors.white;
  }

  // Text styles
  static const TextStyle appBarTitle = TextStyle(
    color: Colors.white,
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );
  
  static TextStyle taskTitle(int priority) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: getTextColorForPriority(priority),
    );
  }
  
  static TextStyle taskCompleted(int priority) {
    return TextStyle(
      fontSize: 18,
      decoration: TextDecoration.lineThrough,
      color: getTextColorForPriority(priority).withOpacity(0.6),
    );
  }
  
  static TextStyle taskSubtitle(int priority) {
    return TextStyle(
      fontSize: 12,
      color: getTextColorForPriority(priority).withOpacity(0.8),
    );
  }
  
  static TextStyle taskSubtitleCompleted(int priority) {
    return TextStyle(
      fontSize: 12,
      color: getTextColorForPriority(priority).withOpacity(0.6),
      decoration: TextDecoration.lineThrough,
    );
  }
  
  static const TextStyle calendarDayHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textColor,
  );
  
  static const TextStyle dialogTitle = TextStyle(
    fontSize: 20, 
    fontWeight: FontWeight.bold,
  );
  
  // Button styles
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: accentColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
  
  static final ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.grey[700],
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
  
  // BoxDecoration for containers
  static BoxDecoration cardDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    color: Colors.grey[800],
  );
  
  // Constants for spacing and sizing
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 32.0;
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;
  static const double smallIconSize = 16.0;
  
  // ThemeData for MaterialApp
  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: appBarTitle,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: textColor,
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: WidgetStateProperty.all(Colors.white),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return null;
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 2,
      ),
      timePickerTheme: timePickerTheme,
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        surface: Colors.grey[800]!,
        onSurface: textColor,
        secondary: accentColor,
      ),
    );
  }

  // TimePickerThemeData 
  static TimePickerThemeData get timePickerTheme {
    return TimePickerThemeData(
      backgroundColor: primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      hourMinuteShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      hourMinuteColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentColor.withValues(alpha: 0.3);
        }
        return backgroundColor.withValues(alpha: 0.25);
      }),
      hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return secondaryTextColor;
      }),
      dialBackgroundColor: backgroundColor.withValues(alpha: 0.25),
      dialHandColor: accentColor,
      dialTextColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return secondaryTextColor;
      }),
      dialTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.0,
      ),
      dayPeriodColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentColor;
        }
        return backgroundColor.withValues(alpha: 0.25);
      }),
      dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return secondaryTextColor;
      }),
      entryModeIconColor: accentColor,
      cancelButtonStyle: TextButton.styleFrom(
        foregroundColor: secondaryTextColor.withValues(alpha: 0.8),
      ),
      confirmButtonStyle: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      ),
    );
  }

  // Helper method to open a spacious, beautifully styled TimePicker
  static Future<TimeOfDay?> showStyledTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
  }) async {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            primaryColor: accentColor,
            scaffoldBackgroundColor: primaryColor,
            colorScheme: const ColorScheme.dark(
              primary: accentColor,
              onPrimary: Colors.white,
              surface: primaryColor,
              onSurface: secondaryTextColor,
            ),
            timePickerTheme: timePickerTheme,
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: Transform.scale(
              scale: 1.06,
              child: child!,
            ),
          ),
        );
      },
    );
  }
}