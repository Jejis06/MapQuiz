import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

class Args {
  DatabaseFactory dbFactory; 
  Database db;
  
 // 
 String DBMAPS = "DB_MAPS";
 String dbPrefix = "";
 
  
  Args({
    required this.dbFactory,
    required this.db,
  });
}


class databaseData {
  List<double> ?dlist;
  List<String> ?slist;
  String ?content;

  StoreRef<Object?, Object?> store;
  Database database;

  databaseData({required this.store,required this.database}) ;

  Future<void> getContent(dbRoute) async{
    content = null;
    var data = await store.record(dbRoute).get(database);
    content = data.toString();
  }

  //HACK: this is a hack
  Future<void> getdataList(dbRoute) async{
    slist = null;
    dlist = null;
    
    var data = await store.record(dbRoute).get(database);
    if (data == null) return;
    List<String> arr = data
      .toString()
      .replaceAll('[', '')
      .replaceAll(']', '')
      .split(',')
      .map((e){
        if (e.length > 1) return e.substring(1, e.length);
        return e;
      }
    ).toList();
    slist = arr;
  }

  void castDouble(){
    if (slist != null)
      dlist = slist?.map((e) => double.parse(e)).toList();
  }

  Future<void> quickSave(String route, String content) async {
    await store.record(route).put(database, content);
  
  }
  
}