import 'package:flutter/material.dart';
import 'custom_app_bar.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final bool showBackButton;
  final bool showNotificationIcon;

  const MainLayout({
    super.key,
    required this.child,
    required this.title,
    this.showBackButton = false,
    this.showNotificationIcon = true,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title,
        showBackButton: widget.showBackButton,
        showNotificationIcon: widget.showNotificationIcon,
      ),
      body: widget.child,
    );
  }
}
