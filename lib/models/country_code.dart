import 'dart:convert';

import 'package:http/http.dart' as http;

class Countries {
  Map<String, String> decodeCountry = new Map();

  get decodedCountries {
    return decodeCountry;
  }

  // getting the 2 letter ISO 3166-1 alpha-2 code for all countries
  void fill() async {
    await http.get("https://api.printful.com/countries").then((response){
      if(response.statusCode == 200){
        final jsonData = json.decode(response.body);
        for(var item in jsonData["result"]){
//          print(item);
          Country c = Country.fromJson(item);
          decodeCountry[c.name] = c.code;
        }
      }
    });
  }

}

class Country{
//  String alpha2Code;
String code;
  String name;
  Country({ this.code, this.name });

  factory Country.fromJson(Map<dynamic, dynamic> data){
    return Country(
      name: data['name'],
      code: data['code'].toLowerCase(),
    );
  }

}