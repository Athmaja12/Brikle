/// Matches GET /api/materials/{materialId}/reviews/ response exactly
/// Review & Rating Model like Flipkart
class ReviewModel {
  final int id;
  final String userName;
  final int rating;
  final String comment;
  final String createdAt;

  ReviewModel({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: _parseInt(json['id']),
      userName: json['user_name']?.toString() ?? '',
      rating: _parseInt(json['rating']),
      comment: json['comment']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_name': userName,
    'rating': rating,
    'comment': comment,
    'created_at': createdAt,
  };

  String get starDisplay => '⭐' * rating + '☆' * (5 - rating);

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}

/// Request model for posting a review
class ReviewRequestModel {
  final int rating;
  final String comment;

  ReviewRequestModel({
    required this.rating,
    required this.comment,
  });

  Map<String, dynamic> toJson() => {
    'rating': rating,
    'comment': comment,
  };
}

/// Response model for review submission
class ReviewResponseModel {
  final bool success;
  final String message;
  final ReviewModel? review;

  ReviewResponseModel({
    required this.success,
    required this.message,
    this.review,
  });

  factory ReviewResponseModel.fromJson(dynamic json) {
    // Check if it's an error response (array with message)
    if (json is List && json.isNotEmpty) {
      return ReviewResponseModel(
        success: false,
        message: json.first.toString(),
        review: null,
      );
    }

    // Success response (single review object)
    if (json is Map<String, dynamic>) {
      // Check if it has an 'id' field (successful review)
      if (json.containsKey('id')) {
        return ReviewResponseModel(
          success: true,
          message: 'Review submitted successfully!',
          review: ReviewModel.fromJson(json),
        );
      }

      // Check if it has an error message
      if (json.containsKey('error')) {
        return ReviewResponseModel(
          success: false,
          message: json['error'].toString(),
          review: null,
        );
      }

      if (json.containsKey('detail')) {
        return ReviewResponseModel(
          success: false,
          message: json['detail'].toString(),
          review: null,
        );
      }
    }

    // Unknown response
    return ReviewResponseModel(
      success: false,
      message: 'Unexpected response from server',
      review: null,
    );
  }
}