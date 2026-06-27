import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../models/pilots_model.dart';
import '_pilot_ui.dart';

class BankDocumentsSection extends StatelessWidget {
  const BankDocumentsSection({required this.documents, super.key});

  final PilotBankDocumentsData documents;

  @override
  Widget build(BuildContext context) {
    return PilotSectionCard(
      title: 'Bank & Documents',
      subtitle: 'Read only',
      child: Column(
        children: [
          PilotInfoRow(label: 'Bank Name', value: documents.bankName),
          PilotInfoRow(label: 'Account Number', value: documents.accountNumber),
          PilotInfoRow(label: 'IFSC', value: documents.ifsc),
          PilotInfoRow(label: 'UPI ID', value: documents.upiId),
          PilotInfoRow(label: 'PAN Number', value: documents.panNumber),
          PilotImageTile(label: 'PAN Image', fileName: documents.panImage),
          SizedBox(height: AppSpacing.md),
          PilotInfoRow(label: 'Aadhaar Number', value: documents.aadhaarNumber),
          PilotImageTile(
            label: 'Aadhaar Image',
            fileName: documents.aadhaarImage,
          ),
        ],
      ),
    );
  }
}
