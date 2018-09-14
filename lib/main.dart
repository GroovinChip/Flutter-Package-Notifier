import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_package_notifier/globals.dart' as globals;
import 'package:url_launcher/url_launcher.dart';
import 'package:groovin_material_icons/groovin_material_icons.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Package Notifer',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: SignIn(),
      debugShowCheckedModeBanner: false,
      routes: <String, WidgetBuilder>{
        "/HomeScreen": (BuildContext context) => FlutterPackageNotifier(),
      },
    );
  }
}

class SignIn extends StatefulWidget {
  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {

  bool _loggedIn = false;

  verifyUser() async {
    final user = await FirebaseAuth.instance.currentUser();
    if (user != null) {
      globals.loggedInUser = user;
      try {
        setState(() {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => FlutterPackageNotifier()));
        });
      } catch (e) {
        print(e);
      }
      if (mounted) {
        setState(() {
          _loggedIn = true;
        });
      }
    }
  }

  @override
  void initState() {
    verifyUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            //mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 100.0),
                child: Text(
                  "Flutter Package Notifier",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30.0,
                  ),
                ),
              ),
              Text(
                "Get updates about your favorite packages"
              ),
              Padding(
                padding: const EdgeInsets.only(top: 75.0, bottom: 75.0),
                child: Icon(GroovinMaterialIcons.dart_logo, size: 50.0, color: Colors.blue[700],),
              ),
              RaisedButton(
                child: Text("Get Started", style: TextStyle(color: Colors.white),),
                color: Colors.blue[600],
                onPressed: () async{
                  FirebaseAuth auth = FirebaseAuth.instance;
                  FirebaseUser user = await auth.signInAnonymously();
                  globals.loggedInUser = user;
                  CollectionReference users = Firestore.instance.collection("Users");
                  users.document(user.uid).setData({});

                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => FlutterPackageNotifier()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class FlutterPackageNotifier extends StatefulWidget {
  @override
  _FlutterPackageNotifierState createState() => _FlutterPackageNotifierState();
}

class _FlutterPackageNotifierState extends State<FlutterPackageNotifier> with SingleTickerProviderStateMixin {

  List<Tab> myTabs = [
    Tab(
      child: Text("Favorites"),
    ),
    Tab(
      child: Text("Search"),
    ),
  ];

  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: myTabs.length);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Flutter Package Notifier"),
        bottom: TabBar(
          tabs: myTabs,
          controller: _tabController,
        ),
        centerTitle: true,
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          StreamBuilder<QuerySnapshot>(
            stream: Firestore.instance.collection("Users").document(globals.loggedInUser.uid).collection("Packages").snapshots(),
            builder: (context, snapshot){
              List<Widget> favoritePackages = [];
              if(snapshot.hasData){
                for(int i = 0; i< snapshot.data.documents.length; i++) {
                  DocumentSnapshot ref = snapshot.data.documents[i];
                  /*var package = ListTile(
                    title: Text("${ref['PackageName']} ${ref['CurrentVersion']}", style: TextStyle(fontWeight: FontWeight.bold),),
                    subtitle: Text("By ${ref['Author']}"),
                  );*/
                  final reg = new RegExp(r"<(.*?)>");
                  final match = reg.firstMatch("${ref['Author']}");
                  final authorEmail = match.group(1);
                  var package = Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              "${ref['PackageName']} ${ref['CurrentVersion']}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20.0
                              ),
                            ),
                            Text("By ${ref['Author']}"),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                IconButton(
                                  icon: Icon(Icons.delete_outline),
                                  onPressed: (){
                                    showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text("Unfollow "+"${ref['PackageName']}"+"?"),
                                          content: Text("Are you sure you want to unfollow this package?"),
                                          actions: <Widget>[
                                            FlatButton(
                                              child: Text("No"),
                                              onPressed: (){
                                                Navigator.pop(context);
                                              },
                                            ),
                                            FlatButton(
                                              child: Text("Yes"),
                                              onPressed: (){
                                                Firestore.instance.collection("Users").document(globals.loggedInUser.uid).collection("Packages").document(ref.documentID).delete();
                                                Navigator.pop(context);
                                              },
                                            ),
                                          ],
                                        )
                                    );
                                  },
                                  tooltip: "Remove",
                                ),
                                IconButton(
                                  icon: Icon(GroovinMaterialIcons.dart_logo, color: Colors.blue),
                                  onPressed: (){
                                    launch("https:pub.dartlang.org/packages/"+"${ref['PackageName']}");
                                  },
                                  tooltip: "View on Pub",
                                ),
                                IconButton(
                                  icon: Icon(GroovinMaterialIcons.github_circle),
                                  onPressed: (){
                                    launch("${ref['Homepage']}");
                                  },
                                  tooltip: "View on GitHub",
                                ),
                                IconButton(
                                  icon: Icon(GroovinMaterialIcons.email_variant, color: Colors.red),
                                  onPressed: (){
                                    launch("mailto:"+authorEmail);
                                  },
                                  tooltip: "Email Developer",
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                  favoritePackages.add(package);
                }
                return ListView.builder(
                  itemCount: favoritePackages.length,
                  itemBuilder: (context, index) {
                    return favoritePackages[index];
                  },
                );
              } else {
                return Center(
                  child: Text("No favorite packages"),
                );
              }
            },
          ),
          Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 16.0, left: 14.0),
                child: Row(
                  children: <Widget>[
                    Text(
                      "Tips:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24.0,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20.0, top: 8.0),
                child: Row(
                  children: <Widget>[
                    Text("- Make sure to type in the package name exactly"),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Row(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text("- Select a package to favorite it"),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                child: TypeAheadField(
                  textFieldConfiguration: TextFieldConfiguration(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                      labelText: "Search Pub",
                    )
                  ),
                  suggestionsCallback: (value) async{
                    var list = <String>[];
                    final response = await http.get('https://pub.dartlang.org/api/search?q='+value);
                    var responseJson = json.decode(response.body.toString());
                    for(int i = 0; i < responseJson.length; i++){
                      list.add(responseJson["packages"][i]["package"]);
                    }
                    return list;
                  },
                  itemBuilder: (context, suggestion){
                    return ListTile(
                      title: Text(suggestion),
                    );
                  },
                  onSuggestionSelected: (value) async{
                    //print(value);
                    //FocusScope.of(context).requestFocus(new FocusNode());
                    final response = await http.get('https://pub.dartlang.org/api/packages/'+value);
                    var responseJson = json.decode(response.body.toString());
                    String packageName = responseJson['name'];
                    String currentVersion = responseJson['latest']['pubspec']['version'];
                    String author = responseJson['latest']['pubspec']['author'];
                    String homepage = responseJson['latest']['pubspec']['homepage'];
                    String pubUrl = "https://pub.dartlang.org/packages/"+value;

                    CollectionReference packageDB = Firestore.instance.collection("Users").document(globals.loggedInUser.uid).collection("Packages");
                    packageDB.document(packageName).setData({
                      "PackageName":packageName,
                      "CurrentVersion":currentVersion,
                      "Author":author,
                      "Homepage":homepage,
                      "PubURL":pubUrl,
                    });

                    SnackBar snackbar = SnackBar(
                      content: Text(packageName + " has been added to your favorites"),
                      duration: Duration(seconds: 2),
                    );

                    Scaffold.of(context).showSnackBar(snackbar);
                  },
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
