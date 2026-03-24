import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/pending_order.dart';
import '../models/pizza.dart';
import '../constants/app_storage_keys.dart';
import '../services/order_exceptions.dart';
import '../utils/storage_service.dart';
import '../utils/time_validator.dart';
import '../constants/app_strings.dart';
import '../constants/app_thresholds.dart';

enum OrderStatus { onTime, comingSoon, slightlyLate, late }

class OrderStatusInfo {
  final OrderStatus status;
  final String statusText;
  final IconData icon;

  OrderStatusInfo({
    required this.status,
    required this.statusText,
    required this.icon,
  });
}

class OrderService extends ChangeNotifier {
  static final Uuid _uuid = Uuid();
  List<PendingOrder> _orders = [];
  int _lateMinutes = AppThresholds.defaultLateMinutes;
  int _slightlyLateMinutes = AppThresholds.defaultSlightlyLateMinutes;
  int _onTimeMinutes = AppThresholds.defaultOnTimeMinutes;
  int _comingSoonMinutes = AppThresholds.defaultComingSoonMinutes;
  bool _thresholdsLoaded = false;

  OrderService() {
    _loadThresholds();
  }

  List<PendingOrder> get orders => List.unmodifiable(_orders);
  int get lateMinutes => _lateMinutes;
  int get slightlyLateMinutes => _slightlyLateMinutes;
  int get onTimeMinutes => _onTimeMinutes;
  int get comingSoonMinutes => _comingSoonMinutes;
  bool get thresholdsLoaded => _thresholdsLoaded;

  bool get hasOrders => _orders.isNotEmpty;

  int get orderCount => _orders.length;

  Future<void> _loadThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    final late =
        prefs.getInt(AppStorageKeys.lateThresholdMinutes) ??
        AppThresholds.defaultLateMinutes;
    final slightlyLate =
        prefs.getInt(AppStorageKeys.slightlyLateThresholdMinutes) ??
        AppThresholds.defaultSlightlyLateMinutes;
    final onTime =
        prefs.getInt(AppStorageKeys.onTimeThresholdMinutes) ??
        AppThresholds.defaultOnTimeMinutes;
    final comingSoon =
        prefs.getInt(AppStorageKeys.comingSoonThresholdMinutes) ??
        AppThresholds.defaultComingSoonMinutes;

    if (!_areThresholdsValid(
      lateMinutes: late,
      slightlyLateMinutes: slightlyLate,
      onTimeMinutes: onTime,
      comingSoonMinutes: comingSoon,
    )) {
      _lateMinutes = AppThresholds.defaultLateMinutes;
      _slightlyLateMinutes = AppThresholds.defaultSlightlyLateMinutes;
      _onTimeMinutes = AppThresholds.defaultOnTimeMinutes;
      _comingSoonMinutes = AppThresholds.defaultComingSoonMinutes;
      await _saveThresholds();
    } else {
      _lateMinutes = late;
      _slightlyLateMinutes = slightlyLate;
      _onTimeMinutes = onTime;
      _comingSoonMinutes = comingSoon;
    }

