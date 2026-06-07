enum UserRole { superAdmin, admin, butcher, cashier }
enum AccountStatus { pending, approved, suspended }

class UserAccount {
  final String id;
  final String firstName;
  final String surname;
  final String email;
  final String? phone;
  final String? gender;
  final DateTime? dob;
  final String? photoUrl;
  final UserRole role; // Permanent primary role
  final String? branchCode; // Branch the user belongs to
  final List<UserRole> secondaryRoles; // Permanent secondary roles
  final String? shopLocation;
  final AccountStatus status;
  final DateTime createdAt;
  final bool isDeleted; // Soft delete
  final DateTime? lastSeen; // Last active timestamp
  
  // Temporary role promotions
  final UserRole? temporaryRole;
  final DateTime? tempRoleStart;
  final DateTime? tempRoleEnd;

  // Active Menu Duties/Permissions
  final Set<String> enabledPermissions;
  final Set<String> newlyAddedPermissions;

  // Salary fields
  final double? salaryAmount;
  final int? salaryDay; // Day of the month (1-31)
  final DateTime? lastSalaryDate;

  // Theme preferences
  final String? themeMode; // 'light', 'dark', 'system'
  final int? themePrimaryColor;

  UserAccount({
    required this.id,
    required this.firstName,
    required this.surname,
    required this.email,
    this.phone,
    this.gender,
    this.dob,
    this.photoUrl,
    required this.role,
    this.branchCode,
    this.secondaryRoles = const [],
    this.shopLocation,
    this.status = AccountStatus.pending, // Default to pending for all new accounts
    DateTime? createdAt,
    this.isDeleted = false,
    this.lastSeen,
    this.temporaryRole,
    this.tempRoleStart,
    this.tempRoleEnd,
    this.enabledPermissions = const {
      '/settings' // Everyone gets settings by default
    },
    this.newlyAddedPermissions = const {},
    this.salaryAmount,
    this.salaryDay,
    this.lastSalaryDate,
    this.themeMode,
    this.themePrimaryColor,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'],
      firstName: json['first_name'],
      surname: json['surname'],
      email: json['email'],
      phone: json['phone'],
      gender: json['gender'],
      dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
      photoUrl: json['photo_url'],
      role: UserRole.values.byName(json['role']),
      branchCode: json['branch_code'],
      secondaryRoles: (json['secondary_roles'] as List? ?? [])
          .map((e) => UserRole.values.byName(e))
          .toList(),
      shopLocation: json['shop_location'],
      status: AccountStatus.values.byName(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      isDeleted: json['is_deleted'] ?? false,
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
      temporaryRole: json['temporary_role'] != null 
          ? UserRole.values.byName(json['temporary_role']) 
          : null,
      tempRoleStart: json['temp_role_start'] != null 
          ? DateTime.parse(json['temp_role_start']) 
          : null,
      tempRoleEnd: json['temp_role_end'] != null 
          ? DateTime.parse(json['temp_role_end']) 
          : null,
      enabledPermissions: Set<String>.from(json['enabled_permissions'] ?? []),
      newlyAddedPermissions: Set<String>.from(json['newly_added_permissions'] ?? []),
      salaryAmount: json['salary_amount']?.toDouble(),
      salaryDay: json['salary_day'],
      lastSalaryDate: json['last_salary_date'] != null ? DateTime.parse(json['last_salary_date']) : null,
      themeMode: json['theme_mode'],
      themePrimaryColor: json['theme_primary_color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'surname': surname,
      'email': email,
      'phone': phone,
      'gender': gender,
      'dob': dob?.toIso8601String(),
      'photo_url': photoUrl,
      'role': role.name,
      'branch_code': branchCode,
      'secondary_roles': secondaryRoles.map((e) => e.name).toList(),
      'shop_location': shopLocation,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'is_deleted': isDeleted,
      'last_seen': lastSeen?.toIso8601String(),
      'temporary_role': temporaryRole?.name,
      'temp_role_start': tempRoleStart?.toIso8601String(),
      'temp_role_end': tempRoleEnd?.toIso8601String(),
      'enabled_permissions': enabledPermissions.toList(),
      'newly_added_permissions': newlyAddedPermissions.toList(),
      'salary_amount': salaryAmount,
      'salary_day': salaryDay,
      'last_salary_date': lastSalaryDate?.toIso8601String(),
      'theme_mode': themeMode,
      'theme_primary_color': themePrimaryColor,
    };
  }

  String get name => "$firstName $surname";

  bool get isOnline {
    if (lastSeen == null) return false;
    // Consider online if active within last 2 minutes
    return DateTime.now().difference(lastSeen!).inMinutes < 2;
  }

  /// Returns the current active primary role (temporary role if within valid period, else permanent role)
  UserRole get activePrimaryRole {
    if (temporaryRole != null && tempRoleStart != null && tempRoleEnd != null) {
      final now = DateTime.now();
      if (now.isAfter(tempRoleStart!) && now.isBefore(tempRoleEnd!.add(const Duration(days: 1)))) {
        return temporaryRole!;
      }
    }
    return role;
  }

  /// Alias for activePrimaryRole for compatibility
  UserRole get activeRole => activePrimaryRole;

  /// Returns all roles currently active for the user
  Set<UserRole> get activeRoles {
    final roles = {role, ...secondaryRoles};
    if (hasActivePromotion) {
      roles.add(temporaryRole!);
    }
    return roles;
  }

  bool get hasActivePromotion {
    if (temporaryRole == null || tempRoleStart == null || tempRoleEnd == null) return false;
    final now = DateTime.now();
    return now.isAfter(tempRoleStart!) && now.isBefore(tempRoleEnd!.add(const Duration(days: 1)));
  }

  UserAccount copyWith({
    String? firstName,
    String? surname,
    String? email,
    String? phone,
    String? gender,
    DateTime? dob,
    String? photoUrl,
    UserRole? role,
    String? branchCode,
    List<UserRole>? secondaryRoles,
    String? shopLocation,
    AccountStatus? status,
    bool? isDeleted,
    DateTime? lastSeen,
    UserRole? temporaryRole,
    DateTime? tempRoleStart,
    DateTime? tempRoleEnd,
    Set<String>? enabledPermissions,
    Set<String>? newlyAddedPermissions,
    double? salaryAmount,
    int? salaryDay,
    DateTime? lastSalaryDate,
    String? themeMode,
    int? themePrimaryColor,
    bool clearPromotion = false,
  }) {
    return UserAccount(
      id: id,
      firstName: firstName ?? this.firstName,
      surname: surname ?? this.surname,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      branchCode: branchCode ?? this.branchCode,
      secondaryRoles: secondaryRoles ?? this.secondaryRoles,
      shopLocation: shopLocation ?? this.shopLocation,
      status: status ?? this.status,
      createdAt: createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
      lastSeen: lastSeen ?? this.lastSeen,
      temporaryRole: clearPromotion ? null : (temporaryRole ?? this.temporaryRole),
      tempRoleStart: clearPromotion ? null : (tempRoleStart ?? this.tempRoleStart),
      tempRoleEnd: clearPromotion ? null : (tempRoleEnd ?? this.tempRoleEnd),
      enabledPermissions: enabledPermissions ?? this.enabledPermissions,
      newlyAddedPermissions: newlyAddedPermissions ?? this.newlyAddedPermissions,
      salaryAmount: salaryAmount ?? this.salaryAmount,
      salaryDay: salaryDay ?? this.salaryDay,
      lastSalaryDate: lastSalaryDate ?? this.lastSalaryDate,
      themeMode: themeMode ?? this.themeMode,
      themePrimaryColor: themePrimaryColor ?? this.themePrimaryColor,
    );
  }
}
