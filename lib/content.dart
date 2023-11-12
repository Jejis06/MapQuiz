import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:sembast/sembast.dart';
import 'dart:convert';
import 'dart:async';
import 'package:sembast/sembast_io.dart';
import 'package:overlayment/overlayment.dart';
import 'package:app/classes.dart'; 
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';


/* later data for specific map will be in format : 
  `DB_PREFIX + MAP_NAME` 
*/


class Vertex {
  Offset point;
  bool show = true;
  bool showLabel = true;
  String name = "";

  Vertex({required this.point});
}


class QuizLayout extends StatefulWidget {

  Args args;

  QuizLayout({super.key, required this.args});

  @override
  State<QuizLayout> createState() => _QuizLayoutState(args:args);
   

}

class _QuizLayoutState extends State<QuizLayout> {

  late Database database = args.db;
  var store = StoreRef.main();
  late DatabaseFactory dbFactory = args.dbFactory;
  Args args;
  late String parentRoute;

  _QuizLayoutState({required this.args});
  
  
  @override 
  void initState() {
    super.initState();
    /* HACK: from overflown stack */
    Future.delayed(Duration.zero, () {
      Map<String,String> prefixes = ModalRoute.of(context)!.settings.arguments as Map<String,String>;

      parentRoute = prefixes["parent"]!;
      MAP_POINTS_DB = prefixes["points"]!; 
      SCORE_POINTS_DB = prefixes["score"]!;
      NAMES_DB = prefixes["names"]!;
      MAP_IMG = prefixes["imgmap"]!;
      loadState();
    });
    
  }

  String MAP_POINTS_DB = "POINTS"; 
  String SCORE_POINTS_DB = "SCORE";
  String NAMES_DB = "NAMES";
  String MAP_IMG = "IMGMAP";

  String bgImage = "";
  Image localImage = Image(image: AssetImage("assets/maps/placeholder.png"));

  List<Vertex> vertices = [];
  Vertex? guess;
  String mode = "edit";
  Map<String,Color> colorMap = {
      "edit" : Colors.green,
      "remove" : Colors.red,
      "find" : Colors.yellow,
  };
  double activation_value = 9; // aprox half of stroke width
  List<int> indecies = [];

  final _MainContainerKey = GlobalKey();
  Size? _MainContainerSize;

  
  Size? FinalSize;
  Offset? ContainerPosition;

  int Points = 0;
  int CurrentToSerch = 0; 
  String findName = "";
  String config = "";

  bool failed = false;

