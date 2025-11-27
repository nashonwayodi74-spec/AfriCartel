import 'dart:convert';
import 'package:http/http.dart' as http;

class MpesaService {
  // Safaricom Daraja API Credentials
  // REPLACE WITH YOUR CREDENTIALS FROM:
  // https://developer.safaricom.co.ke/
  
  static const String consumerKey = 'YOUR_CONSUMER_KEY';
  static const String consumerSecret = 'YOUR_CONSUMER_SECRET';
  static const String passKey = 'YOUR_PASS_KEY';
  static const String shortCode = 'YOUR_SHORT_CODE';
  static const String callbackUrl = 'YOUR_CALLBACK_URL';
  
  // Sandbox URL (change to production when ready)
  static const String baseUrl = 'https://sandbox.safaricom.co.ke';
  
  // Get Access Token
  Future<String?> getAccessToken() async {
    try {
      String credentials = base64Encode(
        utf8.encode('$consumerKey:$consumerSecret'),
      );
      
      final response = await http.get(
        Uri.parse('$baseUrl/oauth/v1/generate?grant_type=client_credentials'),
        headers: {'Authorization': 'Basic $credentials'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['access_token'];
      }
      return null;
    } catch (e) {
      print('Error getting access token: $e');
      return null;
    }
  }
  
  // Initiate STK Push
  Future<Map<String, dynamic>?> initiateSTKPush({
    required String phoneNumber,
    required double amount,
    required String accountReference,
    required String transactionDesc,
  }) async {
    try {
      String? accessToken = await getAccessToken();
      if (accessToken == null) return null;
      
      String timestamp = DateTime.now()
          .toString()
          .replaceAll(RegExp(r'[^0-9]'), '')
          .substring(0, 14);
      
      String password = base64Encode(
        utf8.encode('$shortCode$passKey$timestamp'),
      );
      
      final response = await http.post(
        Uri.parse('$baseUrl/mpesa/stkpush/v1/processrequest'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'BusinessShortCode': shortCode,
          'Password': password,
          'Timestamp': timestamp,
          'TransactionType': 'CustomerPayBillOnline',
          'Amount': amount.toInt(),
          'PartyA': phoneNumber,
          'PartyB': shortCode,
          'PhoneNumber': phoneNumber,
          'CallBackURL': callbackUrl,
          'AccountReference': accountReference,
          'TransactionDesc': transactionDesc,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error initiating STK push: $e');
      return null;
    }
  }
}
