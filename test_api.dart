import 'dart:convert';
import 'dart:io';

void main() async {
  var client = HttpClient();
  var request = await client.postUrl(Uri.parse('http://127.0.0.1:8000/api/v1/car-model'));
  request.headers.set('apikey', '123'); // API.header might require apikey
  request.headers.set('Content-Type', 'application/json');
  request.write(jsonEncode({"brand": "1"}));
  var response = await request.close();
  var responseBody = await response.transform(utf8.decoder).join();
  print(responseBody);
}