  void _getSize() {
    setState(() {
      _MainContainerSize = _MainContainerKey.currentContext!.size;
      final RenderBox _RenderBox = _MainContainerKey.currentContext!.findRenderObject() as RenderBox;
      ContainerPosition = _RenderBox.localToGlobal(Offset.zero);
      FinalSize = Size(_MainContainerSize!.width, _MainContainerSize!.height);
    });
  }

  

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(       

        appBar: AppBar(
          title: Text("Find :  ${findName} \t Points : ${Points}"),
          centerTitle: true,
          backgroundColor: Color.fromARGB(255, 61, 60, 60),
        ),


        body: Center(
          
          child: Container(
            color: Colors.black,
            
            child: GestureDetector(
            onTapDown: (TapDownDetails details) {                      
              _onTapDown(details);
            },
            
            child: CustomPaint(
                key: _MainContainerKey,
                foregroundPainter: LinesPainter(
                  linecolor: colorMap[mode] ?? Colors.amber,
                  vertices: vertices,
                  mode: mode,
                  gess: guess,
                  indices: indecies,
                  size: FinalSize,
                  
                ),
                child: localImage,
                size: Size.infinite,
              ),
          
            ),
          ),
        ),

        
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(

              tooltip: "Import Map",
              heroTag: "import",
              backgroundColor: Colors.brown,
             
              onPressed: () async {
               await importConfig();
              },
              child: Icon(
                Icons.download,
                color: Colors.white,
                
              ),
            ),
            SizedBox(
              width: 20,
            ),
            FloatingActionButton(

              tooltip: "Remove points",
              heroTag: "remove",
              backgroundColor: Colors.red,
              onPressed: () => {                
                setState((){
                  mode = "remove";
                  vertices.forEach((element) {element.show = true;});
                  vertices.forEach((element) {element.showLabel = true;});
                }),
              },
              child: Icon(
                Icons.block,
                color: Colors.white,
                
              ),
            ),
            SizedBox(
              width: 20,
            ),
            FloatingActionButton(

              tooltip: "Add points",
              heroTag: "set",
              backgroundColor: Colors.green,
              onPressed: () => {
                
                setState((){
                  mode = "edit";
                  vertices.forEach((element) {element.show = true;});
                  vertices.forEach((element) {element.showLabel = true;});
                }),
              },
              child: Icon(
                Icons.edit,
                color: Colors.white,
                
              ),
            ),

            //clearPlane
            SizedBox(
              width: 20,
            ),
            FloatingActionButton(

              tooltip: "Start Quiz",
              heroTag: "serch",
              backgroundColor: Colors.blue,
              onPressed: () => {
               
                setState((){
                   mode = "find";
                  if (vertices.length > 0) {
                    //vertices.forEach((element) {element.show = false;});
                    vertices.forEach((element) { element.showLabel = false;});
                    
                    /* tutaj magiczny algorytm emili do losowania pytan omgomg*/
                    CurrentToSerch = Random().nextInt(vertices.length);

                    if (vertices[CurrentToSerch].name.replaceAll(' ','') != '')
                      findName = vertices[CurrentToSerch].name;
                    else findName = "${CurrentToSerch}";
                  }    
                }),
              },
              child: Icon(
                Icons.question_mark_rounded,
                color: Colors.white,
                
              ),
            ),
            SizedBox(
              width: 20,
            ),
            FloatingActionButton(
              tooltip: "Reveal all points",
              heroTag: "show",
              backgroundColor: Colors.pink,
              onPressed: () => {
                setState((){
                  vertices.forEach((element) {element.show = true;});
                  vertices.forEach((element) {element.showLabel = true;});
                }),
              },
              child: Icon(
                Icons.remove_red_eye,
                color: Colors.white,
                
              ),
            ),
            SizedBox(
              width: 20,
            ),
            FloatingActionButton(

              tooltip: "Clear all points",
              heroTag: "clear",
              backgroundColor: Colors.purple,
              onPressed: () => {
               
                setState((){
                  clearPlane();
                }),
              },
              child: Icon(
                Icons.crop_square_sharp,
                color: Colors.white,
                
              ),
            ),

            SizedBox(
              width: 20,
            ),
            FloatingActionButton(

              tooltip: "Name points",
              heroTag: "name",
              backgroundColor: Colors.orange,
              onPressed: () async {
               await popup();
              },
              child: Icon(
                Icons.draw,
                color: Colors.white,
                
              ),
            ),
            SizedBox(
              width: 20,
            ),
            FloatingActionButton(

              tooltip: "Select background image",
              heroTag: "img",
              backgroundColor: Colors.grey,
              onPressed: () async {
               await setMap();
              },
              child: Icon(
                Icons.image,
                color: Colors.white,
                
              ),
            ),
            SizedBox(
              width: 20,
            ),
            FloatingActionButton(

              tooltip: "Go back to the menu",
              heroTag: "back",
              backgroundColor: Colors.black,
              onPressed: ()  {
               Navigator.pushReplacementNamed(context, parentRoute);
              },
              child: Icon(
                Icons.back_hand,
                color: Colors.white,
                
              ),
            ),
           
          ],
        ),
      );
  }
  

  Future setMap() async {
    await Overlayment.show(
      OverPanel(
        animation: OverSlideAnimation(
          beginAlignment: Alignment.bottomCenter,
          durationMilliseconds: 1200,
          reverseDurationMilliseconds: 600,
        ),
        child: Container(

          
          padding: EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll<Color>(Color.fromARGB(255, 49, 48, 48)),
                    ),  
                  onPressed: () async {
                    const XTypeGroup typeGroup = XTypeGroup(
                      label: 'images',
                      extensions: <String>['jpg', 'png'],
                    );
                    final XFile? file =
                        await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
                   
                    if (file == null) {
                      return;
                    }
                    final img = await file.readAsBytes();
                    
                    setState((){                      
                      bgImage = base64.encode(img);
                      localImage = Image.memory(img);                      
                    });
                    databaseData(database: database, store: store).quickSave(MAP_IMG, bgImage);
                  },
                  child:Text("Click to import image"),
                ),
              ),
        ),
        
        alignment: Alignment.center, 
        backgroundSettings: BackgroundSettings(blur: 1.5),
        actions: OverlayActions(
          onClose: (p1) {
            setState(() {});
            return Future.delayed(Duration(seconds:0 ), () {});
          },
        ),
      )    
    );
  }

  Future popup() async {

    List<Widget> tlist = [Text('Change names for points'),SizedBox(height: 8)];
    for (int i = 0; i < vertices.length; i++) {
      tlist.add(
        
        TextField(
          decoration: InputDecoration(
            labelText:'Point ${i} : ${vertices[i].name}',
            hintText:vertices[i].name,
          ),
          onChanged: (value) => {
            vertices[i].name = value,
          },
        )
      );
    }
    tlist.add(
      SizedBox(height: 14)
    );
    tlist.add(
      ElevatedButton(
        onPressed: () => Overlayment.dismissLast(),
        child: const Text('Done'),
      ),
    );

    await Overlayment.show(
      OverPanel(
        animation: OverSlideAnimation(
          beginAlignment: Alignment.centerRight,
          durationMilliseconds: 1200,
          reverseDurationMilliseconds: 600,
        ),
        child: Container(
          padding: EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:tlist,
                ),
              ),
        ),
        
        alignment: Alignment.centerRight, 
        backgroundSettings: BackgroundSettings(blur: 1.5),
        actions: OverlayActions(
          onClose: (p1) {
            setState(() {});
            saveState();
            return Future.delayed(Duration(seconds:0 ), () {});
          },
        ),
      )    
    );
  
  }
  Future importConfig() async {
    setState(() {
      
    config = getConfig();
    });
    // TODO: generate current config/
    List<Widget> tlist = [Text('This is config of your map. If you want to import someone elses config paste it here'),SizedBox(height: 8)];
   
      tlist.add(
        TextField(
          
          controller:TextEditingController(text: config),
          decoration: InputDecoration(
            labelText:'Config',
            hintText:"",
            
          ),
          onChanged: (value) => {
            config = value,      
          },
        )
      );
    
    tlist.add(
      SizedBox(height: 14)
    );
    tlist.add(
      ElevatedButton(
        onPressed: () => Overlayment.dismissLast(),
        child: const Text('Done'),
      ),
    );

    await Overlayment.show(
      OverPanel(
        animation: OverSlideAnimation(
          beginAlignment: Alignment.bottomCenter,
          durationMilliseconds: 1200,
          reverseDurationMilliseconds: 600,
        ),
        child: Container(
          padding: EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:tlist,
                ),
              ),
        ),
        
        alignment: Alignment.center, 
        backgroundSettings: BackgroundSettings(blur: 1.5),
        actions: OverlayActions(
          onClose: (p1) {
            setState(() {});
            loadConfig();
            saveState();
            return Future.delayed(Duration(seconds:0 ), () {});
          },
        ),
      )    
    );
  
  }

  

  void clearDB() async {
    await store.record(MAP_POINTS_DB).delete(database);
    await store.record(NAMES_DB).delete(database);
    /* TODO: clear score */
  }

  void clearPlane(){
    clearDB();
    setState(() {
      vertices.clear();
      indecies.clear();
      guess = null;
    });    
    
  }
  
  String getConfig() {
    List<double> currentPointList = [];
    List<String> currentNameList = [];
    vertices.forEach((v) => {
      currentPointList.add(v.point.dx),
      currentPointList.add(v.point.dy),

      currentNameList.add(v.name),
    });

    String encoded = "|";
    for (int i = 0; i < currentPointList.length; i++) {
      encoded += currentPointList[i].toString();
      if (i < currentPointList.length-1) encoded += ",";
    }
    encoded += "|";
    for (int i = 0; i < currentNameList.length; i++) {
      encoded += currentNameList[i].toString();
      if (i < currentNameList.length-1) encoded += ",";
    }
    encoded += "|";
    encoded += bgImage + "|";


    return encoded;
  }
  void loadState() async{
    databaseData dbData = databaseData(database: database, store: store);
    await dbData.getdataList(MAP_POINTS_DB);
    dbData.castDouble();

    if (dbData.dlist != null) {
      for (int i = 0; i < dbData.dlist!.length; i+=2) {
        vertices.add(Vertex(point: Offset(dbData.dlist![i], dbData.dlist![i+1])));
        indecies.add(vertices.length - 1);
      }
    }    
    
    
    
    
    await dbData.getdataList(NAMES_DB);
    if (dbData.slist != null) {
      for (int i = 0; i < dbData.slist!.length; i++) 
        vertices[i].name = dbData.slist![i];
    }
    
    
    
    await dbData.getContent(MAP_IMG);
    print(MAP_IMG);
    if (dbData.content != "null") {
      bgImage = dbData.content!;
      localImage = Image.memory(base64.decode(bgImage));
    }
    
   
    setState(() {});
    /* TODO: logic for loadug score */ 
  }
  void loadConfig() {

    List<String> splitData = config.split('|');
    for (int i =0; i<splitData.length; i++) { 
      splitData[i] = splitData[i].replaceAll(' ', '');
    }
    vertices = [];
    indecies = [];
    if (splitData[1] == "") {
      
    }else {
      List<String> points = splitData[1].split(',');
      print(points);
      for (int i = 0; i < points.length - 1; i+=2) {
        //if (points[i] == "" || points[i+1] == "") break;
        vertices.add(Vertex(point: Offset(double.parse(points[i]), double.parse(points[i+1]))));
        indecies.add(vertices.length - 1);
      }
    }
    if (splitData[2] == "") {
    } else {

      List<String> names = splitData[2].split(',');
      for (int i = 0; i < names.length; i++){                
        vertices[i].name = names[i];
      }
    }


    
    if (splitData[3] == "") {
      databaseData(database: database, store: store).quickSave(MAP_IMG, "null");
      localImage = Image(image: AssetImage("assets/maps/placeholder.png"));
    } else {
      bgImage = splitData[3];
      localImage = Image.memory(base64.decode(bgImage));
      databaseData(database: database, store: store).quickSave(MAP_IMG, bgImage);
    }

                    
    setState(() {
      
    });
  }
  void saveState() async {
    
    List<double> currentPointList = [];
    List<String> currentNameList = [];
    vertices.forEach((v) => {
      currentPointList.add(v.point.dx),
      currentPointList.add(v.point.dy),

      currentNameList.add(v.name),
    });

    var databasePointList = await store.record(MAP_POINTS_DB).get(database); 

    if (databasePointList == null || databasePointList != currentPointList) {
      await store.record(MAP_POINTS_DB).put(database, currentPointList);     
    }

    var databaseNameList = await store.record(NAMES_DB).get(database);

    if (databaseNameList == null || databaseNameList != currentNameList) {
      await store.record(NAMES_DB).put(database, currentNameList);
    }

    /* TODO: logic for saving score */
 
  }

  void _onTapDown(TapDownDetails details){
    setState(() {

      _getSize();
      double width = FinalSize!.width; 
      double height = FinalSize!.height; 
      //print(FinalSize);
     
      guess = null;
      if (mode == "edit") {               
        vertices.add(Vertex(point: Offset((details.globalPosition.dx - ContainerPosition!.dx) / width, (details.globalPosition.dy - ContainerPosition!.dy ) / height)));
        indecies.add(vertices.length - 1);

      }
        
      else if (vertices.isNotEmpty){
        guess = Vertex(point: Offset((details.globalPosition.dx - ContainerPosition!.dx) / width, (details.globalPosition.dy - ContainerPosition!.dy ) / height));

        //bool found = false;
        for (int i = 0; i < indecies.length; i++) {
          double bottom_side = ((guess?.point.dx ?? 0)* width - vertices[indecies[i]].point.dx * width).abs();
          double top_side = ((guess?.point.dy ?? 0)* height - vertices[indecies[i]].point.dy * height).abs();
          
          double distance = sqrt(pow(bottom_side, 2) + pow(top_side, 2));
        
          
          if (distance <= activation_value) {
            if (mode == "find") {
              if (i == CurrentToSerch) {
                setState((){

                  if (failed) vertices[CurrentToSerch].showLabel = false;
                  if (!failed) Points++;

                  /* find point to quiz */
                  CurrentToSerch = Random().nextInt(vertices.length);

                  failed = false;
                  if (vertices[CurrentToSerch].name.replaceAll(' ','') != '')
                    findName = vertices[CurrentToSerch].name;
                  else findName = "${CurrentToSerch}";
                });
                break;
              }
              
            } 
              //print("HIT ${indecies[i]}");

            else if (mode == "remove") {
              for (int j= 0; j < indecies.length; j++)
                if (indecies[j] > indecies[i]) 
                  indecies[j]--;
              
              vertices.removeAt(indecies[i]);
              indecies.removeAt(i);

              break;
            }
          } else if (mode == "find" && (i == CurrentToSerch)) {              
              setState(() {
                Points--;
                vertices[CurrentToSerch].showLabel = true;
                failed = true;
              });
          }

        }  
      }
      saveState();
      
    });
  }
}


