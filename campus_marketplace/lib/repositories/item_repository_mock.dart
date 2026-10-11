import '../models/item.dart';
import 'item_repository.dart';

// ข้อมูลจำลองสำหรับทดสอบตอน Fake Store API ล่ม (ใช้ชั่วคราวเท่านั้น)
class ItemRepositoryMock implements ItemRepository {
  @override
  Future<List<Item>> getItems() async {
    return const [
      Item(
        id: 1,
        title: 'เป้สะพายหลังนักศึกษา',
        price: 450,
        description: 'เป้ใบใหญ่ ใส่โน้ตบุ๊กได้',
        category: 'bags',
        imageUrl: 'https://picsum.photos/id/1/200',
      ),
      Item(
        id: 2,
        title: 'หนังสือ Flutter มือสอง',
        price: 199.5,
        description: 'สภาพดี ไม่มีรอยขีดเขียน',
        category: 'books',
        imageUrl: 'https://picsum.photos/id/2/200',
      ),
      Item(
        id: 3,
        title: 'เครื่องคิดเลข Casio',
        price: 320,
        description: 'ใช้งานได้ปกติ',
        category: 'electronics',
        imageUrl: 'https://picsum.photos/id/3/200',
      ),
      Item(
        id: 4,
        title: 'โคมไฟตั้งโต๊ะ LED',
        price: 280,
        description: 'ปรับความสว่างได้ 3 ระดับ',
        category: 'home',
        imageUrl: 'https://picsum.photos/id/4/200',
      ),
      Item(
        id: 5,
        title: 'จักรยานพับ',
        price: 3500,
        description: 'เหมาะกับขี่ในมหาวิทยาลัย',
        category: 'sports',
        imageUrl: 'https://picsum.photos/id/5/200',
      ),
    ];
  }
}
