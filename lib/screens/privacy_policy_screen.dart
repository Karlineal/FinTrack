import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('隐私政策')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '隐私政策',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '最后更新时间: 2024-07-28',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 16),
            Text(
              '欢迎使用 FinTrack！我们致力于保护您的个人信息和隐私安全。本隐私政策旨在说明我们如何收集、使用、共享和保护您的信息。',
            ),
            SizedBox(height: 16),
            Text(
              '1. 我们收集的信息',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '我们可能会收集您在使用我们的服务时提供的信息，例如您的交易记录、预算设置和偏好。所有数据均存储在您的设备本地，我们不会在服务器上存储您的个人财务数据。',
            ),
            SizedBox(height: 16),
            Text(
              '2. 信息的存储',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '您的所有个人数据都安全地存储在您的设备上。我们无法访问您的个人交易数据。如果您选择使用自动备份功能，您的数据将被加密并存储在您的个人云服务中，我们同样无法访问。',
            ),
            SizedBox(height: 16),
            Text(
              '3. 汇率信息',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '为了提供准确的货币转换，应用会匿名请求第三方服务（如 aweb-api.com）以获取最新的汇率数据。此过程不涉及任何个人信息的传输。',
            ),
            SizedBox(height: 16),
            Text(
              '4. 政策变更',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('我们可能会不时更新本隐私政策。任何变更都将在此页面上公布，我们建议您定期查看。'),
            SizedBox(height: 16),
            Text(
              '5. 联系我们',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('如果您对本隐私政策有任何疑问，请通过 [您的联系邮箱] 与我们联系。'),
          ],
        ),
      ),
    );
  }
}
