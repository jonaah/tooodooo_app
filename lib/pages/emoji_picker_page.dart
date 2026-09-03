import 'package:flutter/material.dart';
import 'package:tooodooo_app/util/icon_manager.dart';
import 'package:tooodooo_app/util/app_theme.dart';

class EmojiPickerPage extends StatelessWidget {
  final List<IconData> recentlyUsed;
  final List<IconData> allEmojis;
  final Function(IconData) onIconSelected;

  const EmojiPickerPage({
    super.key, 
    required this.recentlyUsed, 
    required this.allEmojis, 
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: AppTheme.primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: screenHeight * 0.78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modern Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 6),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryTextColor.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),

            // Modern Header (matching New Task style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.secondaryTextColor),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Close',
                  ),
                  Text(
                    "Select Icon",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1.5, color: AppTheme.dividerColor),

            // Scrollable icon content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppTheme.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recently Used / Default section
                    Text(
                      IconManager.isUsingDefaultIcons 
                        ? "Default Icons" 
                        : "Recently Used",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                    SizedBox(height: AppTheme.smallPadding),
                    _buildIconGrid(recentlyUsed, context),
                    const SizedBox(height: 16),
                    Divider(thickness: 1.5, color: AppTheme.dividerColor),
                    const SizedBox(height: 12),

                    Text(
                      "All Icons",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                    SizedBox(height: AppTheme.smallPadding),
                    _buildIconGrid(allEmojis, context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconGrid(List<IconData> icons, BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final icon = icons[index];
        final isDefaultIcon = IconManager.isDefaultIcon(icon);
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              onIconSelected(icon);
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDefaultIcon && icons != IconManager.defaultIcons && !IconManager.isUsingDefaultIcons
                    ? AppTheme.accentColor
                    : Colors.white.withValues(alpha: 0.08),
                  width: isDefaultIcon && icons != IconManager.defaultIcons && !IconManager.isUsingDefaultIcons ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 3,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon, 
                size: AppTheme.iconSize + 6,
                color: AppTheme.textColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> showIconPicker({
  required BuildContext context,
  required Function(IconData) onIconSelected,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => EmojiPickerPage(
      recentlyUsed: IconManager.recentIcons,
      allEmojis: IconManager.allIcons,
      onIconSelected: onIconSelected,
    ),
  );
}
