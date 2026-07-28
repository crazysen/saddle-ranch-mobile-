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

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? json['full_name'] ?? json['fullName'] ?? '').toString();
    final email = (json['email'] ?? '').toString();
    final phone = json['phone']?.toString();
    final photo = (json['photo_url'] ?? json['avatar'] ?? json['photoUrl'])?.toString();
    return AppUser(
      email: email,
      fullName: name,
      phone: phone,
      photoUrl: photo,
      profileComplete: name.isNotEmpty,
    );
  }
}
