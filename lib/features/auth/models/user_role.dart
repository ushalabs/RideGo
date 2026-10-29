enum UserRole {
  customer,
  operator,
  admin;

  static UserRole fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'operator':
        return UserRole.operator;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.operator:
        return 'Vehicle Operator';
      case UserRole.customer:
        return 'Customer';
    }
  }
}
