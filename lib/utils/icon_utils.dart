import 'package:flutter/material.dart';

class IconUtils {
  static IconData getIconData(String iconName) {
    switch (iconName) {
      // Work & Productivity
      case 'work': return Icons.work;
      case 'school': return Icons.school;
      case 'computer': return Icons.computer;
      case 'book': return Icons.book;
      case 'phone': return Icons.phone;
      case 'meeting_room': return Icons.meeting_room;
      case 'business': return Icons.business;
      case 'account_balance': return Icons.account_balance;
      case 'assignment': return Icons.assignment;
      case 'description': return Icons.description;
      
      // Personal & Family
      case 'family_restroom': return Icons.family_restroom;
      case 'home': return Icons.home;
      case 'person': return Icons.person;
      case 'favorite': return Icons.favorite;
      case 'heart': return Icons.favorite;
      case 'child_care': return Icons.child_care;
      case 'elderly': return Icons.elderly;
      case 'pets': return Icons.pets;
      
      // Health & Fitness
      case 'fitness_center': return Icons.fitness_center;
      case 'sports_soccer': return Icons.sports_soccer;
      case 'sports_basketball': return Icons.sports_basketball;
      case 'sports_tennis': return Icons.sports_tennis;
      case 'sports_esports': return Icons.sports_esports;
      case 'directions_run': return Icons.directions_run;
      case 'directions_bike': return Icons.directions_bike;
      case 'pool': return Icons.pool;
      case 'local_hospital': return Icons.local_hospital;
      case 'local_pharmacy': return Icons.local_pharmacy;
      
      // Travel & Transportation
      case 'flight': return Icons.flight;
      case 'hotel': return Icons.hotel;
      case 'directions_car': return Icons.directions_car;
      case 'train': return Icons.train;
      case 'bus': return Icons.directions_bus;
      case 'beach_access': return Icons.beach_access;
      case 'park': return Icons.park;
      case 'landscape': return Icons.landscape;
      case 'map': return Icons.map;
      case 'navigation': return Icons.navigation;
      
      // Entertainment & Leisure
      case 'movie': return Icons.movie;
      case 'music_note': return Icons.music_note;
      case 'gamepad': return Icons.gamepad;
      case 'casino': return Icons.casino;
      case 'theater_comedy': return Icons.theater_comedy;
      case 'museum': return Icons.museum;
      case 'library_books': return Icons.library_books;
      case 'sports_bar': return Icons.sports_bar;
      case 'restaurant': return Icons.restaurant;
      case 'local_cafe': return Icons.local_cafe;
      
      // Shopping & Services
      case 'shopping_cart': return Icons.shopping_cart;
      case 'local_grocery_store': return Icons.local_grocery_store;
      case 'local_mall': return Icons.local_mall;
      case 'local_laundry_service': return Icons.local_laundry_service;
      case 'local_car_wash': return Icons.local_car_wash;
      case 'local_gas_station': return Icons.local_gas_station;
      case 'local_police': return Icons.local_police;
      case 'local_fire_department': return Icons.local_fire_department;
      case 'local_post_office': return Icons.local_post_office;
      case 'local_printshop': return Icons.local_printshop;
      
      // Goals & Achievement
      case 'flag': return Icons.flag;
      case 'target': return Icons.gps_fixed;
      case 'star': return Icons.star;
      case 'thumb_up': return Icons.thumb_up;
      case 'check_circle': return Icons.check_circle;
      case 'trending_up': return Icons.trending_up;
      case 'rocket_launch': return Icons.rocket_launch;
      case 'lightbulb': return Icons.lightbulb;
      case 'emoji_events': return Icons.emoji_events;
      case 'military_tech': return Icons.military_tech;
      
      // Time & Status
      case 'hourglass_empty': return Icons.hourglass_empty;
      case 'schedule': return Icons.schedule;
      case 'access_time': return Icons.access_time;
      case 'timer': return Icons.timer;
      case 'alarm': return Icons.alarm;
      case 'calendar_today': return Icons.calendar_today;
      case 'event': return Icons.event;
      case 'pending': return Icons.pending;
      case 'done': return Icons.done;
      case 'error': return Icons.error;
      
      // Religious & Cultural
      case 'church': return Icons.church;
      case 'mosque': return Icons.mosque;
      case 'temple_buddhist': return Icons.temple_buddhist;
      case 'synagogue': return Icons.synagogue;
      
      // Default fallback
      default: return Icons.work;
    }
  }

  static List<String> getAvailableIcons() {
    return [
      'work', 'school', 'computer', 'book', 'phone', 'meeting_room',
      'family_restroom', 'home', 'person', 'favorite', 'child_care',
      'fitness_center', 'sports_soccer', 'sports_basketball', 'sports_tennis',
      'flight', 'hotel', 'directions_car', 'beach_access', 'park',
      'movie', 'music_note', 'gamepad', 'casino', 'theater_comedy',
      'shopping_cart', 'local_grocery_store', 'local_mall',
      'flag', 'target', 'star', 'check_circle', 'trending_up',
      'hourglass_empty', 'schedule', 'calendar_today',
      'church', 'local_hospital', 'local_police'
    ];
  }

  static String getIconDisplayName(String iconName) {
    switch (iconName) {
      case 'work': return 'Work';
      case 'school': return 'School';
      case 'computer': return 'Computer';
      case 'book': return 'Book';
      case 'phone': return 'Phone';
      case 'meeting_room': return 'Meeting';
      case 'family_restroom': return 'Family';
      case 'home': return 'Home';
      case 'person': return 'Person';
      case 'favorite': return 'Favorite';
      case 'child_care': return 'Child Care';
      case 'fitness_center': return 'Fitness';
      case 'sports_soccer': return 'Soccer';
      case 'sports_basketball': return 'Basketball';
      case 'sports_tennis': return 'Tennis';
      case 'flight': return 'Flight';
      case 'hotel': return 'Hotel';
      case 'directions_car': return 'Car';
      case 'beach_access': return 'Beach';
      case 'park': return 'Park';
      case 'movie': return 'Movie';
      case 'music_note': return 'Music';
      case 'gamepad': return 'Gaming';
      case 'casino': return 'Casino';
      case 'theater_comedy': return 'Theater';
      case 'shopping_cart': return 'Shopping';
      case 'local_grocery_store': return 'Grocery';
      case 'local_mall': return 'Mall';
      case 'flag': return 'Flag';
      case 'target': return 'Target';
      case 'star': return 'Star';
      case 'check_circle': return 'Check';
      case 'trending_up': return 'Trending';
      case 'hourglass_empty': return 'Idle';
      case 'schedule': return 'Schedule';
      case 'calendar_today': return 'Calendar';
      case 'church': return 'Church';
      case 'local_hospital': return 'Hospital';
      case 'local_police': return 'Police';
      default: return iconName.replaceAll('_', ' ').toTitleCase();
    }
  }
}

extension StringExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
