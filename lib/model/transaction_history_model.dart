class TransactionHistoryData {
  String? id;
  String? amount;
  String? deductionType;
  String? rideId;
  String? paymentMethod;
  String? paymentStatus;
  String? creer;
  String? description;
  String? txnId;
  String? type;
  String? date;
  String? categoryTitle;
  String? counterpartyName;
  String? formattedDate;
  String? statusLabel;
  String? iconType;

  TransactionHistoryData({
    this.id,
    this.amount,
    this.deductionType,
    this.rideId,
    this.paymentMethod,
    this.paymentStatus,
    this.creer,
    this.description,
    this.txnId,
    this.type,
    this.date,
    this.categoryTitle,
    this.counterpartyName,
    this.formattedDate,
    this.statusLabel,
    this.iconType,
  });

  TransactionHistoryData.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    amount = json['amount']?.toString();
    deductionType = json['deduction_type']?.toString();
    rideId = json['ride_id']?.toString();
    paymentMethod = json['payment_method']?.toString();
    paymentStatus = json['payment_status']?.toString();
    creer = json['creer']?.toString();
    description = json['description']?.toString();
    txnId = json['txn_id']?.toString();
    type = json['type']?.toString();
    date = json['date']?.toString();
    categoryTitle = json['category_title']?.toString();
    counterpartyName = json['counterparty_name']?.toString();
    formattedDate = json['formatted_date']?.toString();
    statusLabel = json['status_label']?.toString();
    iconType = json['icon_type']?.toString();
  }
}
