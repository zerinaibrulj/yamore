import 'package:flutter/material.dart';

import '../models/service_model.dart';

/// Icons for add-on / catalog services. Uses [ServiceModel] name and description
/// so items in the same category (e.g. Entertainment) can get distinct icons
/// (Wi‑Fi vs music). Optional [categoryName] refines fallbacks when names are generic.
IconData yamoreServiceIcon(
  ServiceModel service, {
  String categoryName = '',
}) {
  final n = service.name.toLowerCase().trim();
  final d = (service.description ?? '').toLowerCase();
  final c = categoryName.toLowerCase();
  final all = '$n $d $c';

  if (n.contains('wi-fi') || n.contains('wifi')) return Icons.wifi;
  if (n.contains('internet') || n.contains('wlan')) return Icons.wifi;
  if (d.contains('unlimited internet') || d.contains('unlimited internet on board') || d.contains('wireless on board')) {
    return Icons.wifi;
  }

  // Food before drink so "Food and drinks" prefers a meal icon.
  if (n.contains('food') ||
      n.contains('meal') ||
      (n.contains('catering') && !n.contains('drink')) ||
      d.contains('meals &') ||
      d.contains('catering on board') ||
      d.contains('meals and catering') ||
      (c.contains('cater') && (n.contains('lunch') || n.contains('breakfast') || n.contains('dinner') || d.contains('meal')))) {
    return Icons.dinner_dining;
  }

  if (n.contains('drink') ||
      n.contains('beverage') ||
      d.contains('champagne package') ||
      d.contains('wine, cocktail') ||
      d.contains('wine, cocktails') ||
      (d.contains('cocktail') && d.contains('champagne')) ||
      d.contains('open bar') ||
      (d.contains('wine') && d.contains('cocktail'))) {
    return Icons.wine_bar;
  }

  if (n.contains('skipper') || n.contains('captain') || n.contains('helm')) {
    return Icons.sailing;
  }
  if (n.contains('hostess') || n.contains('steward')) {
    return Icons.support_agent;
  }

  if (n.contains('music') ||
      n.contains('dj') ||
      d.contains('live music') ||
      d.contains('dj or') ||
      d.contains('sound system') ||
      (n.length < 24 && n.contains('band') && !n.contains('broadband'))) {
    return Icons.music_note;
  }

  if (n.contains('clean') || n.contains('laundry')) return Icons.cleaning_services;
  if (n.contains('pet')) return Icons.pets;
  if (n.contains('safety') || n.contains('life jacket') || n.contains('life ')) {
    return Icons.health_and_safety;
  }
  if (n.contains('diving') || n.contains('snorkel')) return Icons.scuba_diving;
  if (n.contains('fuel') || n.contains('gas ')) return Icons.local_gas_station;
  if (n.contains('equip') || n.contains('gear') || c.contains('equip')) {
    return Icons.fitness_center;
  }
  if (n.contains('transfer') || n.contains('transport') || c.contains('transport')) {
    return Icons.directions_car;
  }
  if (n.contains('fishing')) return Icons.phishing;
  if (n.contains('photo') || n.contains('video')) return Icons.camera_alt;
  if (n.contains('towel') || n.contains('linen')) return Icons.dry_cleaning;
  if (n.contains('insurance')) return Icons.verified_user_outlined;
  if (n.contains('bar') && n.length < 32) return Icons.wine_bar;
  if (n.contains('welcome')) return Icons.emoji_food_beverage_outlined;

  if (c.contains('water') || c.contains('sport') || all.contains('jet ski') || c.contains('diving')) {
    return Icons.pool;
  }
  if (c.contains('excurs') || c.contains('tour')) return Icons.explore;
  if (c.contains('wellness') || c.contains('spa')) return Icons.spa;
  if (c.contains('event') || c.contains('party')) return Icons.celebration;
  if (c.contains('transport')) return Icons.local_taxi;
  if (c.contains('entertain')) return Icons.theater_comedy;
  if (c.contains('crew') || c.contains('staff')) return Icons.groups;
  if (c.contains('cater') || c.contains('dining') || c.contains('food')) {
    return Icons.restaurant;
  }
  if (c.contains('equip') || c.contains('rental') || c.contains('gear')) {
    return Icons.construction;
  }

  return Icons.room_service_outlined;
}
