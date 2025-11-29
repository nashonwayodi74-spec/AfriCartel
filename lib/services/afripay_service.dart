import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Afripay Service - Cross-Africa Payment and Wallet Platform
class AfripayService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final String _walletsCollection = 'afripay_wallets';
  final String _transactionsCollection = 'afripay_transactions';

  /// Get current user's wallet
  Future<Map<String, dynamic>?> getWallet() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final doc = await _firestore.collection(_walletsCollection).doc(user.uid).get();

      if (!doc.exists) {
        await createWallet();
        return await getWallet();
      }

      return doc.data();
    } catch (e) {
      print('Error getting wallet: $e');
      return null;
    }
  }

  /// Create new wallet
  Future<void> createWallet() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final walletData = {
        'userId': user.uid,
        'balances': {
          'KES': 0.0,
          'NGN': 0.0,
          'GHS': 0.0,
          'TZS': 0.0,
          'UGX': 0.0,
        },
        'primaryCurrency': 'KES',
        'kycStatus': 'basic',
        'dailyLimit': 100.0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(_walletsCollection).doc(user.uid).set(walletData);
    } catch (e) {
      throw e;
    }
  }

  /// Get balance for currency
  Future<double> getBalance(String currency) async {
    try {
      final wallet = await getWallet();
      if (wallet == null) return 0.0;
      final balances = wallet['balances'] as Map<String, dynamic>;
      return (balances[currency] ?? 0.0).toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  /// Add funds to wallet
  Future<bool> addFunds({
    required double amount,
    required String currency,
    required String source,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final transactionId = _firestore.collection(_transactionsCollection).doc().id;
      
      await _firestore.collection(_transactionsCollection).doc(transactionId).set({
        'transactionId': transactionId,
        'userId': user.uid,
        'type': 'deposit',
        'amount': amount,
        'currency': currency,
        'source': source,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection(_walletsCollection).doc(user.uid).update({
        'balances.$currency': FieldValue.increment(amount),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Send money to another user
  Future<bool> sendMoney({
    required String recipientId,
    required double amount,
    required String currency,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final senderBalance = await getBalance(currency);
      if (senderBalance < amount) throw Exception('Insufficient balance');

      final transactionId = _firestore.collection(_transactionsCollection).doc().id;

      await _firestore.collection(_transactionsCollection).doc(transactionId).set({
        'transactionId': transactionId,
        'senderId': user.uid,
        'recipientId': recipientId,
        'type': 'transfer',
        'amount': amount,
        'currency': currency,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection(_walletsCollection).doc(user.uid).update({
        'balances.$currency': FieldValue.increment(-amount),
      });

      await _firestore.collection(_walletsCollection).doc(recipientId).update({
        'balances.$currency': FieldValue.increment(amount),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Process payment for AfriCartel
  Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String currency,
    required String merchantId,
    required Map<String, dynamic> orderDetails,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final balance = await getBalance(currency);
      if (balance < amount) {
        return {'success': false, 'error': 'Insufficient balance'};
      }

      final transactionId = _firestore.collection(_transactionsCollection).doc().id;

      await _firestore.collection(_transactionsCollection).doc(transactionId).set({
        'transactionId': transactionId,
        'userId': user.uid,
        'merchantId': merchantId,
        'type': 'payment',
        'amount': amount,
        'currency': currency,
        'orderDetails': orderDetails,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection(_walletsCollection).doc(user.uid).update({
        'balances.$currency': FieldValue.increment(-amount),
      });

      await _firestore.collection(_walletsCollection).doc(merchantId).update({
        'balances.$currency': FieldValue.increment(amount),
      });

      return {'success': true, 'transactionId': transactionId};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get transaction history
  Future<List<Map<String, dynamic>>> getTransactions({int limit = 20}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final querySnapshot = await _firestore
          .collection(_transactionsCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }
}
