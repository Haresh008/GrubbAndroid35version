class OrderCretedRazorpayModal {
  int? amount;
  int? amountDue;
  int? amountPaid;
  int? attempts;
  int? createdAt;
  String? currency;
  String? entity;
  String? id;

  String? offerId;
  String? receipt;
  String? status;
  List<Transfers>? transfers;

  OrderCretedRazorpayModal({
    this.amount,
    this.amountDue,
    this.amountPaid,
    this.attempts,
    this.createdAt,
    this.currency,
    this.entity,
    this.id,
    this.offerId,
    this.receipt,
    this.status,
    this.transfers,
  });

  OrderCretedRazorpayModal.fromJson(Map<String, dynamic> json) {
    amount = json['amount'];
    amountDue = json['amount_due'];
    amountPaid = json['amount_paid'];
    attempts = json['attempts'];
    createdAt = json['created_at'];
    currency = json['currency'];
    entity = json['entity'];
    id = json['id'];

    offerId = json['offer_id'];
    receipt = json['receipt'];
    status = json['status'];
    if (json['transfers'] != null) {
      transfers = <Transfers>[];
      json['transfers'].forEach((v) {
        transfers!.add(new Transfers.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['amount'] = this.amount;
    data['amount_due'] = this.amountDue;
    data['amount_paid'] = this.amountPaid;
    data['attempts'] = this.attempts;
    data['created_at'] = this.createdAt;
    data['currency'] = this.currency;
    data['entity'] = this.entity;
    data['id'] = this.id;

    data['offer_id'] = this.offerId;
    data['receipt'] = this.receipt;
    data['status'] = this.status;
    if (this.transfers != null) {
      data['transfers'] = this.transfers!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Transfers {
  int? amount;
  int? amountReversed;
  int? createdAt;
  String? currency;
  String? entity;
  Error? error;
  String? id;
  List<String>? linkedAccountNotes;
  Notes? notes;
  bool? onHold;
  var onHoldUntil;
  String? processedAt;
  String? recipient;
  RecipientDetails? recipientDetails;
  String? recipientSettlementId;
  String? source;
  String? status;

  Transfers({
    this.amount,
    this.amountReversed,
    this.createdAt,
    this.currency,
    this.entity,
    this.error,
    this.id,
    this.linkedAccountNotes,
    this.notes,
    this.onHold,
    this.onHoldUntil,
    this.processedAt,
    this.recipient,
    this.recipientDetails,
    this.recipientSettlementId,
    this.source,
    this.status,
  });

  Transfers.fromJson(Map<String, dynamic> json) {
    amount = json['amount'];
    amountReversed = json['amount_reversed'];
    createdAt = json['created_at'];
    currency = json['currency'];
    entity = json['entity'];
    error = json['error'] != null ? new Error.fromJson(json['error']) : null;
    id = json['id'];
    linkedAccountNotes = json['linked_account_notes'].cast<String>();
    notes = json['notes'] != null ? new Notes.fromJson(json['notes']) : null;
    onHold = json['on_hold'];
    onHoldUntil = json['on_hold_until'];
    processedAt = json['processed_at'];
    recipient = json['recipient'];
    recipientDetails =
        json['recipient_details'] != null
            ? new RecipientDetails.fromJson(json['recipient_details'])
            : null;
    recipientSettlementId = json['recipient_settlement_id'];
    source = json['source'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['amount'] = this.amount;
    data['amount_reversed'] = this.amountReversed;
    data['created_at'] = this.createdAt;
    data['currency'] = this.currency;
    data['entity'] = this.entity;
    if (this.error != null) {
      data['error'] = this.error!.toJson();
    }
    data['id'] = this.id;
    data['linked_account_notes'] = this.linkedAccountNotes;
    if (this.notes != null) {
      data['notes'] = this.notes!.toJson();
    }
    data['on_hold'] = this.onHold;
    data['on_hold_until'] = this.onHoldUntil;
    data['processed_at'] = this.processedAt;
    data['recipient'] = this.recipient;
    if (this.recipientDetails != null) {
      data['recipient_details'] = this.recipientDetails!.toJson();
    }
    data['recipient_settlement_id'] = this.recipientSettlementId;
    data['source'] = this.source;
    data['status'] = this.status;
    return data;
  }
}

class Error {
  String? code;
  String? description;
  String? field;
  String? id;
  String? metadata;
  String? reason;
  String? source;
  String? step;

  Error({
    this.code,
    this.description,
    this.field,
    this.id,
    this.metadata,
    this.reason,
    this.source,
    this.step,
  });

  Error.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    description = json['description'];
    field = json['field'];
    id = json['id'];
    metadata = json['metadata'];
    reason = json['reason'];
    source = json['source'];
    step = json['step'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['code'] = this.code;
    data['description'] = this.description;
    data['field'] = this.field;
    data['id'] = this.id;
    data['metadata'] = this.metadata;
    data['reason'] = this.reason;
    data['source'] = this.source;
    data['step'] = this.step;
    return data;
  }
}

class Notes {
  String? branch;
  String? name;

  Notes({this.branch, this.name});

  Notes.fromJson(Map<String, dynamic> json) {
    branch = json['branch'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['branch'] = this.branch;
    data['name'] = this.name;
    return data;
  }
}

class RecipientDetails {
  String? email;
  String? name;

  RecipientDetails({this.email, this.name});

  RecipientDetails.fromJson(Map<String, dynamic> json) {
    email = json['email'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['email'] = this.email;
    data['name'] = this.name;
    return data;
  }
}
