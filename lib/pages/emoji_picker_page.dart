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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Select Icon", style: AppTheme.appBarTitle),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
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
                  fontSize: 18,
                  color: AppTheme.textColor,
                ),
              ),
              SizedBox(height: AppTheme.smallPadding),
              _buildIconGrid(recentlyUsed, context),
              Divider(thickness: 2, color: AppTheme.dividerColor),
              SizedBox(height: AppTheme.smallPadding),

              Text(
                "All Icons",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.textColor,
                ),
              ),
              SizedBox(height: AppTheme.smallPadding),
              _buildIconGrid(allEmojis, context),
            ],
          ),
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
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final icon = icons[index];
        final isDefaultIcon = IconManager.isDefaultIcon(icon);
        
        return GestureDetector(
          onTap: () {
            onIconSelected(icon);
            Navigator.pop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
              border: isDefaultIcon && icons != IconManager.defaultIcons && !IconManager.isUsingDefaultIcons
                ? Border.all(color: AppTheme.accentColor, width: 2)
                : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            padding: EdgeInsets.all(AppTheme.smallPadding),
            child: Icon(
              icon, 
              size: AppTheme.iconSize + 8,
              color: AppTheme.textColor,
            ),
          ),
        );
      },
    );
  }
}
