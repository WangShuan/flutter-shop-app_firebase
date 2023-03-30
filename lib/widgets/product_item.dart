import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/product_detail_screen.dart';

import '../models/cart.dart';
import '../models/products.dart';
import '../models/auth.dart';

class ProductItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final product = Provider.of<Product>(context, listen: false);
    final cart = Provider.of<Cart>(context, listen: false);
    final token = Provider.of<Products>(context, listen: false).authToken;
    final userId = Provider.of<Auth>(context, listen: false).userId;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GridTile(
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(
              ProductDetailScreen.routeName,
              arguments: product.id,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).primaryColorLight,
              ),
            ),
            child: Image.network(
              product.imgUrl,
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
        header: GridTileBar(
          title: product.salePrice != null
              ? Text(
                  'SALE',
                  style: TextStyle(
                    color: Colors.white,
                    backgroundColor: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Anton',
                  ),
                )
              : Text(''),
          trailing: Consumer<Product>(
            builder: (context, value, child) => IconButton(
              icon: Icon(
                product.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              ),
              onPressed: () {
                product.toggleFavoriteStatus(token, userId);
              },
            ),
          ),
        ),
        footer: GridTileBar(
          backgroundColor: Theme.of(context).primaryColorDark,
          subtitle: product.salePrice == null
              ? Text(
                  'NT\$ ${product.price.toString()}',
                  textAlign: TextAlign.center,
                )
              : Text(
                  'NT\$ ${product.salePrice.toString()}',
                  textAlign: TextAlign.center,
                ),
          title: Text(
            product.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.shopping_bag,
              shadows: <Shadow>[
                Shadow(
                  color: Theme.of(context).primaryColorDark,
                  blurRadius: 5,
                )
              ],
              color: Theme.of(context).canvasColor,
              size: 20,
            ),
            onPressed: () {
              final snackBar = SnackBar(
                content: Text('${product.name} 成功加入購物車'),
                action: SnackBarAction(
                  label: '復原',
                  onPressed: () {
                    cart.removeSingleItem(product.id);
                  },
                ),
              );
              int price;
              if (product.salePrice != null) {
                price = product.salePrice;
              } else {
                price = product.price;
              }
              cart.addItem(product.id, product.name, price);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            },
          ),
        ),
      ),
    );
  }
}
