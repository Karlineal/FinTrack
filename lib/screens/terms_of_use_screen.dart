import 'package:flutter/material.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('使用条款')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '使用条款',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '最后更新时间: 2024-07-28',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 16),
            Text('在使用 FinTrack（"本应用"）前，请仔细阅读以下条款和条件。您访问和使用本应用即表示您接受并同意遵守这些条款。'),
            SizedBox(height: 16),
            Text(
              '1. 服务内容',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('本应用提供个人财务跟踪和管理工具。所有输入的数据均存储在您的本地设备上。我们不对数据的准确性或完整性作任何保证。'),
            SizedBox(height: 16),
            Text(
              '2. 用户责任',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '您对通过本应用输入的所有数据的准确性和合法性负全部责任。您有责任保护好您的设备和数据安全。对于因设备丢失、被盗或未经授权的访问而导致的数据泄露，我们不承担任何责任。',
            ),
            SizedBox(height: 16),
            Text(
              '3. 免责声明',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('本应用按"原样"提供，不附带任何明示或暗示的保证。我们不保证应用将永远安全、不出错，也不保证它将始终正常运行。'),
            SizedBox(height: 16),
            Text(
              '4. 条款变更',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('我们保留随时修改这些条款的权利。所有修改将在本页面上公布。继续使用本应用即表示您接受修改后的条款。'),
            SizedBox(height: 16),
            Text(
              '5. 联系我们',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('如果您对这些使用条款有任何疑问，请通过 [您的联系邮箱] 与我们联系。'),
          ],
        ),
      ),
    );
  }
}
