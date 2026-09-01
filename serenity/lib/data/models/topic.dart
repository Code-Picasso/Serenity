class TopicSection {
  final String name;
  final List<String> topics;

  const TopicSection({required this.name, required this.topics});

  factory TopicSection.fromJson(Map<String, dynamic> json) => TopicSection(
        name: json['name'] as String? ?? '',
        topics: (json['topics'] as List<dynamic>? ?? []).cast<String>(),
      );
}

class TopicCatalog {
  final List<TopicSection> sections;
  final List<String> topics;

  const TopicCatalog({required this.sections, required this.topics});

  factory TopicCatalog.fromJson(Map<String, dynamic> json) => TopicCatalog(
        sections: (json['sections'] as List<dynamic>? ?? [])
            .map((e) => TopicSection.fromJson(e as Map<String, dynamic>))
            .toList(),
        topics: (json['topics'] as List<dynamic>? ?? []).cast<String>(),
      );
}
