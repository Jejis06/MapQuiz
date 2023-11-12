import 'package:flutter/material.dart';
import 'package:sembast/sembast.dart';
import 'dart:async';
import 'package:sembast/sembast_io.dart';
import 'package:app/content.dart';
import 'package:app/menu.dart';
import 'package:overlayment/overlayment.dart';
import 'package:app/classes.dart';

void main() async {
  
  String dbPath = "maps.db";
  DatabaseFactory dbFactory = databaseFactoryIo; 
  Database db = await dbFactory.openDatabase(dbPath);

  
  Args args = Args(dbFactory: dbFactory, db: db);
  /*
  runApp(
    QuizLayout(database: db, dbFactory: dbFactory)
  );
  */

  //pushReplacementNamed
  @override
  final key = GlobalKey<NavigatorState>();
  Overlayment.navigationKey = key;

  runApp(MaterialApp(
    navigatorKey: key, 

    initialRoute: '/menu',
    routes: {
      '/menu': (context) => Menu(args: args),
      '/quiz': (context) => QuizLayout(args: args),
    },
  ));
}
/*

  

*/