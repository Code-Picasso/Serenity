/// Generic paginated list wrapper returned by list endpoints.
class Paginated<T> {
  final List<T> items;
  final int page;
  final int total;

  const Paginated({required this.items, required this.page, required this.total});

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = json['items'] as List<dynamic>? ?? [];
    return Paginated(
      items: raw.map((e) => fromJson(e as Map<String, dynamic>)).toList(),
      page: json['page'] as int? ?? 1,
      total: json['total'] as int? ?? raw.length,
    );
  }
}
