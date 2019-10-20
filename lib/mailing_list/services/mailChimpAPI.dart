import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../models/contacts.dart';

String generateMd5(String input) {
  return md5.convert(utf8.encode(input.toLowerCase())).toString();
}

String constructAuthToken(String apiKey) {
  return 'Basic ' + base64Encode(utf8.encode('username:$apiKey'));
}

Future<String> getInfo(String email) async {
  final RemoteConfig remoteConfig = await RemoteConfig.instance;
  await remoteConfig.fetch(expiration: const Duration(hours: 5));
  await remoteConfig.activateFetched();
  final apiKey = remoteConfig.getString('mailchimp_api_key');
  final baseUrl = remoteConfig.getString('mailchimp_base_url');
  final user = generateMd5(email);
  final url = '$baseUrl$user';

  final basicAuth = constructAuthToken(apiKey);

  final response = await http
      .get(url, headers: <String, String>{'authorization': basicAuth});

  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw Exception('Failed to retrieve data from: $url');
  }
}

Future<String> addContact(NewContact newContact) async {
  final RemoteConfig remoteConfig = await RemoteConfig.instance;
  await remoteConfig.fetch(expiration: const Duration(hours: 5));
  await remoteConfig.activateFetched();
  final apiKey = remoteConfig.getString('mailchimp_api_key');
  final baseUrl = remoteConfig.getString('mailchimp_base_url');
  final url ='$baseUrl';
  final basicAuth = constructAuthToken(apiKey);

  final body = json.encode(newContact);

  final response = await http.post(url,
      headers: <String, String>{'authorization': basicAuth, 'content-type': 'application/json'}, body: body);

  print(response);
  print(response.statusCode);
  print(response.body);

  if (response.statusCode == 200) {
    return response.body;
  }
  else if (response.statusCode == 400 && response.body.contains('Member Exists')) {
    return 'Error: You are already subsribed to the mailing list';
  }
  else {
    throw Exception('Failed to retrieve data from: $url');
  }
}