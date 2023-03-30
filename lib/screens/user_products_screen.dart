import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './edit_product_screen.dart';

import '../models/products.dart';

import '../widgets/user_product_item.dart';
import '../widgets/add_drawer.dart';

class UserProductsScreen extends StatelessWidget {
  static const routeName = '/user-products';
  const UserProductsScreen({Key key}) : super(key: key);

  Future<void> _refreshProds(BuildContext context) async {
    await Provider.of<Products>(context, listen: false).getProducts(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColorLight,
      appBar: AppBar(
        title: const Text('商品一覽'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(EditProductScreen.routeName);
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: FutureBuilder(
        future: Provider.of<Products>(context, listen: false).getProducts(true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LinearProgressIndicator();
          } else {
            if (snapshot.error != null) {
              print(snapshot.error);
              return Center(
                child: Text(
                  'Something wrong...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              );
            } else {
              return RefreshIndicator(
                onRefresh: () => _refreshProds(context),
                child: Consumer<Products>(
                  builder: (context, productsData, child) =>
                      productsData.items.length > 0
                          ? Padding(
                              padding: const EdgeInsets.all(5),
                              child: ListView.builder(
                                itemBuilder: (context, index) {
                                  return UserProductItem(
                                    title: productsData.items[index].name,
                                    imgUrl: productsData.items[index].imgUrl,
                                    price: productsData.items[index].price,
                                    salePrice:
                                        productsData.items[index].salePrice,
                                    id: productsData.items[index].id,
                                  );
                                },
                                itemCount: productsData.items.length,
                              ),
                            )
                          : Center(
                              child: Text(
                              '- 目前店內沒有商品 -',
                              style: Theme.of(context).textTheme.titleLarge,
                            )),
                ),
              );
            }
          }
        },
      ),
    );
  }
}
