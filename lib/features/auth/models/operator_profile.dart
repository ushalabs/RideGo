enum OperatorApprovalStatus {
  pending,
  approved,
  rejected;

  static OperatorApprovalStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'approved':
        return OperatorApprovalStatus.approved;
      case 'rejected':
        return OperatorApprovalStatus.rejected;
      case 'pending':
      default:
        return OperatorApprovalStatus.pending;
    }
  }
}

class OperatorProfile {
  final String id;
  final String userId;
  final String ownerName;
  final String businessName;
  final String contactNumber;
  final String businessLocation;
  final OperatorApprovalStatus approvalStatus;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;

  const OperatorProfile({
    required this.id,
    required this.userId,
    required this.ownerName,
    required this.businessName,
    required this.contactNumber,
    required this.businessLocation,
    this.approvalStatus = OperatorApprovalStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
  });

  factory OperatorProfile.fromJson(Map<String, dynamic> json) {
    return OperatorProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      ownerName: json['owner_name'] as String? ?? '',
      businessName: json['business_name'] as String? ?? '',
      contactNumber: json['contact_number'] as String? ?? '',
      businessLocation: json['business_location'] as String? ?? '',
      approvalStatus: OperatorApprovalStatus.fromString(
        json['approval_status'] as String?,
      ),
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'owner_name': ownerName,
      'business_name': businessName,
      'contact_number': contactNumber,
      'business_location': businessLocation,
      'approval_status': approvalStatus.name,
    };
  }

  bool get isApproved => approvalStatus == OperatorApprovalStatus.approved;
  bool get isPending => approvalStatus == OperatorApprovalStatus.pending;
  bool get isRejected => approvalStatus == OperatorApprovalStatus.rejected;
}
