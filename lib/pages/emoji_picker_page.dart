import 'package:flutter/material.dart';
import 'package:tooodooo_app/util/icon_manager.dart';

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
      backgroundColor: Colors.blueGrey[100],
      appBar: AppBar(
        title: const Text("Select Icon"),
        backgroundColor: Colors.brown[400],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recently Used / Default section
              Text(
                IconManager.isUsingDefaultIcons 
                  ? "Default Icons" 
                  : "Recently Used",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              _buildIconGrid(recentlyUsed, context),
              const Divider(thickness: 2),
              const SizedBox(height: 8),

              const Text(
                "All Icons",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
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
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
              border: isDefaultIcon && icons != IconManager.defaultIcons && !IconManager.isUsingDefaultIcons
                ? Border.all(color: Colors.blue, width: 2)
                : null,
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon, 
              size: 32,
              color: Colors.black,
            ),
          ),
        );
      },
    );
  }
}
