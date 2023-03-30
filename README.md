# flutter-shop-app_firebase

## 將資料存放於 Firebase 的 HTTP Request 整理

首先需建立一個 Firebase 的專案，
選用 Realtime Database 建立資料庫(規則的部分選 test mode)
完成後會得到一個連結：https://xxxxxxxxxx.firebasedatabase.app
將該連結設為常量變數以利後續使用：
```dart
const firebaseUrl = 'xxxxxxxxxx.firebasedatabase.app';
```

>過程中如遇到讀取、寫入等問題，請至 firebase 中的 rules 修改規則內容

發送 HTTP Request 說明參考：https://docs.flutter.dev/cookbook/networking/fetch-data

- getProducts 獲取所有在資料庫中的商品們
```dart
Future<void> getProducts() async {
  Uri url = Uri.https(firebaseUrl, '/products.json'); // set http request URL

  try { // use try&catch handle error
    final res = await http.get(url); // send get request
    final data = json.decode(res.body) as Map<String, dynamic>; // get response data
    final List<Product> arr = []; // 建立一個空陣列，以將 data 存入

    if (data == null) { // 沒有資料
      return;
    }
    data.forEach((prodId, prodData) { // 解析資料，prodId 為 key，prodData 為 value
      arr.insert(
        0,
        Product(
          id: prodId,
          imgUrl: prodData['imgUrl'],
          description: prodData['description'],
          name: prodData['name'],
          price: prodData['price'],
          isFavorite: prodData['isFavorite'] == null ? false : prodData['isFavorite'], // 因 isFavorite 非必填項目，如果資料庫中抓取不到該資料則給個初始值
        ),
      );
    });

    _items = arr; // 將 _items 設為利用 data 建立的新陣列
    notifyListeners(); // update views
  } catch (err) {
    throw err;
  }
}

// products_overview_screen.dart 中初始化時呼叫 getProducts 方法
// getProducts 使用方式 1 - initState + listen false
@override
void initState() {
  Provider.of<Products>(context, listen: false).getProducts();
  super.initState();
}

// getProducts 使用方式 2 - didChangeDependencies + isInit
bool _isInit = true;
@override
void didChangeDependencies() {
  if (_isInit) {
    setState(() {
      _isLoading = true;
    });
    Provider.of<Products>(context).getProducts().then((value) {
      setState(() {
        _isLoading = false;
      });
    });
  }
  _isInit = false;
  super.didChangeDependencies();
}
```

- addProduct 新增一個商品
```dart
Future<void> addProduct(Product prod) {
  Uri url = Uri.https(firebaseUrl, '/products.json'); // set http request URL

  return http
      .post(url, // send POST http request
        body: json.encode({ // 傳入 json 格式的商品資訊
          "name": prod.name,
          "description": prod.description,
          "price": prod.price,
          "imgUrl": prod.imgUrl,
          "isFavorite": false,
        })
      )
      .then((value) {
    final newProd = Product( // 建立一個 Product
      name: prod.name,
      description: prod.description,
      price: prod.price,
      imgUrl: prod.imgUrl,
      id: json.decode(value.body)['name'], // 將 firebase 產生的隨機 key 設為商品 id
      isFavorite: false,
    );

    _items.insert(0, newProd); // 放到陣列中第一個
    notifyListeners(); // update views
  }).catchError((err) {
    throw err;
  });
}

// 在 edit_product_screen.dart 中送出表單後判斷是否有商品 id 若無則調用 addProduct
Provider.of<Products>(context, listen: false)
  .addProduct(_tempProd)
  .catchError((err) { // 處理錯誤
    return showDialog<Null>( // 顯示 alert 彈窗小部件
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('錯誤'),
        content: Text('執行操作時發生錯誤，請重試。'),
        actions: [
          TextButton(
            child: Text('好的'),
            onPressed: () => Navigator.of(ctx).pop(), // 關閉彈窗小部件
          ),
        ],
      ),
    );
  })
  .then((value) {
    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).pop(); // 關閉 editProductScreen 畫面
  });
```

