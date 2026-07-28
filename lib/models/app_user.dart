class AppUser {
  final String email;
  final String? photoUrl;
  final String fullName;
  final String? phone;
  final bool profileComplete;

  const AppUser({
    required this.email,
    this.photoUrl,
    this.fullName = '',
    this.phone,
    this.profileComplete = false,
  });

  AppUser copyWith({
    String? email,
    String? photoUrl,
    String? fullName,
    String? phone,
    bool? profileComplete,
  }) {
    return AppUser(
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      profileComplete: profileComplete ?? this.profileComplete,
    );
  }

  Map<String, String?> toStorage() => {
        'email': email,
        'photoUrl': photoUrl,
        'fullName': fullName,
        'phone': phone,
        'profileComplete': profileComplete ? '1' : '0',
      };

  factory AppUser.fromStorage(Map<String, String?> data) {
    return AppUser(
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      fullName: data['fullName'] ?? '',
      phone: data['phone'],
      profileComplete: data['profileComplete'] == '1',
    );
  }
}
