import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:navigation_view/item_navigation_view.dart';
import 'package:navigation_view/navigation_view.dart';

class AppBBN extends StatelessWidget {
  const AppBBN({
    super.key,
    required this.atBottom,
    required this.onTabChange,
    required this.currentIndex, // Indeks aktif
  });

  final bool atBottom;
  final ValueChanged<int> onTabChange;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return NavigationView(
      onChangePage: onTabChange,
      curve: Curves.fastEaseInToSlowEaseOut,
      durationAnimation: const Duration(milliseconds: 400),
      backgroundColor: theme.scaffoldBackgroundColor,
      borderTopColor: Theme.of(context).brightness == Brightness.light
          ? atBottom
              ? theme.primaryColor
              : null
          : null,
      color: theme.primaryColor,
     items: [
  // Home (Indeks 0)
  ItemNavigationView(
    childAfter: Icon(
      IconlyBold.home,
      color: currentIndex == 0 ? theme.primaryColor : Colors.black,
      size: 35,
    ),
    childBefore: Icon(
      IconlyBroken.home,
      color: currentIndex == 0 ? theme.primaryColor : Colors.black,
      size: 30,
    ),
  ),
  // Upload (Indeks 1)
  ItemNavigationView(
    childAfter: Icon(
      IconlyBold.plus,
      color: currentIndex == 1 ? theme.primaryColor : Colors.black,
      size: 35,
    ),
    childBefore: Icon(
      IconlyBroken.plus,
      color: currentIndex == 1 ? theme.primaryColor : Colors.black,
      size: 30,
    ),
  ),
  // Albums (Indeks 2)
  ItemNavigationView(
    childAfter: Icon(
      IconlyBold.category,
      color: currentIndex == 2 ? theme.primaryColor : Colors.black,
      size: 35,
    ),
    childBefore: Icon(
      IconlyBroken.category,
      color: currentIndex == 2 ? theme.primaryColor : Colors.black,
      size: 30,
    ),
  ),
  // Profile (Indeks 3)
  ItemNavigationView(
    childAfter: Icon(
      IconlyBold.profile,
      color: currentIndex == 3 ? theme.primaryColor : Colors.black,
      size: 35,
    ),
    childBefore: Icon(
      IconlyBroken.profile,
      color: currentIndex == 3 ? theme.primaryColor : Colors.black,
      size: 30,
    ),
  ),
]
    );
  }
}
