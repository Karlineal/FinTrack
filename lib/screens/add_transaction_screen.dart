import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_form.dart';

class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TransactionForm(
      onSubmit: (transaction) {
        final provider = Provider.of<TransactionProvider>(
          context,
          listen: false,
        );
        provider.addTransaction(transaction);
        Navigator.of(context).pop();
      },
    );
  }
}