    _thresholdsLoaded = true;
    notifyListeners();
  }

  Future<void> _saveThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppStorageKeys.lateThresholdMinutes, _lateMinutes);
    await prefs.setInt(
      AppStorageKeys.slightlyLateThresholdMinutes,
      _slightlyLateMinutes,
    );
    await prefs.setInt(AppStorageKeys.onTimeThresholdMinutes, _onTimeMinutes);
    await prefs.setInt(
      AppStorageKeys.comingSoonThresholdMinutes,
      _comingSoonMinutes,
    );
  }

  bool _areThresholdsValid({
    required int lateMinutes,
    required int slightlyLateMinutes,
    required int onTimeMinutes,
    required int comingSoonMinutes,
  }) {
    return lateMinutes < slightlyLateMinutes &&
        slightlyLateMinutes < onTimeMinutes &&
        onTimeMinutes <= comingSoonMinutes;
  }

  Future<bool> setStatusThresholds({
    required int lateMinutes,
    required int slightlyLateMinutes,
    required int onTimeMinutes,
    required int comingSoonMinutes,
  }) async {
    if (!_areThresholdsValid(
      lateMinutes: lateMinutes,
      slightlyLateMinutes: slightlyLateMinutes,
      onTimeMinutes: onTimeMinutes,
      comingSoonMinutes: comingSoonMinutes,
    )) {
      return false;
    }

    if (_lateMinutes == lateMinutes &&
        _slightlyLateMinutes == slightlyLateMinutes &&
        _onTimeMinutes == onTimeMinutes &&
        _comingSoonMinutes == comingSoonMinutes) {
      return true;
    }

    _lateMinutes = lateMinutes;
    _slightlyLateMinutes = slightlyLateMinutes;
    _onTimeMinutes = onTimeMinutes;
    _comingSoonMinutes = comingSoonMinutes;
    notifyListeners();
    await _saveThresholds();
    return true;
  }

  Future<void> resetStatusThresholdsToDefaults() async {
    _lateMinutes = AppThresholds.defaultLateMinutes;
    _slightlyLateMinutes = AppThresholds.defaultSlightlyLateMinutes;
    _onTimeMinutes = AppThresholds.defaultOnTimeMinutes;
    _comingSoonMinutes = AppThresholds.defaultComingSoonMinutes;
    notifyListeners();
    await _saveThresholds();
  }

  Future<void> loadOrders() async {
    _orders = await StorageService.loadPendingOrders();
    _sortOrders();
    notifyListeners();
  }

  void _sortOrders() {
    _orders.sort((a, b) => a.pickupDateTime.compareTo(b.pickupDateTime));
  }

  Future<void> addOrder(PendingOrder order) async {
    await StorageService.savePendingOrder(order);
    _orders.add(order);
    _sortOrders();
    notifyListeners();
  }

  Future<void> removeOrder(String orderId) async {
    await StorageService.removePendingOrder(orderId);
    _orders.removeWhere((order) => order.id == orderId);
    notifyListeners();
  }

  PendingOrder? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  OrderStatusInfo getOrderStatus(PendingOrder order) {
    final now = DateTime.now();
    final pickupTime = order.pickupDateTime;
    final difference = pickupTime.difference(now).inMinutes;

    if (difference < _lateMinutes) {
      return OrderStatusInfo(
        status: OrderStatus.late,
        statusText: AppStrings.orderStatusLate,
        icon: Icons.warning,
      );
    } else if (difference < _slightlyLateMinutes) {
      return OrderStatusInfo(
        status: OrderStatus.slightlyLate,
        statusText: AppStrings.orderStatusSlightlyLate,
        icon: Icons.access_time,
      );
    } else if (difference == _onTimeMinutes) {
      return OrderStatusInfo(
        status: OrderStatus.onTime,
        statusText: AppStrings.orderStatusOnTime,
        icon: Icons.check_circle,
      );
    } else if (difference <= _comingSoonMinutes) {
      return OrderStatusInfo(
        status: OrderStatus.comingSoon,
        statusText: AppStrings.orderStatusComingSoon,
        icon: Icons.schedule,
      );
    } else {
      return OrderStatusInfo(
        status: OrderStatus.onTime,
        statusText: AppStrings.orderStatusOnTime,
        icon: Icons.check_circle,
      );
    }
  }

  Future<PendingOrder> createOrder({
    required List<Pizza> items,
    required double amount,
    required String pickupTime,
  }) async {
    if (items.isEmpty) {
      throw const EmptyOrderItemsException();
    }
    if (amount <= 0) {
      throw InvalidOrderAmountException(amount);
    }
    if (!TimeValidator.isValidHHmm(pickupTime)) {
      throw InvalidPickupTimeException(pickupTime);
    }

    final order = PendingOrder(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      plannedPickupTime: pickupTime,
      items: items,
      amount: amount,
    );
    await addOrder(order);
    return order;
  }
}
