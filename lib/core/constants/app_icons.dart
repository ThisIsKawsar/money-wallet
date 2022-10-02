import 'package:flutter/material.dart';

class AppIcons {
  static IconData fromName(String? name) {
    switch (name) {
      // Categories
      case 'restaurant': return Icons.restaurant_rounded;
      case 'shopping_bag': return Icons.shopping_bag_rounded;
      case 'shopping_cart': return Icons.shopping_cart_rounded;
      case 'directions_car': return Icons.directions_car_rounded;
      case 'receipt_long': return Icons.receipt_long_rounded;
      case 'movie': return Icons.movie_rounded;
      case 'favorite': return Icons.favorite_rounded;
      case 'school': return Icons.school_rounded;
      case 'savings': return Icons.savings_rounded;
      case 'home': return Icons.home_rounded;
      case 'remove_circle': return Icons.remove_circle_rounded;
      case 'add_circle': return Icons.add_circle_rounded;
      case 'work': return Icons.work_rounded;
      case 'laptop': return Icons.laptop_rounded;
      case 'trending_up': return Icons.trending_up_rounded;
      case 'card_giftcard': return Icons.card_giftcard_rounded;
      case 'account_balance': return Icons.account_balance_rounded;
      // Accounts
      case 'wallet': return Icons.account_balance_wallet_rounded;
      case 'credit_card': return Icons.credit_card_rounded;
      case 'phone_android': return Icons.phone_android_rounded;
      case 'payments': return Icons.payments_rounded;
      case 'attach_money': return Icons.attach_money_rounded;
      // General
      case 'flight': return Icons.flight_rounded;
      case 'fitness_center': return Icons.fitness_center_rounded;
      case 'pets': return Icons.pets_rounded;
      case 'local_hospital': return Icons.local_hospital_rounded;
      case 'business': return Icons.business_rounded;
      case 'music_note': return Icons.music_note_rounded;
      case 'sports': return Icons.sports_rounded;
      case 'coffee': return Icons.coffee_rounded;
      case 'fastfood': return Icons.fastfood_rounded;
      case 'local_grocery_store': return Icons.local_grocery_store_rounded;
      case 'electric_bolt': return Icons.electric_bolt_rounded;
      case 'water_drop': return Icons.water_drop_rounded;
      case 'wifi': return Icons.wifi_rounded;
      case 'phone': return Icons.phone_rounded;
      case 'insurance': return Icons.shield_rounded;
      case 'child_care': return Icons.child_care_rounded;
      case 'celebration': return Icons.celebration_rounded;
      case 'volunteer_activism': return Icons.volunteer_activism_rounded;
      default: return Icons.receipt_long_rounded;
    }
  }

  static const List<Map<String, dynamic>> availableIcons = [
    {'name': 'restaurant', 'label': 'Food'},
    {'name': 'shopping_bag', 'label': 'Shopping'},
    {'name': 'directions_car', 'label': 'Transport'},
    {'name': 'home', 'label': 'Home'},
    {'name': 'favorite', 'label': 'Health'},
    {'name': 'school', 'label': 'Education'},
    {'name': 'movie', 'label': 'Entertainment'},
    {'name': 'savings', 'label': 'Savings'},
    {'name': 'work', 'label': 'Work'},
    {'name': 'laptop', 'label': 'Tech'},
    {'name': 'trending_up', 'label': 'Investment'},
    {'name': 'card_giftcard', 'label': 'Gift'},
    {'name': 'account_balance', 'label': 'Bank'},
    {'name': 'flight', 'label': 'Travel'},
    {'name': 'fitness_center', 'label': 'Fitness'},
    {'name': 'pets', 'label': 'Pets'},
    {'name': 'coffee', 'label': 'Coffee'},
    {'name': 'fastfood', 'label': 'Fast Food'},
    {'name': 'music_note', 'label': 'Music'},
    {'name': 'sports', 'label': 'Sports'},
    {'name': 'electric_bolt', 'label': 'Electricity'},
    {'name': 'water_drop', 'label': 'Water'},
    {'name': 'wifi', 'label': 'Internet'},
    {'name': 'phone', 'label': 'Phone'},
    {'name': 'child_care', 'label': 'Kids'},
    {'name': 'celebration', 'label': 'Events'},
    {'name': 'volunteer_activism', 'label': 'Charity'},
    {'name': 'receipt_long', 'label': 'Bills'},
    {'name': 'add_circle', 'label': 'Other+'},
    {'name': 'remove_circle', 'label': 'Other-'},
  ];
}
