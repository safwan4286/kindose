class UserData {
  final String? accessToken;
  final String? refreshToken;
  final UserModel? user;
  final int? expiresIn;
  final int? onboardingStep;

  const UserData({
    this.accessToken,
    this.refreshToken,
    this.user,
    this.expiresIn,
    this.onboardingStep,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      expiresIn: json['expires_in'] as int?,
      onboardingStep: json["onboarding_step"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'user': user?.toJson(),
      'expires_in': expiresIn,
      "onboarding_step": onboardingStep,
    };
  }

  UserData copyWith({
    String? accessToken,
    String? refreshToken,
    UserModel? user,
    int? expiresIn,
    int? onboardingStep,
  }) {
    return UserData(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      user: user ?? this.user,
      expiresIn: expiresIn ?? this.expiresIn,
      onboardingStep: onboardingStep ?? this.onboardingStep,
    );
  }
}

class UserModel {
  final String? id;
  final String? email;
  final String? phoneNumber;
  final String? authProvider;
  final String? providerUserId;
  final bool? activeSubscription;
  final String? defaultCurrency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    this.id,
    this.email,
    this.phoneNumber,
    this.authProvider,
    this.providerUserId,
    this.activeSubscription,
    this.defaultCurrency,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String?,
      email: json['email'] as String?,
      phoneNumber: json["phone_number"] as String?,
      authProvider: json['auth_provider'] as String?,
      providerUserId: json['provider_user_id'] as String?,
      activeSubscription: json['active_subscription'] as bool?,
      defaultCurrency: json['default_currency'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      "phone_number": phoneNumber,
      'auth_provider': authProvider,
      'provider_user_id': providerUserId,
      'active_subscription': activeSubscription,
      'default_currency': defaultCurrency,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? authProvider,
    String? providerUserId,
    bool? activeSubscription,
    String? defaultCurrency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      authProvider: authProvider ?? this.authProvider,
      providerUserId: providerUserId ?? this.providerUserId,
      activeSubscription: activeSubscription ?? this.activeSubscription,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
