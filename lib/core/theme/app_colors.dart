import 'dart:ui';

abstract final class AppColors {
  // Background gradient stops
  static const bgTop = Color(0xFFFFF8F0);
  static const bgUpperMid = Color(0xFFFFE8D6);
  static const bgLowerMid = Color(0xFFFFDCC4);
  static const bgBottom = Color(0xFFFFD0B0);

  // Primary accent
  static const orange = Color(0xFFFF6B35);
  static const orangeDark = Color(0xFFE85D26);

  // Text
  static const heading = Color(0xFF1A1B2E);
  static const body = Color(0xFF3D2B30);
  static const subtitle = Color(0xB33D2B30); // 70%
  static const muted = Color(0x803D2B30); // 50%
  static const dimmed = Color(0x663D2B30); // 40%

  // Stars & hearts
  static const starFilled = Color(0xFFFF6B35);
  static const starEmpty = Color(0xFFE8DDD4);
  static const heartFilled = Color(0xFFFF4757);

  // Green accent
  static const green = Color(0xFF2ED573);
  static const greenLight = Color(0xFF7BED9F);

  // Cards & surfaces
  static const cardBg = Color(0x73FFFFFF); // 45%
  static const cardBgStrong = Color(0xA6FFFFFF); // 65%
  static const glassBorder = Color(0x66FFFFFF); // 40%
  static const inputBg = Color(0xB3FFFFFF); // 70%

  // Decorative circles
  static const circleOrange = Color(0x14FF6B35); // 8%
  static const circleGreen = Color(0x122ED573); // 7%
  static const circleGold = Color(0x14FFB627); // 8%

  // Misc
  static const locked = Color(0x592D3047); // node locked
  static const connectorDone = Color(0xFF2D3047);
  static const connectorUndone = Color(0x1A2D3047);
}
