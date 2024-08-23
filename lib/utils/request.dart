import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, dynamic>> makeRequest({
  required SharedPreferences prefs,
  required String method,
  required Map data,
  required String endpoint
}) async {
  try {
    String? apiUri = prefs.getString(
        "!server:${prefs.getString("currentServer")}");
    var headers = prefs.containsKey("login_token") ? {
      'Authorization': 'Token ${prefs.getString("login_token")}'
    } : {
      'Content-Type': 'application/json'
    };
    var request = http.Request(method, Uri.parse('$apiUri$endpoint'));
    request.headers.addAll(headers);

    if (method == "POST") request.body = json.encode(data);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(
          await response.stream.bytesToString());

      return data;
    } else {
     // Get.defaultDialog(title: "Something Went Wrong", content: Text(await response.stream.bytesToString()));
      return {
        'status': false,
        'message': await response.stream.bytesToString()
      };
    }
  }catch(e){
    print(e);
   // Get.defaultDialog(title: "Something Went Wrong", content: Text(e.toString()));
    return {
      'status': false,
      'message': "Something Went Wrong"
    };
  }
}