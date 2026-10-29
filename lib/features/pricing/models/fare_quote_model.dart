class FareQuoteModel {
  final bool isValid;
  final String? errorMessage;
  final double baseFare;
  final double segmentCharge;
  final double terminalFee;
  final int passengers;
  final bool isPrivate;
  final double totalFare;
  final String currency;

  const FareQuoteModel({
    required this.isValid,
    this.errorMessage,
    this.baseFare = 0.0,
    this.segmentCharge = 0.0,
    this.terminalFee = 0.0,
    this.passengers = 1,
    this.isPrivate = false,
    required this.totalFare,
    this.currency = 'PHP',
  });

  factory FareQuoteModel.fromJson(Map<String, dynamic> json) {
    if (json['is_valid'] == false) {
      return FareQuoteModel(
        isValid: false,
        errorMessage:
            json['error'] as String? ??
            'Invalid route combination or tariff rule',
        totalFare: 0.0,
      );
    }

    return FareQuoteModel(
      isValid: true,
      baseFare: (json['base_fare'] as num?)?.toDouble() ?? 150.0,
      segmentCharge: (json['segment_charge'] as num?)?.toDouble() ?? 0.0,
      terminalFee: (json['terminal_fee'] as num?)?.toDouble() ?? 10.0,
      passengers: (json['passengers'] as int?) ?? 1,
      isPrivate: (json['is_private'] as bool?) ?? false,
      totalFare: (json['total_fare'] as num?)?.toDouble() ?? 160.0,
      currency: json['currency'] as String? ?? 'PHP',
    );
  }

  factory FareQuoteModel.error(String message) {
    return FareQuoteModel(
      isValid: false,
      errorMessage: message,
      totalFare: 0.0,
    );
  }
}
