import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Products Collection
  Stream<List<ProductModel>> getProducts() {
    return _firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<ProductModel>> getProductsByCategory(String category) {
    return _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addProduct(ProductModel product) async {
    await _firestore.collection('products').add(product.toMap());
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _firestore.collection('products').doc(id).update(data);
  }

  Future<void> deleteProduct(String id) async {
    await _firestore.collection('products').doc(id).update({'isActive': false});
  }

  // Users Collection
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  // Orders Collection
  Future<String> createOrder(Map<String, dynamic> orderData) async {
    final docRef = await _firestore.collection('orders').add(orderData);
    return docRef.id;
  }

  Stream<List<Map<String, dynamic>>> getUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // Categories Collection
  Stream<List<Map<String, dynamic>>> getCategories() {
    return _firestore
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }
}
