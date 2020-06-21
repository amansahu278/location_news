import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:locationnews/models/api_response.dart';
import 'package:locationnews/models/country_code.dart';
import 'package:locationnews/models/news.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

News service = News();

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GoogleMapController _controller;
  bool showNews = false;
  bool isLoading = false;
  String address;
  List<Marker> markers = [];
  ApiResponse _newsResponse;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    markers.add(Marker(
        markerId: MarkerId("Home"),
        draggable: false,
        position: LatLng(28.61, 77.23)));
    Countries c = new Countries();
    c.fill();
    setState(() {
      showNews = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            Container(
              child: GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition:
                    CameraPosition(target: LatLng(28.61, 77.23), zoom: 12.0),
                onMapCreated: mapCreated,
                markers: markers.toSet(),
              ),
            ),
            Positioned(
              top: 30.0,
              left: 15,
              right: 15,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  child: TextField(
                    autofocus: false,
                    onTap: () {
                      setState(() {
                        showNews = false;
                      });
                    },
                    onChanged: (val) {
                      setState(() {
                        address = val;
                      });
                    },
                    decoration: InputDecoration(
                        prefixIcon: FocusScope.of(context).hasFocus
                            ? IconButton(
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: Colors.black,
                                ),
                                onPressed: () {
                                  FocusScope.of(context).unfocus();
                                },
                              )
                            : null,
                        hintText: "Search...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.only(left: 15.0, top: 15.0),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.search,
                            color: Colors.black,
                          ),
                          onPressed: searchAndNavigate,
                        )),
                  ),
                ),
              ),
            ),
            !showNews
                ? Container()
                : isLoading
                    ? Center(child: CircularProgressIndicator())
                    : newsBuilder(),
          ],
        ),
      ),
    );
  }

  searchAndNavigate() {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
    if (address == null || address.length == 0) return;
    Geolocator().placemarkFromAddress(address).then((value) {
      _controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target:
              LatLng(value[0].position.latitude, value[0].position.longitude),
          zoom: 12.0)));
      getNews(value[0].country.trim());
      markers = [];
      setState(() {
        showNews = true;
        markers.add(Marker(
          markerId: MarkerId('aa'),
          draggable: false,
          position:
              LatLng(value[0].position.latitude, value[0].position.longitude),
        ));
      });
    });
  }

  void mapCreated(controller) {
    setState(() {
      _controller = controller;
    });
  }

  newsBuilder() {
    if (_newsResponse.error) {
      return Positioned(
        bottom: 10,
        child: Container(
          child: Text(_newsResponse.errorMessage),
        ),
      );
    } 
    return Positioned(
      bottom: 10,
      left: 10,
      right: 10,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            height: MediaQuery.of(context).size.height / 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          "Top Headlines:",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 25,
                              fontWeight: FontWeight.w500),
                        ),
                        IconButton(
                          icon: Icon(Icons.cancel,),
                          onPressed: (){
                            setState(() {
                              showNews = false;
                            });
                          },
                        )
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    itemCount: _newsResponse.data.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2),
                    itemBuilder: (context, index) {
                      return customCard(_newsResponse.data[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  customCard(Article s) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: GestureDetector(
        onTap: () {
          _launchURL(s.url);
        },
        child: Container(
            height: 100,
            width: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                image: DecorationImage(
                  alignment: Alignment.topCenter,
                  image: NetworkImage(s.urlToImage ?? "https://images.pexels.com/photos/949587/pexels-photo-949587.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500")
                )),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10))
                ),
                width: 200,
                child: Text(
                  s.title,
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w500),
                ),
              ),
            )),
      ),
    );
  }

  void getNews(String country) async {
    setState(() {
      isLoading = true;
    });
    _newsResponse = await service.getNews(country);
    setState(() {
      isLoading = false;
    });
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
