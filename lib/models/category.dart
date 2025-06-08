// lib/models/category.dart

class Category {
  final String name;
  final int icon; // 图标代码点

  Category({required this.name, required this.icon});

  // 从 JSON 对象创建 Category 实例的工厂构造函数
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name'],
      // JSON 中的 icon 是字符串 "0xe25c"，需要解析为整数
      icon: int.parse(json['icon']),
    );
  }
}
