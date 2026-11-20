typedef Json = Map<String, Object?>;

final class ApiError {
  const ApiError(this.code, [this.details = const {}]);

  factory ApiError.fromJson(Json json) => ApiError(json['code'] as String, (json['details'] as Json?) ?? const {});

  final String code;
  final Json details;

  Json toJson() => {'code': code, 'details': details};
}

final class LoginRequest {
  const LoginRequest({required this.email, required this.password, required this.client});

  factory LoginRequest.fromJson(Json json) => LoginRequest(
    email: json['email'] as String,
    password: json['password'] as String,
    client: json['client'] as String,
  );

  final String email;
  final String password;
  final String client;

  Json toJson() => {'email': email, 'password': password, 'client': client};
}

final class SessionResponse {
  const SessionResponse({
    required this.id,
    required this.email,
    required this.role,
    required this.expiresAt,
    this.token,
  });

  factory SessionResponse.fromJson(Json json) {
    final user = json['user'] as Json;
    return SessionResponse(
      id: user['id'] as String,
      email: user['email'] as String,
      role: user['role'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      token: json['token'] as String?,
    );
  }

  final String id;
  final String email;
  final String role;
  final DateTime expiresAt;
  final String? token;

  Json toJson() => {
    'user': {'id': id, 'email': email, 'role': role},
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'token': ?token,
  };
}

final class ReviewInput {
  const ReviewInput({required this.title, required this.body, required this.rating, this.deviceId});

  factory ReviewInput.fromJson(Json json) => ReviewInput(
    title: json['title'] as String,
    body: json['body'] as String,
    rating: json['rating'] as int,
    deviceId: json['deviceId'] as String?,
  );

  final String title;
  final String body;
  final int rating;
  final String? deviceId;

  Json toJson() => {'title': title, 'body': body, 'rating': rating, 'deviceId': ?deviceId};
}

final class ModerationRequest {
  const ModerationRequest(this.action, {this.reason});

  factory ModerationRequest.fromJson(Json json) =>
      ModerationRequest(json['action'] as String, reason: json['reason'] as String?);

  final String action;
  final String? reason;

  Json toJson() => {'action': action, 'reason': ?reason};
}

final class ReviewDto {
  const ReviewDto({
    required this.id,
    required this.deviceId,
    required this.authorId,
    required this.title,
    required this.body,
    required this.rating,
    required this.status,
    required this.submittedAt,
    required this.statusAt,
    this.reason,
    this.uniqueReportCount,
  });

  factory ReviewDto.fromJson(Json json) => ReviewDto(
    id: json['id'] as String,
    deviceId: json['deviceId'] as String,
    authorId: json['authorId'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    rating: json['rating'] as int,
    status: json['status'] as String,
    submittedAt: DateTime.parse(json['submittedAt'] as String),
    statusAt: DateTime.parse(json['statusAt'] as String),
    reason: json['reason'] as String?,
    uniqueReportCount: json['uniqueReportCount'] as int?,
  );

  final String id;
  final String deviceId;
  final String authorId;
  final String title;
  final String body;
  final int rating;
  final String status;
  final DateTime submittedAt;
  final DateTime statusAt;
  final String? reason;
  final int? uniqueReportCount;

  Json toJson() => {
    'id': id,
    'deviceId': deviceId,
    'authorId': authorId,
    'title': title,
    'body': body,
    'rating': rating,
    'status': status,
    'submittedAt': submittedAt.toUtc().toIso8601String(),
    'statusAt': statusAt.toUtc().toIso8601String(),
    'reason': ?reason,
    'uniqueReportCount': ?uniqueReportCount,
  };
}

final class ReviewPage {
  const ReviewPage(this.reviews, this.nextOffset);

  factory ReviewPage.fromJson(Json json) => ReviewPage(
    (json['reviews'] as List<Object?>).map((item) => ReviewDto.fromJson(item as Json)).toList(),
    json['nextOffset'] as int?,
  );

  final List<ReviewDto> reviews;
  final int? nextOffset;

  Json toJson() => {'reviews': reviews.map((item) => item.toJson()).toList(), 'nextOffset': nextOffset};
}
