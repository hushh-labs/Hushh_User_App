import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_model.dart';
import '../../domain/entities/cart_entity.dart';

/// Data service for cart persistence using SharedPreferences
/// Follows clean architecture by providing data access abstraction
class CartDataService {
  static const String _cartKey = 'discover_cart';

  SharedPreferences? _prefs;

  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save cart to local storage
  Future<void> saveCart(CartEntity cart) async {
    try {
      await _ensureInitialized();
      final cartModel = CartModel.fromEntity(cart);
      final jsonString = jsonEncode(cartModel.toJson());
      await _prefs!.setString(_cartKey, jsonString);
    } catch (e) {
      throw CartDataException('Failed to save cart: $e');
    }
  }

  /// Load cart from local storage
  Future<CartEntity> loadCart() async {
    try {
      await _ensureInitialized();
      final jsonString = _prefs!.getString(_cartKey);

      if (jsonString == null || jsonString.isEmpty) {
        return CartEntity(lastUpdated: DateTime.now());
      }

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final cartModel = CartModel.fromJson(jsonMap);
      return cartModel.toEntity();
    } catch (e) {
      // If there's any error loading, return empty cart
      return CartEntity(lastUpdated: DateTime.now());
    }
  }

  /// Clear cart from local storage
  Future<void> clearCart() async {
    try {
      await _ensureInitialized();
      await _prefs!.remove(_cartKey);
    } catch (e) {
      throw CartDataException('Failed to clear cart: $e');
    }
  }

  /// Check if cart exists in storage
  Future<bool> hasCart() async {
    try {
      await _ensureInitialized();
      return _prefs!.containsKey(_cartKey);
    } catch (e) {
      return false;
    }
  }
}

class CartDataException implements Exception {
  final String message;

  const CartDataException(this.message);

  @override
  String toString() => 'CartDataException: $message';
}
