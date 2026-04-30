class PaymentModel {
  final int? id;
  final int? subscriptionId;
  final double amount;
  final String? memberName;
  final String? paymentDate;
  final String? paymentMethod;
  final String? status;
  final String? transactionRef;

  PaymentModel({
    this.id, this.subscriptionId, required this.amount,
    this.memberName, this.paymentDate, this.paymentMethod,
    this.status, this.transactionRef,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> j) => PaymentModel(
    id:             j['id'],
    subscriptionId: j['subscriptionId'],
    amount:         (j['amount'] ?? 0).toDouble(),
    memberName:     j['memberName'],
    paymentDate:    j['paymentDate'],
    paymentMethod:  j['paymentMethod'],
    status:         j['status'],
    transactionRef: j['transactionRef'],
  );
}
