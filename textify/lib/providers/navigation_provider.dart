import 'package:flutter/material.dart';
import '../services/navigation_service.dart';

class NavigationProvider {
  final NavigationService _navigationService;

  NavigationProvider(this._navigationService);

  void navigateToRoute(String routeName) {
    _navigationService.navigateToRoute(routeName);
  }

  void navigateToPage(Widget page) {
    _navigationService.navigateToPage(page);
  }
}
