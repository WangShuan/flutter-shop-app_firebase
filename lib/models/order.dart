import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import './cart.dart';

final firebaseUrl = dotenv.env['FIREBASE_URL'];

class Orders with ChangeNotifier {
  final authToken;
  final userId;

  Orders(this.authToken, this.userId, this._orders);
  List<Order> _orders = [];

  List<Order> get orders {
    return [..._orders];
  }

  Future<void> createOrder(List<CartItem> products, int total) {
    final t = DateTime.now();
    Uri url = Uri.https(firebaseUrl, '/orders/${userId}.json', {'auth': authToken});
    return http
        .post(url,
            body: json.encode({
              "amount": total,
              "dateTime": t.toIso8601String(), // 轉成字串版時間
              "products": products
                  .map((e) => {"id": e.id, "name": e.name, "price": e.price, "qty": e.qty})
                  .toList(),
            }))
        .then((value) {
      _orders.insert(
        0,
        Order(
          amount: total,
          dateTime: t,
          id: json.decode(value.body)['name'],
          products: products,
        ),
      );
      notifyListeners();
    });
  }

  Future<void> getOrders() async {
    Uri url = Uri.https(firebaseUrl, '/orders/${userId}.json', {'auth': authToken});

    try {
      final res = await http.get(url);
      final data = json.decode(res.body) as Map<String, dynamic>;
      final List<Order> arr = [];

      if (data == null) {
        return;
      }
      data.forEach((orderId, orderData) {
        arr.insert(
          0,
          Order(
            amount: orderData['amount'],
            dateTime: DateTime.parse(orderData['dateTime']),
            id: orderId,
            products: (orderData['products'] as List)
                .map((e) => CartItem(
                      id: e['id'],
                      name: e['name'],
                      price: e['price'],
                      qty: e['qty'],
                    ))
                .toList(),
          ),
        );
      });

      _orders = arr;
      notifyListeners();
    } catch (err) {
      throw err;
    }
  }
}

class Order {
  final String id;
  final int amount;
  final DateTime dateTime;
  final List<CartItem> products;

  Order({
    @required this.amount,
    @required this.dateTime,
    @required this.id,
    @required this.products,
  });
}
