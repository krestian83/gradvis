import 'dart:ui';

/// Store item categories and their items.
const storeCategories = [
  StoreCategory(
    name: 'Rammer',
    icon: '🖼️',
    columns: 2,
    items: [
      StoreItem(
        id: 'f1',
        name: 'Gull',
        icon: '✨',
        price: 50,
        previewColors: [Color(0xFFFFD700), Color(0xFFFFA500)],
      ),
      StoreItem(
        id: 'f2',
        name: 'Regnbue',
        icon: '🌈',
        price: 80,
        previewColors: [
          Color(0xFFFF6B6B),
          Color(0xFFFFE66D),
          Color(0xFF4ECB71),
          Color(0xFF45B7D1),
          Color(0xFFB56EFF),
        ],
      ),
      StoreItem(
        id: 'f3',
        name: 'Is',
        icon: '❄️',
        price: 60,
        previewColors: [Color(0xFFA0D8F0), Color(0xFFE0F0FF)],
      ),
      StoreItem(
        id: 'f4',
        name: 'Flamme',
        icon: '🔥',
        price: 100,
        previewColors: [
          Color(0xFFFF4500),
          Color(0xFFFF8C00),
          Color(0xFFFFD700),
        ],
      ),
      StoreItem(
        id: 'f5',
        name: 'Galakse',
        icon: '🌌',
        price: 120,
        previewColors: [
          Color(0xFF1A1B2E),
          Color(0xFF6B3FA0),
          Color(0xFFFF6EC7),
        ],
      ),
    ],
  ),
  StoreCategory(
    name: 'Tema',
    icon: '🎨',
    columns: 2,
    items: [
      StoreItem(
        id: 't1',
        name: 'Hav',
        icon: '🌊',
        price: 150,
        previewColors: [
          Color(0xFF0077B6),
          Color(0xFF48CAE4),
          Color(0xFF90E0EF),
        ],
        vertical: true,
      ),
      StoreItem(
        id: 't2',
        name: 'Skog',
        icon: '🌲',
        price: 150,
        previewColors: [
          Color(0xFF2D6A4F),
          Color(0xFF52B788),
          Color(0xFF95D5B2),
        ],
        vertical: true,
      ),
      StoreItem(
        id: 't3',
        name: 'Solnedgang',
        icon: '🌅',
        price: 200,
        previewColors: [
          Color(0xFFFF6B6B),
          Color(0xFFFFA07A),
          Color(0xFFFFD93D),
        ],
        vertical: true,
      ),
      StoreItem(
        id: 't4',
        name: 'Natt',
        icon: '🌙',
        price: 200,
        previewColors: [
          Color(0xFF1A1A2E),
          Color(0xFF16213E),
          Color(0xFF0F3460),
        ],
        vertical: true,
      ),
      StoreItem(
        id: 't5',
        name: 'Godteri',
        icon: '🍬',
        price: 250,
        previewColors: [
          Color(0xFFFF9FF3),
          Color(0xFFFECA57),
          Color(0xFF54A0FF),
        ],
        vertical: true,
      ),
    ],
  ),
  StoreCategory(
    name: 'Emoji',
    icon: '😎',
    columns: 3,
    items: [
      StoreItem(id: 'e1', name: 'Ninja', icon: '🥷', price: 40),
      StoreItem(id: 'e2', name: 'Drage', icon: '🐲', price: 60),
      StoreItem(id: 'e3', name: 'Astronaut', icon: '🧑\u200d🚀', price: 80),
      StoreItem(id: 'e4', name: 'Trollmann', icon: '🧙', price: 50),
      StoreItem(id: 'e5', name: 'Zombie', icon: '🧟', price: 70),
      StoreItem(id: 'e6', name: 'Superhelter', icon: '🦸', price: 90),
      StoreItem(id: 'e7', name: 'Prinsesse', icon: '👸', price: 60),
      StoreItem(id: 'e8', name: 'Robot', icon: '🤖', price: 100),
    ],
  ),
];

class StoreCategory {
  final String name;
  final String icon;
  final int columns;
  final List<StoreItem> items;

  const StoreCategory({
    required this.name,
    required this.icon,
    required this.columns,
    required this.items,
  });
}

class StoreItem {
  final String id;
  final String name;
  final String icon;
  final int price;
  final List<Color> previewColors;
  final bool vertical;

  const StoreItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.price,
    this.previewColors = const [],
    this.vertical = false,
  });

  bool get hasPreview => previewColors.isNotEmpty;
}
