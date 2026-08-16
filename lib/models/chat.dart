class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    chatId: json['chat_id'] as String,
    senderId: json['sender_id'] as String,
    text: json['text'] as String? ?? '',
    isRead: json['is_read'] as bool? ?? false,
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now(),
  );
}

class SoleChat {
  final String id;
  final String buyerId;
  final String sellerId;
  final String? productId;
  final String? productTitle;

  SoleChat({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    this.productId,
    this.productTitle,
  });

  factory SoleChat.fromJson(Map<String, dynamic> json) {
    final product = json['products'] as Map<String, dynamic>?;
    return SoleChat(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      productId: json['product_id'] as String?,
      productTitle: product?['title'] as String?,
    );
  }
}
