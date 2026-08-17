class AppUser {
  final int? id;
  final String email;
  final String? photoUrl;
  final String fullName;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? address;
  final String role; // 'admin' | 'employee' | 'user'
  final String branch; // 'all' | 'Bulihan' | 'Dasma'
  final bool profileComplete;

  const AppUser({
    this.id,
    required this.email,
    this.photoUrl,
    this.fullName = '',
    this.firstName,
    this.lastName,
    this.phone,
    this.address,
    this.role = 'user',
    this.branch = 'all',
    this.profileComplete = false,
  });

  AppUser copyWith({
    int? id,
    String? email,
    String? photoUrl,
    String? fullName,
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
    String? role,
    String? branch,
    bool? profileComplete,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      fullName: fullName ?? this.fullName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      branch: branch ?? this.branch,
      profileComplete: profileComplete ?? this.profileComplete,
    );
  }

  Map<String, String?> toStorage() => {
        'id': id?.toString(),
        'email': email,
        'photoUrl': photoUrl,
        'fullName': fullName,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'address': address,
        'role': role,
        'branch': branch,
        'profileComplete': profileComplete ? '1' : '0',
      };

  factory AppUser.fromStorage(Map<String, String?> data) {
    return AppUser(
      id: int.tryParse(data['id'] ?? ''),
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      fullName: data['fullName'] ?? '',
      firstName: data['firstName'],
      lastName: data['lastName'],
      phone: data['phone'],
      address: data['address'],
      role: data['role'] ?? 'user',
      branch: data['branch'] ?? 'all',
      profileComplete: data['profileComplete'] == '1',
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? json['full_name'] ?? json['fullName'] ?? '').toString();
    final email = (json['email'] ?? '').toString();
    final phone = (json['phone_number'] ?? json['phone'] ?? json['phoneNumber'])?.toString();
    final photo = (json['photo_url'] ?? json['avatar'] ?? json['photoUrl'])?.toString();
    final address = json['address']?.toString();
    final role = (json['role'] ?? 'user').toString();
    final branch = (json['branch'] ?? 'all').toString();
    final id = json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '');

    return AppUser(
      id: id,
      email: email,
      fullName: name,
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      phone: phone,
      photoUrl: photo,
      address: address,
      role: role,
      branch: branch,
      profileComplete: name.isNotEmpty,
    );
  }
}
