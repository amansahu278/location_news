import 'package:flutter/cupertino.dart';
import 'package:locationnews/models/api_response.dart';
import 'package:locationnews/models/country_code.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class News{
  static const API = "https://newsapi.org/v2/";
  static const APIKey = "8bcd2ef07b50405abb2686b60b9414c2";

  Map<String, String> countryCode;

  News(){
    getCountryCodes();
  }

  void getCountryCodes(){
    Countries c = new Countries();
    c.fill();
    countryCode = c.decodedCountries;
  }

  Future<ApiResponse<List<Article>>> getNews(String country){
    String code = countryCode[country];
    print("Code is $code");
    return http.get(API + "top-headlines" + "?country=${code}" + "&apiKey=$APIKey").then((value){
      if(value.statusCode == 200){
        final jsonData = json.decode(value.body);
        final articles = <Article>[];
        for(var item in jsonData['articles']){
          articles.add(Article.fronJson(item));
        }
        print("Articles for $country ${articles.length}");
        if(articles.length == 0){
          return ApiResponse<List<Article>>(error: true, errorMessage: "No news available");
        }
        return ApiResponse<List<Article>>(data: articles);
      }else {
        return ApiResponse<List<Article>>(data: null, error: true, errorMessage: "${value.statusCode}");
      }
    }).catchError((_)=>ApiResponse<List<Article>>(data: null, error: true, errorMessage: "An error occurred"));
  }
}

class Article{
  String title;
  String urlToImage;
  String url;
  Article({ this.title, this.url, this.urlToImage });
  factory Article.fronJson(Map<dynamic, dynamic> data){
    return Article(
      title: data['title'],
      url: data['url'],
      urlToImage: data['urlToImage']
    );
  }
}