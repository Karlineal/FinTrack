import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_list_item.dart';
import 'transaction_detail_screen.dart';

class AllTransactionsScreen extends StatelessWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('全部交易')),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.convertedTransactions.isEmpty) {
            return const Center(child: Text('没有交易记录'));
          }

          return ListView.builder(
            itemCount: provider.convertedTransactions.length,
            itemBuilder: (context, index) {
              final transaction = provider.convertedTransactions[index];
              return TransactionListItem(
                transaction: transaction,
                dateFormat: 'yyyy-MM-dd',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              TransactionDetailScreen(transaction: transaction),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
