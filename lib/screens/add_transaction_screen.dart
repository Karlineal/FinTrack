import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_form.dart';

class AddTransactionScreen extends StatelessWidget {
  final Transaction? transactionToEdit;

  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final isEditing = transactionToEdit != null;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          isEditing ? '修改账单' : '记一笔',
          style: TextStyle(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
      ),
      body: SafeArea(
        child: TransactionForm(
          initialTransaction: transactionToEdit,
          onSubmit: (transaction) async {
            if (isEditing) {
              await provider.updateTransaction(transaction);
            } else {
              await provider.addTransaction(transaction);
            }
            if (context.mounted) {
              Navigator.of(context).pop(true);
            }
          },
          onSubmitAndContinue: (transaction) async {
            if (!isEditing) {
              await provider.addTransaction(transaction);
              // Do not pop, allow form to reset for the next entry
            }
          },
        ),
      ),
    );
  }
}
