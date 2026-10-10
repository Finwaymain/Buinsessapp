import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cabme_driver/model/user_model.dart';
import 'package:cabme_driver/model/transaction_history_model.dart';
import 'package:cabme_driver/page/wallet/utils/transaction_history_display.dart';

void main() {
  group('Driver UserData upiQrData serialization', () {
    test('UserData.fromJson parses upi_qr_data correctly', () {
      final json = {
        'id': '45',
        'ac_no': '708098765432',
        'nom': 'Yadav',
        'prenom': 'Suresh',
        'upi_qr_data': 'upi://pay?pa=fiinway@icici&pn=Fiinway+-+Suresh&tr=708098765432&cu=INR',
      };

      final data = UserData.fromJson(json);

      expect(data.acNo, '708098765432');
      expect(data.upiQrData, 'upi://pay?pa=fiinway@icici&pn=Fiinway+-+Suresh&tr=708098765432&cu=INR');
    });

    test('UserData.toJson preserves upi_qr_data correctly', () {
      final data = UserData(
        id: '45',
        acNo: '708098765432',
        nom: 'Yadav',
        prenom: 'Suresh',
        upiQrData: 'upi://pay?pa=fiinway@icici&pn=Fiinway+-+Suresh&tr=708098765432&cu=INR',
      );

      final json = data.toJson();

      expect(json['ac_no'], '708098765432');
      expect(json['upi_qr_data'], 'upi://pay?pa=fiinway@icici&pn=Fiinway+-+Suresh&tr=708098765432&cu=INR');
    });

    test('UserData.fromJson handles null upi_qr_data safely', () {
      final json = {
        'id': '46',
        'ac_no': '708011223344',
      };

      final data = UserData.fromJson(json);

      expect(data.acNo, '708011223344');
      expect(data.upiQrData, isNull);
    });
  });

  group('Driver TransactionHistoryDisplay UPI formatting', () {
    test('renders UPI icon, sky-blue color, and container styling for UPI transaction', () {
      final txn = TransactionHistoryData(
        id: '0000210',
        amount: '350.00',
        paymentMethod: 'UPI',
        categoryTitle: 'UPI Payment Received',
        counterpartyName: 'From Sagar',
        iconType: 'upi',
        statusLabel: 'Paid',
        deductionType: '1',
      );

      expect(TransactionHistoryDisplay.categoryTitle(txn), 'UPI Payment Received');
      expect(TransactionHistoryDisplay.counterpartyName(txn), 'From Sagar');
      expect(TransactionHistoryDisplay.iconType(txn), 'upi');
      expect(TransactionHistoryDisplay.iconFor('upi'), Icons.qr_code_2_rounded);
      expect(TransactionHistoryDisplay.iconColorFor('upi'), const Color(0xFF0284C7));
      expect(TransactionHistoryDisplay.iconBackgroundFor('upi'), const Color(0xFFE0F2FE));
      expect(TransactionHistoryDisplay.statusLabel(txn), 'Paid');
      expect(TransactionHistoryDisplay.statusBackground('Paid'), const Color(0xFFDCFCE7));
    });
  });
}
