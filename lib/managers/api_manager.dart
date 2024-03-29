import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../model/entry.dart';
import '../model/treatment.dart';

/// From the internet about calibrations
/// sgv=(unfiltered/1000-intercept)*slope
/// mbg contains actual measured values
/// cal has intercept and slope
/// mbg and cal are on same timestamps
///

Future<List<Entry>> getEntriesFromApi({required DateTime afterTime}) async {
  final prefs = await SharedPreferences.getInstance();
  final _baseUrl = prefs.getString('baseUrl') ?? "";

  String timeString = afterTime.toUtc().toIso8601String();
  final url = Uri.parse(
      "$_baseUrl/api/v1/entries/sgv.json?find[dateString][\$gte]=$timeString&count=288");

  try {
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('status code ${response.statusCode}');
    }

    var responseData = json.decode(response.body);
    //Creating a list to store input data;
    List<Entry> entries = [];
    for (var singleEntry in responseData) {
      Entry entry = Entry.fromMap(singleEntry);

      //Adding entry to the list.
      entries.add(entry);
    }
    return entries;
  } on Exception catch (e, s) {
    print("fail ${e}");
  } on TypeError catch (e) {
    print("fail ${e}");
  }

  return [];
}

Future<void> undoLastTreatment() async {
  // Get ID of the last treatment
  final prefs = await SharedPreferences.getInstance();
  final _baseUrl = prefs.getString('baseUrl') ?? "";
  final _sha1ApiSecret = prefs.getString('apiSecretSha1') ?? "";

  final url = Uri.parse("$_baseUrl/api/v1/treatments.json?count=1");

  try {
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('status code ${response.statusCode}');
    }

    var responseData = json.decode(response.body);
    //Creating a list to store input data;
    String createdAt = responseData.first["created_at"];

    final deleteUrl = Uri.parse(
        "$_baseUrl/api/v1/treatments.json?find[created_at][\$eq]=$createdAt");

    try {
      final response = await http.delete(
        deleteUrl,
        headers: <String, String>{
          'API-SECRET': _sha1ApiSecret,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('status code ${response.statusCode}');
      }
    } on Exception catch (e, s) {
      print("fail 2 ${e}");
    } on TypeError catch (e) {
      print("fail 2 ${e}");
    }
  } on Exception catch (e, s) {
    print("fail 1 ${e}");
  } on TypeError catch (e) {
    print("fail 1 ${e}");
  }
}

Future<List<Treatment>> getTreatmentsFromApi(
    {required DateTime afterTime}) async {
  final prefs = await SharedPreferences.getInstance();
  final _baseUrl = prefs.getString('baseUrl') ?? "";

  String timeString = afterTime.toUtc().toIso8601String();
  final url = Uri.parse(
      "$_baseUrl/api/v1/treatments.json?find[created_at][\$gte]=$timeString");

  try {
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('status code ${response.statusCode}');
    }

    var responseData = json.decode(response.body);
    //Creating a list to store input data;
    List<Treatment> treatments = [];
    for (var singleEntry in responseData) {
      Treatment treatment = Treatment.fromMap(singleEntry);

      //Adding treatment to the list.
      treatments.add(treatment);
    }

    return treatments;
  } on Exception catch (e, s) {
    print("fail ${e}");
  } on TypeError catch (e) {
    print("fail ${e}");
  }

  return [];
}

void postTreatment(Treatment treatment) async {
  final prefs = await SharedPreferences.getInstance();
  final _baseUrl = prefs.getString('baseUrl') ?? "";
  final _sha1ApiSecret = prefs.getString('apiSecretSha1') ?? "";

  final url = Uri.parse("$_baseUrl/api/v1/treatments.json");

  try {
    final response = await http.post(
      url,
      headers: <String, String>{
        'API-SECRET': _sha1ApiSecret,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(treatment.toMap()),
    );

    if (response.statusCode != 200) {
      throw Exception('status code ${response.statusCode}');
    }
  } on Exception catch (e, s) {
    print("fail ${e}");
  } on TypeError catch (e) {
    print("fail ${e}");
  }
}
