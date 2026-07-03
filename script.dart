import 'dart:io';

void main() async {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in files) {
    String content = await file.readAsString();
    if (content.contains('Something want wrong')) {
      content = content.replaceAll(
        "ShowToastDialog.showToast('Something want wrong. Please try again later');",
        "ShowToastDialog.showToast('Error \${response.statusCode}: \${response.reasonPhrase}');",
      );
      content = content.replaceAll(
        "ShowToastDialog.showToast('Something want wrong. Please try again later'.tr);",
        "ShowToastDialog.showToast('Error \${response.statusCode}: \${response.reasonPhrase}'.tr);",
      );
      await file.writeAsString(content);
      print('Updated ${file.path}');
    }
  }
}
