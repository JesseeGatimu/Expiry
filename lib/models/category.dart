class Category {
  final String? id;
  String name;
  int removalDays;

  Category({this.id, required this.name, required this.removalDays});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category && id != null && other.id == id);

  @override
  int get hashCode => id?.hashCode ?? identityHashCode(this);
}