- updateProduct 更新一個商品
```dart
Future<void> updateProduct(Product prod) async {
  final i = _items.indexWhere((element) => element.id == prod.id); // get index
  if (i != -1) { // 判斷 index 是否存在於 _items 中
    Uri url = Uri.https(firebaseUrl, '/products/${prod.id}.json'); // set http request URL
    try { // use try&catch handle error
      await http.patch(url, // send PATCH http request
        body: json.encode({ // 傳入要更新的內容
          "name": prod.name,
          "description": prod.description,
          "price": prod.price,
          "imgUrl": prod.imgUrl,
        })
      );
      _items[i] = prod; // 將原本的 Product 更新
      notifyListeners(); // upsate views
    } catch (err) {
      throw err;
    }
  }
}

// 在 edit_product_screen.dart 中送出表單後判斷是否有商品 id 若有則調用 updateProduct
Provider.of<Products>(context, listen: false)
  .updateProduct(_tempProd)
  .catchError((err) { // 處理錯誤
    return showDialog<Null>( // 顯示 alert 彈窗小部件
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('錯誤'),
        content: Text('執行操作時發生錯誤，請重試。'),
        actions: [
          TextButton(
            child: Text('好的'),
            onPressed: () => Navigator.of(ctx).pop(), // 關閉彈窗小部件
          ),
        ],
      ),
    );
  })
  .then((value) {
    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).pop(); // 關閉 editProductScreen 畫面
  });
```

- removeProduct 刪除一個商品
```dart
// 在 products_provider.dart 設置 removeProduct 方法
Future<void> removeProduct(String id) async {
  Uri url = Uri.https(firebaseUrl, '/products/${id}'); // set http request URL
  int i = _items.indexWhere((element) => element.id == id); // get index
  Product prod = _items[i]; // get been remove Product
  _items.removeWhere((element) => element.id == id); // remove Product
  notifyListeners(); // update views

  final res = await http.delete(url); // send delete http request
  if (res.statusCode >= 400) { // check http statusCode
    _items.insert(i, prod); // put been remove Product back
    notifyListeners(); // update views
    throw HttpException('無法刪除商品'); // throw error
  }
  prod = null; // clear Product
}

// 在 user_products_screen.dart 中的垃圾桶按鈕綁定點擊事件
onPressed: () async {
  try {
    await Provider.of<Products>(context, listen: false).removeProduct(id); // 調用 removeProduct 方法
  } catch (error) {
    scaffold.showSnackBar(SnackBar( // 如果無法刪除則顯示 SnackBar
      content: const Text('刪除失敗'),
    ));
  }
},
```
> http 第三方套件，只會針對 get 與 post 請求拋出錯誤，其餘的 put/patch/delete 請求需通過 statusCode 自行處理錯誤

- getOrders 獲取所有訂單，與 getProducts 相同，介紹第三種使用方式：
```dart
body: FutureBuilder( // use FutureBuilder
  future: Provider.of<Orders>(context, listen: false).getOrders(), // put Future here
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) { // check if is wating
      return Center(child: CircularProgressIndicator()); // return loading views
    } else { // check if done
      if (snapshot.error != null) { // if has error
        return Center(child: Text('Something wrong...')); // return a text widget
      } else { // if no error
        return Consumer<Orders>( // use Consumer here and remove final ordersData = Provider.of<Orders>(context);
          builder: (context, ordersData, child) {
            return ListView.builder(
              itemBuilder: (context, index) {
                return OrderItem(ordersData.orders[index]);
              },
              itemCount: ordersData.orders.length,
            );
          },
        );
      }
    }
  },
);
```

## 增加帳號驗證機制

首先到 firebase 的 Realtime Database 中重新設定 rules，
將其改為：
```
{
  "rules": {
    ".read": "auth != null", 
    ".write": "auth != null"
  }
}
```

接著到 firebase 的 Authentication > Sign-in method，點選『電子郵件/密碼』設為啟用後儲存，
接著新增一個 auth.dart 檔案建立 Auth 使用的 provider，並在裡面撰寫登入與註冊用的 HTTP Request
（API 參考文檔：https://firebase.google.com/docs/reference/rest/auth）

