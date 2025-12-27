/// FAQ Item model
class FAQItem {
  final int id;
  final int? eventId;
  final String question;
  final String answer;
  final String? category;
  final int order;

  FAQItem({
    required this.id,
    this.eventId,
    required this.question,
    required this.answer,
    this.category,
    required this.order,
  });

  factory FAQItem.fromJson(Map<String, dynamic> json) {
    return FAQItem(
      id: json['id'],
      eventId: json['event_id'],
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      category: json['category'],
      order: json['order'] ?? 0,
    );
  }
}
