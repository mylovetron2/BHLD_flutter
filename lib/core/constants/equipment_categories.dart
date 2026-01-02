import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EquipmentCategory {
  final String name;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const EquipmentCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });
}

class EquipmentCategories {
  // Danh mục thiết bị theo mã vật tư
  static EquipmentCategory getCategory(int mavt, String? tenvt) {
    final tenvtLower = tenvt?.toLowerCase() ?? '';

    // Bảo vệ đầu
    if (mavt == 500500 || tenvtLower.contains('mũ')) {
      return const EquipmentCategory(
        name: 'Bảo vệ đầu',
        icon: FontAwesomeIcons.hardHat,
        color: Color(0xFFFF6D00), // Bright Orange
        backgroundColor: Color(0xFFFFE0B2),
      );
    }

    // Bảo vệ mắt
    if (mavt == 501545 || tenvtLower.contains('kính')) {
      return const EquipmentCategory(
        name: 'Bảo vệ mắt',
        icon: FontAwesomeIcons.glasses,
        color: Color(0xFF6A1B9A), // Deep Purple
        backgroundColor: Color(0xFFE1BEE7),
      );
    }

    // Bảo vệ chân
    if (mavt == 500120 || tenvtLower.contains('giày')) {
      return const EquipmentCategory(
        name: 'Bảo vệ chân',
        icon: FontAwesomeIcons.shoePrints,
        color: Color(0xFF6D4C41), // Brown
        backgroundColor: Color(0xFFD7CCC8),
      );
    }

    // Áo đi mưa
    if (mavt == 501660 ||
        tenvtLower.contains('bạt') ||
        tenvtLower.contains('mưa')) {
      return const EquipmentCategory(
        name: 'Áo đi mưa',
        icon: FontAwesomeIcons.cloudRain,
        color: Color(0xFF00ACC1), // Cyan
        backgroundColor: Color(0xFFB2EBF2),
      );
    }

    // Quần áo bảo hộ
    if (mavt == 500860 ||
        tenvtLower.contains('áo') ||
        tenvtLower.contains('quần')) {
      return const EquipmentCategory(
        name: 'Quần áo BH',
        icon: FontAwesomeIcons.vest,
        color: Color(0xFF0277BD), // Blue Darken
        backgroundColor: Color(0xFFB3E5FC),
      );
    }

    // Bảo vệ tai
    if (mavt == 10000 ||
        tenvtLower.contains('tai') ||
        tenvtLower.contains('nút')) {
      return const EquipmentCategory(
        name: 'Bảo vệ tai',
        icon: FontAwesomeIcons.earListen,
        color: Color(0xFFAFB42B), // Lime Green
        backgroundColor: Color(0xFFF0F4C3),
      );
    }

    // Bảo vệ hô hấp
    if (mavt == 20000 ||
        tenvtLower.contains('phin') ||
        tenvtLower.contains('khẩu trang') ||
        tenvtLower.contains('lọc')) {
      return const EquipmentCategory(
        name: 'Bảo vệ hô hấp',
        icon: FontAwesomeIcons.maskFace,
        color: Color(0xFFC62828), // Red Darken
        backgroundColor: Color(0xFFFFCDD2),
      );
    }

    // Bảo vệ tay
    if (tenvtLower.contains('găng') || tenvtLower.contains('tay')) {
      return const EquipmentCategory(
        name: 'Bảo vệ tay',
        icon: FontAwesomeIcons.handFist,
        color: Color(0xFF2E7D32), // Green Darken
        backgroundColor: Color(0xFFC8E6C9),
      );
    }

    // Thiết bị khác
    return const EquipmentCategory(
      name: 'Khác',
      icon: Icons.inventory_2,
      color: Color(0xFF616161), // Grey
      backgroundColor: Color(0xFFF5F5F5),
    );
  }

  // Lấy tất cả các danh mục
  static List<EquipmentCategory> getAllCategories() {
    return [
      const EquipmentCategory(
        name: 'Bảo vệ đầu',
        icon: FontAwesomeIcons.hardHat,
        color: Color(0xFFFF6D00),
        backgroundColor: Color(0xFFFFE0B2),
      ),
      const EquipmentCategory(
        name: 'Bảo vệ mắt',
        icon: FontAwesomeIcons.glasses,
        color: Color(0xFF6A1B9A),
        backgroundColor: Color(0xFFE1BEE7),
      ),
      const EquipmentCategory(
        name: 'Bảo vệ chân',
        icon: FontAwesomeIcons.shoePrints,
        color: Color(0xFF6D4C41),
        backgroundColor: Color(0xFFD7CCC8),
      ),
      const EquipmentCategory(
        name: 'Quần áo BH',
        icon: FontAwesomeIcons.vest,
        color: Color(0xFF0277BD),
        backgroundColor: Color(0xFFB3E5FC),
      ),
      const EquipmentCategory(
        name: 'Áo đi mưa',
        icon: FontAwesomeIcons.cloudRain,
        color: Color(0xFF00ACC1),
        backgroundColor: Color(0xFFB2EBF2),
      ),
      const EquipmentCategory(
        name: 'Bảo vệ tai',
        icon: FontAwesomeIcons.earListen,
        color: Color(0xFFAFB42B),
        backgroundColor: Color(0xFFF0F4C3),
      ),
      const EquipmentCategory(
        name: 'Bảo vệ hô hấp',
        icon: FontAwesomeIcons.maskFace,
        color: Color(0xFFC62828),
        backgroundColor: Color(0xFFFFCDD2),
      ),
      const EquipmentCategory(
        name: 'Bảo vệ tay',
        icon: FontAwesomeIcons.handFist,
        color: Color(0xFF2E7D32),
        backgroundColor: Color(0xFFC8E6C9),
      ),
      const EquipmentCategory(
        name: 'Khác',
        icon: Icons.inventory_2,
        color: Color(0xFF616161),
        backgroundColor: Color(0xFFF5F5F5),
      ),
    ];
  }
}