auth.dart 中主要重點如下：
```dart
bool get isAuth { // 判斷是否有取得 token
  return token != null;
}

String get token { // 獲取登入者的 token
  if (_expiryDate != null && _expiryDate.isAfter(DateTime.now()) && _token != null) {
    return _token;
  }
  return null;
}

Future<void> signup(String mail, String pwd) async {
  final Uri url = Uri.https('identitytoolkit.googleapis.com', 'v1/accounts:signUp', {'key': '[Firebase Web API key here]'}); // 參數一為主網域，參數二為網域 / 後的路徑，參數三為 ? 後參數
  try {
    final res = await http.post(url,
        body: json.encode({
          "email": mail,
          "password": pwd,
          "returnSecureToken": true,
        }));
    if (json.decode(res.body)['error'] != null) { // 確認是否有錯誤訊息，比如帳號/密碼錯誤、信箱已被使用等等錯誤訊息
      throw HttpException(json.decode(res.body)['error']);
    }
    _token = json.decode(res.body)['idToken']; // 獲取 token
    _expiryDate = DateTime.now().add(Duration(seconds: int.parse(json.decode(res.body)['expiresIn']))); // 設置過期時間為登入成功起算幾秒後
    _userId = json.decode(res.body)['localId']; // 獲取用戶 id
    notifyListeners();
  } catch (err) {
    throw err;
  }
}
```
>Firebase Web API key(網路 API 金鑰)於專案設定中可以找到

接著再新增一個 auth_screen.dart 設置登入與註冊用的輸入帳密表單畫面，
並於 main.dart 中，通過判斷是否有取得 token 以切換是否需顯示登入/註冊畫面

取得 token 後，需將所有 HTTP Request 重設為帶有 authToken 的版本，
但因 authToken 在 Auth 的 Provider 中，無法傳送至其他 Provider 使用，
所以先在要獲取 token 的 Provider 檔案中建立好 authToken 參數用以傳入 auth.token：
```dart
class Products with ChangeNotifier {
  final authToken;
  Products(this.authToken, this._items);

  List<Product> _items = [];

  // ...
}

class Orders with ChangeNotifier {
  final authToken;
  Orders(this.authToken, this._orders);

  List<Order> _orders = [];

  // ...
}
```

接著於 main.dart 中重新設定 ChangeNotifierProvider 以取得 Auth 中的參數在 Products 或 Orders 中使用，
將需要獲取 Auth 中的參數的 ChangeNotifierProvider 統一改為 ChangeNotifierProxyProvider：
```dart
providers: [
  ChangeNotifierProvider( // 1. 必須將 Auth 的 ChangeNotifierProvider 放置在最上方
    create: (ctx) => Auth(),
  ),
  ChangeNotifierProxyProvider<Auth, Products>( // 2. 將 Products 的 ChangeNotifierProvider 改為 ChangeNotifierProxyProvider<Auth, Products>
    create: (ctx) => Products(null, []), // 設置初始的 Products(authToken,_items)
    update: (ctx, auth, previous) =>
        Products(auth.token, previous == null ? [] : previous.items), // 設置實際需要使用的 Products(authToken,_items)
  ),
  ChangeNotifierProxyProvider<Auth, Orders>( // 3. 將 Orders 的 ChangeNotifierProvider 改為 ChangeNotifierProxyProvider<Auth, Orders>
    create: (ctx) => Orders(null, []), // 設置初始的 Orders(authToken,_orders)
    update: (ctx, auth, previous) =>
        Orders(auth.token, previous == null ? [] : previous.items), // 設置實際需要使用的 Orders(authToken,_orders)
  ),
  // 原本的其他 ChangeNotifierProvider ...
],
```

