// File: app_bottom_navigation.dart
import 'package:flutter/material.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChange;

  const AppBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTabChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, 0, Icons.home_outlined, Icons.home),
          _buildNavItem(context, 1, Icons.add_circle_outline, Icons.add_circle),
          _buildNavItem(context, 2, Icons.photo_album_outlined, Icons.photo_album),
          _buildNavItem(context, 3, Icons.person_outline, Icons.person),
        ],
      ),
    );
  }

Widget _buildNavItem(BuildContext context, int index, IconData icon, IconData activeIcon) {
  final isSelected = currentIndex == index;
  final primaryColor = Theme.of(context).primaryColor;

  return GestureDetector(
    onTap: () => onTabChange(index),
    behavior: HitTestBehavior.opaque,
    child: SizedBox(
      width: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            transform: Matrix4.translationValues(0, isSelected ? -4 : 0, 0),
            child: Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? primaryColor : Colors.grey,
              size: isSelected ? 31 : 28,
            ),
          ),
        ],
      ),
    ),
  );
}

}