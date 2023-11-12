import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sembast/sembast.dart';
import 'dart:async';
import 'package:sembast/sembast_io.dart';
import 'package:app/classes.dart';

/* TODO : 

  - Image preview of map
  - Store maps in database as base64 strings
  - display points in preview
  - kill urself
  - store configs for maps in global database

*/
/* Global prefixes in databse */
String MAP_POINTS_DB = "POINTS"; 
String SCORE_POINTS_DB = "SCORE";
String NAMES_DB = "NAMES";
String MAP_IMG = "IMGMAP";


/* menu */
class Menu extends StatefulWidget {
  Args args;
  Menu({super.key, required this.args});

  @override
  State<Menu> createState() => _MenuState(args: args);
}

class _MenuState extends State<Menu> {
  Args args;
  int mapNumber = 0;
  List<Widget> cards = [];
  _MenuState({required this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Menu"),
        backgroundColor: Color.fromARGB(255, 61, 60, 60),
      ),
      /*floatingActionButton: SizedBox(
        width: 400,
        height: 50,
        child: FloatingActionButton.extended(
            
            label: Text("Add new map"),
            heroTag: "Addmap",
            
            backgroundColor: const Color.fromARGB(255, 49, 49, 49),
            onPressed: () => {    
                cards.add(Card(route: '/quiz', sufix: "Map${mapNumber}", args: args)),
                mapNumber++,
               
                setState((){})
              },
            icon: Icon(
              Icons.add,            
              color: Colors.white,    
            ),
          ),
      ),**/
  
      body: Container(
        
        color: Colors.grey,
        //padding: EdgeInsets.symmetric(vertical: 100),
        child: GridView.count(
          crossAxisCount: 3,
          children: [
            Card(route: '/quiz', sufix: "Map ${1}", args: args),
            Card(route: '/quiz', sufix: "Map ${2}", args: args),
            Card(route: '/quiz', sufix: "Map ${3}", args: args),
            Card(route: '/quiz', sufix: "Map ${4}", args: args),
            Padding(
              padding: const EdgeInsets.all(100.0),
              child: Text("DODAWANIE I USUWANIE MAP JEST JESZCZE NIE ZROBIONE BO DLUGO BY TRZEBA SIE BYLO MECZYC Z BAZA DANYCH WIEC NA RAZIE MOZNA EDYTOWAC 4 MAPY",
              style: TextStyle(color: const Color.fromARGB(255, 44, 44, 44)),),
            )
          ]
          //Card(route: '/quiz', sufix: "1", args: args),
        ),

      ),
      
    );
  }
}

/* card */

class Card extends StatefulWidget {
  String route;
  Args args;
  String sufix;
  Card({required this.route, required this.sufix ,required this.args});

  @override
  State<Card> createState() => _CardState(route:route, sufix: sufix, args: args);
}

class _CardState extends State<Card> {

  Args args;
  String route;
  String sufix;

  late Database database = args.db;
  var store = StoreRef.main();
  late databaseData db = databaseData(database: database, store:store);
  _CardState({required this.route, required this.sufix ,required this.args});

  Image img = Image(image: AssetImage("assets/maps/placeholder.png"));


  void loadImages() async {    
    await db.getContent(MAP_IMG + sufix);
    print(MAP_IMG + sufix);
    if (db.content != "null") {
      img = Image.memory(base64Decode(db.content!));
    }
    setState(() {});
  }
  @override
  void initState() {
    super.initState();
    loadImages();
  }

  @override
  Widget build(BuildContext context) {    
    return Container(
      
      margin: EdgeInsets.symmetric(vertical:20, horizontal:  40),
      padding : EdgeInsets.symmetric(vertical:20, horizontal:  40),
      color: const Color.fromARGB(255, 71, 71, 71),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: (){},
                icon: Icon(Icons.close),
                color: Colors.red,
              )
            ],
          ),
          Container(
            child: img,
            height: MediaQuery.of(context).size.width / 5.2,
            
          ),
          SizedBox(
              height: 20,
          ),
          Text(
            "${sufix}",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
              height: 20,
          ),
          ElevatedButton(
            onPressed: (){
              Map<String,String> namedArguments = {
                "points":MAP_POINTS_DB + sufix,
                "score":SCORE_POINTS_DB + sufix,
                "names":NAMES_DB + sufix,
                "imgmap":MAP_IMG + sufix,
                "parent":'/menu',
              };
              Navigator.pushReplacementNamed(context, route, arguments: namedArguments);
            }, 
            child: Icon(
              Icons.edit,
              size: 15,
            ),          
            style: ButtonStyle(
              backgroundColor: MaterialStatePropertyAll<Color>(const Color.fromARGB(255, 31, 30, 30)),
            ),  
          ),

        ],
      ),
    );
  }
}