完成上述步驟後即可成功登入/註冊並獲取到帳號的 token/userId/expiryTime 等重要資訊，
接下來就可以為每個 HTTP Request 的 URL 加上 auth 驗證，
這部分有別於其他資料庫需通過 header 傳入，
在 firebase 中，可以通過於 ? 後帶參數的方式來發送 token 進行驗證，
(EX: https://xxxxxx.firebasedatabase.app/products.json?auth=token)
轉換為 Uri 的 URL 寫法則如下：
```dart
Uri.https(firebaseUrl, '/products.json', {'auth': authToken}); // addProduct & getProducts
Uri.https(firebaseUrl, '/userFavorites/${userId}.json', {'auth': authToken}); // 獲取某用戶的收藏紀錄
Uri.https(firebaseUrl, '/products/${prodId}.json', {'auth': authToken}); // updateProduct
Uri.https(firebaseUrl, '/products/${prodId}.json', {'auth': authToken}); // removeProduct
Uri.https(firebaseUrl, '/orders/${userId}.json', {'auth': authToken}); // createOrder & getOrders
```

對於資料庫保存的內容也需要做些調整，
1. 首頁的 products_overview 畫面應該可以瀏覽所有的商品，但如果是在商品管理的 user_products 畫面則應該只顯示當前登入者所新增過的商品，針對這部分則需要在新增商品時，於資料庫中多保存當前的 userId 為何，主要更新 addProduct 函數：
```dart
Future<void> addProduct(Product prod) {
  Uri url = Uri.https(firebaseUrl, '/products.json', {'auth': authToken});

  return http
      .post(url,
          body: json.encode({
            "name": prod.name,
            "description": prod.description,
            "price": prod.price,
            "imgUrl": prod.imgUrl,
            "user_id": userId // 新增這個 key-value ，主要為了區別該商品是被誰建立的
          }))
      .then((value) {
    final newProd = Product(
      name: prod.name,
      description: prod.description,
      price: prod.price,
      imgUrl: prod.imgUrl,
      id: json.decode(value.body)['name'],
    );

    _items.insert(0, newProd);
    notifyListeners();
  }).catchError((err) {
    throw err;
  });
}
```

2. 在商品管理中也需要更改 getProducts 函數，當處於首頁時，不需要過濾數據，但如果在呼叫 getProducts 函數時帶入了 true 參數，則表示需過濾 userId，主要更新 getProducts 函數：
```dart
Future<void> getProducts([bool filterByUser = false]) async { // 新增 filterByUser ，辨識是否獲取所有商品，且該參數應該有個預設值，可以通過 [] 的方式設定預設值
  var _params;
  if (filterByUser == true) { // 如果只需要獲取 user 所建立的商品
    _params = <String, String>{ // 設置 ? 後參數的內容
      'auth': authToken,
      'orderBy': json.encode("user_id"), // 獲取 key 為 user_id 的數據
      'equalTo': json.encode(userId), // 獲取 user_id equalTo userId 的數據
    };
  } else {
    _params = <String, String>{
      'auth': authToken,
    };
  }

  var url = Uri.https(firebaseUrl, '/products.json', _params);
  try {
    final res = await http.get(url);
    final data = json.decode(res.body) as Map<String, dynamic>;
    final List<Product> arr = [];

    if (data == null) {
      return;
    }

    data.forEach((prodId, prodData) {
      arr.insert(
        0,
        Product(
          id: prodId,
          imgUrl: prodData['imgUrl'],
          description: prodData['description'],
          name: prodData['name'],
          price: prodData['price'],
          isFavorite: prodData['isFavorite'] ? prodData['isFavorite'] : false,
        ),
      );
    });

    _items = arr;
    notifyListeners();
  } catch (err) {
    throw err;
  }
}
```

3. 在每個商品身上都有一個愛心按鈕用於切換收藏狀態，原先是將收藏狀態綁定在商品數據中，這邊應該獨立將數據傳送到資料庫中，並根據不同的 userId 進行保存，主要更新 toggleFavoriteStatus 函數：
```dart
void toggleFavoriteStatus(String token, String userId) async {
  bool oldVal = isFavorite;

  _setFavValue(!isFavorite);

  Uri url = Uri.https(firebaseUrl, '/userFavorites/${userId}/${id}.json', {'auth': token}); // 新增一個 userFavorites 的表，底下資料層級為 userId > productId: true或false
  try {
    final res = await http.put(
      url,
      body: json.encode(
        isFavorite,
      ),
    );
    if (res.statusCode >= 400) {
      _setFavValue(oldVal);
      throw HttpException('執行操作時遇到錯誤');
    }
  } catch (err) {
    _setFavValue(oldVal);
  }
}
```

4. 在資料庫中按照 userId 保存了商品是否被加入收藏後，在 getProducts 函數中，則需要抓取商品是否被加入收藏的資料用以顯示愛心，所以 getProducts 函數再次進行更新後應該如下：
```dart
Future<void> getProducts([bool filterByUser = false]) async {
  var _params;
  if (filterByUser == true) {
    _params = <String, String>{
      'auth': authToken,
      'orderBy': json.encode("user_id"),
      'equalTo': json.encode(userId),
    };
  } else {
    _params = <String, String>{
      'auth': authToken,
    };
  }

  var url = Uri.https(firebaseUrl, '/products.json', _params);
  try {
    final res = await http.get(url);
    final data = json.decode(res.body) as Map<String, dynamic>;
    final List<Product> arr = [];

    if (data == null) {
      return;
    }

    Uri favsUrl = Uri.https(firebaseUrl, '/userFavorites/${userId}.json', {'auth': authToken}); // 新增 favsUrl
    final favsRes = await http.get(favsUrl); // 獲取數據
    final favsData = json.decode(favsRes.body) as Map<String, dynamic>; // 將數據轉換為 map 類型
    data.forEach((prodId, prodData) {
      arr.insert(
        0,
        Product(
          id: prodId,
          imgUrl: prodData['imgUrl'],
          description: prodData['description'],
          name: prodData['name'],
          price: prodData['price'],
          isFavorite: favsData == null  // 查找是否有 favsData 的資料
            ? false // 若無則顯示false
            : favsData[prodId] // 若有 favsData 則再次查找是否有當前商品的資料
              ? favsData[prodId] // 若有則顯示當前商品的資料
              : false // 若無則一樣顯示 false
          // 上方的 if/else 可簡寫成 isFavorite: favsData == null ? false : favsData[prodId] ?? false, 
        ),
      );
    });

    _items = arr;
    notifyListeners();
  } catch (err) {
    throw err;
  }
}
```

自動登出：

當我們發送登入請求後，可以得到 `expiresIn` 即 `token` 會在幾秒後過期，
有了 `expiresIn` 後就可以通過計時器計算過期時間，時間到時就執行登出的動作，

使用方式：
  1. 引入 `import 'dart:async';` 以使用 `Timer()`
  2. 設置 `logout` 函數，將登入時獲取到的 `token`/`userId`/`expiresIn` 都設為 `null`
  3. 建立 `_autoLogout` 函數，調用 `Timer()` 方法，執行 `logout` 函數進行自動登出
  4. 在發送登入請求成功後調用 `_autoLogout` 函數，開始跑計時登出
  5. 將 `Timer()` 設置為一個參數，當主動進行登出時，就將計時器取消，以避免自動登出與主動登出產生重複

重點程式碼如下：
```dart
Timer _authTimer; // 設置一個存放計時器的變數

Future<void> login(String mail, String pwd) async {
  final Uri url = Uri.https('identitytoolkit.googleapis.com', {'key': '[Firebase Web API key here]'});
  try {
    final res = await http.post(url,
      body: json.encode({
        "email": mail,
        "password": pwd,
        "returnSecureToken": true,
      })
    );
    
    if (json.decode(res.body)['error'] != null) { // 處理錯誤
      throw HttpException(json.decode(res.body)['error']['message']);
    }
    
    // 保存回傳的重要數據
    _token = json.decode(res.body)['idToken'];
    _expiryDate = DateTime.now().add(Duration(seconds: int.parse(json.decode(res.body)['expiresIn'])));
    _userId = json.decode(res.body)['localId'];
    
    _autoLogout(); // 開始執行自動登出
    
    notifyListeners();
  } catch (err) {
    throw err;
  }
}

void logout() { // 登出函數
  _token = null;
  _userId = null;
  _expiryDate = null;
  _authTimer = null;
  notifyListeners();
}

void _autoLogout() { // 自動登出函數
  if (_authTimer != null) { // 如果計時器已存在就取消以重置計時器
    _authTimer.cancel();
  }
  int expirySeconds = _expiryDate.difference(DateTime.now()).inSeconds; // 獲取當前時間與過期時間的總秒數
  _authTimer = Timer(Duration(seconds: expirySeconds), logout); // 設置計時器，時間到時執行登出函數
}
```

自動登入：
在 `flutter` 中，有個第三方依賴 `shared_preferences` 可以用來將資料存儲到設備中
我們可以通過 `shared_preferences` ，將登入後獲取到的資料保存到手機中，
當用戶關閉 APP 再重新打開食，撈取設備中保存的資料進行處理，即可自動登入帳號

使用方式：
  1. 安裝並引入 shared_preferences ([點此前往 flutter.dev](https://pub.dev/packages/shared_preferences/install))
  2. 通過 `final prefs = await SharedPreferences.getInstance();` 獲取 Shared Preferences
  3. 通過 `prefs.setString(key, value);` 存入特定資料
  4. 通過 `prefs.getString(key)` 取出特定資料以做使用

重點程式碼如下：
```dart
import 'package:shared_preferences/shared_preferences.dart'; // 引入 SharedPreferences

class Auth with ChangeNotifier {
  String _token;
  DateTime _expiryDate;
  String _userId;
  Timer _authTimer;

  Future<void> _authenticate(String mail, String pwd, String urlPath) async {
    final Uri url = Uri.https(
      'identitytoolkit.googleapis.com',
      urlPath,
      {'key': '[Firebase Web API key here]'},
    );
    
    try {
      final res = await http.post(
        url,
        body: json.encode({
          "email": mail,
          "password": pwd,
          "returnSecureToken": true,
        }),
      );
      
      _token = json.decode(res.body)['idToken'];
      _expiryDate = DateTime.now().add(Duration(
        seconds: int.parse(json.decode(res.body)['expiresIn']),
      ));
      _userId = json.decode(res.body)['localId'];
      
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance(); // 獲取 Shared Preferences
      final userData = json.encode({ // 建立 json 格式的數據保存 userData 資料
        "token": _token,
        "userId": _userId,
        "expiryDate": _expiryDate.toIso8601String(),
      });
      prefs.setString("userData", userData); // 將 userData 存到 Shared Preferences 中
    } catch (err) {
      throw err;
    }
  }

  Future<void> tryAutoLogin() async { // 建立一個 Future 類型的函數回傳布林值判斷是否有自動登入
    final prefs = await SharedPreferences.getInstance(); // 獲取 Shared Preferences
    if (!prefs.containsKey("userData")) { // 判斷是否有 userData 的 key
      return false;
    }
    final data = json.decode(prefs.getString("userData")) as Map<String, Object>; // 將 userData 轉換為 Map
    final expiryDate = DateTime.parse(data['expiryDate']); // 獲取過期時間
    if (expiryDate.isBefore(DateTime.now())) { // 判斷過期時間是否比現在時間更早
      return false;
    }

    // 重新保存登入數據
    _token = data['token'];
    _expiryDate = expiryDate;
    _userId = data['userId'];
    
    notifyListeners();
    
    // 執行自動登出函數
    _autoLogout();
    
    return true; // 回傳 ture 告知已成功自動登入
  }

  // 自動登出函數
  Future<void> logout() async {
    _token = null;
    _userId = null;
    _expiryDate = null;
    _authTimer = null;

    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance(); // 獲取 Shared Preferences
    prefs.remove("userData"); // 從 Shared Preferences 中移除 userData
    // prefs.clear(); // 從 Shared Preferences 中清空所有資料
  }

  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer.cancel();
    }
    int expirySeconds = _expiryDate.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(Duration(seconds: expirySeconds), logout);
  }
}
```
