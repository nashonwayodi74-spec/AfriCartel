import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// AfriCDSA Service - African Centre for Data Science and Analytics
/// 
/// Provides analytics, recommendations, insights, and data processing
/// for AfriCartel and Afripay platforms.
class AfriCDSAService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final String _analyticsCollection = 'africdsa_analytics';
  final String _recommendationsCollection = 'africdsa_recommendations';
  final String _insightsCollection = 'africdsa_insights';

  /// Get user analytics dashboard data
  Future<Map<String, dynamic>> getUserDashboard() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user's activity metrics
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      final transactionsSnapshot = await _firestore
          .collection('afripay_transactions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      // Calculate metrics
      final totalOrders = ordersSnapshot.size;
      final totalSpent = ordersSnapshot.docs
          .map((doc) => (doc.data()['totalAmount'] ?? 0.0) as double)
          .fold(0.0, (sum, amount) => sum + amount);

      final totalTransactions = transactionsSnapshot.size;
      final transactionVolume = transactionsSnapshot.docs
          .map((doc) => (doc.data()['amount'] ?? 0.0) as double)
          .fold(0.0, (sum, amount) => sum + amount);

      return {
        'userId': user.uid,
        'orders': {
          'total': totalOrders,
          'totalSpent': totalSpent,
          'averageOrderValue': totalOrders > 0 ? totalSpent / totalOrders : 0.0,
        },
        'transactions': {
          'total': totalTransactions,
          'volume': transactionVolume,
          'averageTransaction': totalTransactions > 0 ? transactionVolume / totalTransactions : 0.0,
        },
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error getting dashboard: $e');
      return {};
    }
  }

  /// Get personalized product recommendations
  Future<List<Map<String, dynamic>>> getRecommendations({int limit = 10}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user's order history
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .get();

      // Extract categories from past orders
      Set<String> purchasedCategories = {};
      for (var doc in ordersSnapshot.docs) {
        final items = doc.data()['items'] as List?;
        if (items != null) {
          for (var item in items) {
            final category = item['category'] as String?;
            if (category != null) {
              purchasedCategories.add(category);
            }
          }
        }
      }

      // Get recommendations based on purchased categories
      if (purchasedCategories.isEmpty) {
        // Return popular products for new users
        return await getPopularProducts(limit: limit);
      }

      // Fetch products from categories user has shown interest in
      final recommendedProducts = <Map<String, dynamic>>[];
      for (var category in purchasedCategories.take(3)) {
        final productsSnapshot = await _firestore
            .collection('products')
            .where('category', isEqualTo: category)
            .where('available', isEqualTo: true)
            .limit(limit ~/ purchasedCategories.length)
            .get();

        recommendedProducts.addAll(
          productsSnapshot.docs.map((doc) => {
            ...doc.data(),
            'productId': doc.id,
            'recommendationReason': 'Based on your interest in $category',
          }).toList(),
        );
      }

      return recommendedProducts.take(limit).toList();
    } catch (e) {
      print('Error getting recommendations: $e');
      return [];
    }
  }

  /// Get popular products across platform
  Future<List<Map<String, dynamic>>> getPopularProducts({int limit = 10}) async {
    try {
      // Get products with highest purchase count
      final productsSnapshot = await _firestore
          .collection('products')
          .where('available', isEqualTo: true)
          .orderBy('purchaseCount', descending: true)
          .limit(limit)
          .get();

      return productsSnapshot.docs
          .map((doc) => {...doc.data(), 'productId': doc.id})
          .toList();
    } catch (e) {
      print('Error getting popular products: $e');
      return [];
    }
  }

  /// Get spending insights
  Future<Map<String, dynamic>> getSpendingInsights() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Get current month transactions
      final transactionsSnapshot = await _firestore
          .collection('afripay_transactions')
          .where('userId', isEqualTo: user.uid)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      final totalSpent = transactionsSnapshot.docs
          .where((doc) => doc.data()['type'] == 'payment')
          .map((doc) => (doc.data()['amount'] ?? 0.0) as double)
          .fold(0.0, (sum, amount) => sum + amount);

      // Category breakdown
      Map<String, double> categorySpending = {};
      for (var doc in transactionsSnapshot.docs) {
        if (doc.data()['type'] == 'payment') {
          final orderDetails = doc.data()['orderDetails'] as Map?;
          final category = orderDetails?['category'] as String? ?? 'Other';
          final amount = (doc.data()['amount'] ?? 0.0) as double;
          categorySpending[category] = (categorySpending[category] ?? 0.0) + amount;
        }
      }

      return {
        'userId': user.uid,
        'month': '${now.year}-${now.month.toString().padLeft(2, '0')}',
        'totalSpent': totalSpent,
        'transactionCount': transactionsSnapshot.size,
        'categoryBreakdown': categorySpending,
        'topCategory': categorySpending.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key,
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error getting spending insights: $e');
      return {};
    }
  }

  /// Track user behavior for analytics
  Future<void> trackEvent({
    required String eventType,
    required Map<String, dynamic> eventData,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection(_analyticsCollection).add({
        'userId': user.uid,
        'eventType': eventType,
        'eventData': eventData,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error tracking event: $e');
    }
  }

  /// Get trending products in user's region
  Future<List<Map<String, dynamic>>> getTrendingProducts({
    required String region,
    int limit = 10,
  }) async {
    try {
      // Get products with high recent activity in the region
      final productsSnapshot = await _firestore
          .collection('products')
          .where('available', isEqualTo: true)
          .where('region', isEqualTo: region)
          .orderBy('viewCount', descending: true)
          .limit(limit)
          .get();

      return productsSnapshot.docs
          .map((doc) => {
            ...doc.data(),
            'productId': doc.id,
            'trending': true,
          })
          .toList();
    } catch (e) {
      print('Error getting trending products: $e');
      return [];
    }
  }

  /// Generate sales forecast for vendors
  Future<Map<String, dynamic>> getSalesForecast(String vendorId) async {
    try {
      // Get vendor's historical sales data
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('vendorId', isEqualTo: vendorId)
          .where('status', isEqualTo: 'completed')
          .orderBy('createdAt', descending: true)
          .limit(90) // Last 90 days
          .get();

      if (ordersSnapshot.docs.isEmpty) {
        return {'error': 'Insufficient data for forecast'};
      }

      // Simple moving average for next 30 days
      final totalSales = ordersSnapshot.docs
          .map((doc) => (doc.data()['totalAmount'] ?? 0.0) as double)
          .fold(0.0, (sum, amount) => sum + amount);

      final avgDailySales = totalSales / ordersSnapshot.size;
      final forecastedMonthlySales = avgDailySales * 30;

      return {
        'vendorId': vendorId,
        'historicalDays': ordersSnapshot.size,
        'averageDailySales': avgDailySales,
        'forecastedMonthlySales': forecastedMonthlySales,
        'confidence': 'medium', // Simplified
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error generating forecast: $e');
      return {};
    }
  }

  /// Get customer insights for vendors
  Future<Map<String, dynamic>> getCustomerInsights(String vendorId) async {
    try {
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('vendorId', isEqualTo: vendorId)
          .get();

      // Calculate metrics
      final uniqueCustomers = <String>{};
      final repeatCustomers = <String>{};
      final customerOrderCount = <String, int>{};

      for (var doc in ordersSnapshot.docs) {
        final customerId = doc.data()['userId'] as String;
        uniqueCustomers.add(customerId);
        customerOrderCount[customerId] = (customerOrderCount[customerId] ?? 0) + 1;
        
        if (customerOrderCount[customerId]! > 1) {
          repeatCustomers.add(customerId);
        }
      }

      final repeatRate = uniqueCustomers.isNotEmpty
          ? (repeatCustomers.length / uniqueCustomers.length) * 100
          : 0.0;

      return {
        'vendorId': vendorId,
        'totalCustomers': uniqueCustomers.length,
        'repeatCustomers': repeatCustomers.length,
        'repeatRate': repeatRate.toStringAsFixed(1) + '%',
        'totalOrders': ordersSnapshot.size,
        'averageOrdersPerCustomer': uniqueCustomers.isNotEmpty
            ? (ordersSnapshot.size / uniqueCustomers.length).toStringAsFixed(2)
            : '0',
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error getting customer insights: $e');
      return {};
    }
  }
}
