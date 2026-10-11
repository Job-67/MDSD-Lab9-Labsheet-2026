import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:campus_marketplace/home_page.dart';
import 'package:campus_marketplace/models/cart_model.dart';
import 'package:campus_marketplace/models/favorites_model.dart';
import 'package:campus_marketplace/models/item.dart';
import 'package:campus_marketplace/repositories/item_repository.dart';

class FakeItemRepository implements ItemRepository {
  @override
  Future<List<Item>> getItems() async => <Item>[];
}

void main() {
  testWidgets('HomePage shows app title and saved count', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => FavoritesModel()),
          ChangeNotifierProvider(create: (context) => CartModel()),
        ],
        child: MaterialApp(
          home: HomePage(repository: FakeItemRepository()),
        ),
      ),
    );

    expect(find.text('Campus Marketplace'), findsOneWidget);
    expect(find.text(' 0'), findsNWidgets(2)); // favorites count + cart count
  });
}