class LinesPainter extends CustomPainter {

  List<Vertex> vertices;
  Vertex? gess;
  Color linecolor;
  String mode;
  List<int> indices;
  Size? size;
  
  LinesPainter({required this.vertices, required this.linecolor, required this.mode, required this.gess, required this.indices, required this.size});


  @override
  void paint(Canvas canvas, Size size) {

    

    Paint pointColor = Paint()
      ..color = Colors.black
      ..strokeWidth = 18.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    Paint lineColor = Paint()
      ..color = linecolor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
 
    double width = size!.width; 
    double height = size!.height;

 

    List<Offset> Points = vertices.where((element) => element.show).map((e) => Offset(e.point.dx * width, e.point.dy * height)).toList();
    /* draw lines from guess to points */
    if (gess != null && (mode != "edit" && mode != "find")){    
     

      Offset start =  (gess?.point) ?? Offset(0,0);
      start = Offset(start.dx * width, start.dy * height);
      for (var i = 0; i < indices.length; i++){
        Offset end = Offset(vertices[i].point.dx * width, vertices[i].point.dy * height);
        //canvas.drawLine(start, end, lineColor);
        drawDashedLine(
          canvas: canvas,
          p1:end,
          p2:start,
          dashWidth: 6,
          dashSpace: 6,
          paint: lineColor,
        );
        //start = end;
      }
      
    }

    /* draw the points */
    canvas.drawPoints(PointMode.points, Points, pointColor);

    /* draw points names */
    for (int i = 0; i < Points.length; i++) {
      if (!vertices[i].showLabel) continue;

      String title = "${i}";
      if (vertices[i].name.replaceAll(' ', '') != "") title = vertices[i].name;

      TextPainter textPainter = TextPainter(
      text: TextSpan( 
        text: title,
        style: TextStyle(         
          color: Colors.amber,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
      );

      textPainter.layout(minWidth:0,maxWidth: width);
      textPainter.paint(canvas,Offset(Points[i].dx - 2 - title.length,Points[i].dy -6));
    }
    

  

    
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  void drawDashedLine(
      {required Canvas canvas,
      required Offset p1,
      required Offset p2,
      required int dashWidth,
      required int dashSpace,
      required Paint paint}) {
  
  
  Paint outlinePaint = Paint()
  ..color = Colors.black
  ..strokeWidth = paint.strokeWidth + 3
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.stroke;
  
  
  var dx = p2.dx - p1.dx;
  var dy = p2.dy - p1.dy;
  final magnitude = sqrt(dx * dx + dy * dy);
  dx = dx / magnitude;
  dy = dy / magnitude;

 
  final steps = (magnitude / (dashWidth + dashSpace)).ceil();
  var startX = p1.dx;
  var startY = p1.dy;
  
  for (int i = 0; i < steps; i++) {
    final endX = startX + dx * dashWidth;
    final endY = startY + dy * dashWidth;
    
    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), outlinePaint);
    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    startX += dx * (dashWidth + dashSpace);
    startY += dy * (dashWidth + dashSpace);

    
  }
}
}
