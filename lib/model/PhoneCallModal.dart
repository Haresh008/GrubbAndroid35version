class PhoneCallModal {
  String? status;
  String? message;
  String? callId;
  String? batchId;

  PhoneCallModal({this.status, this.message, this.callId, this.batchId});

  PhoneCallModal.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    callId = json['call_id'];
    batchId = json['batch_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    data['call_id'] = this.callId;
    data['batch_id'] = this.batchId;
    return data;
  }
}
