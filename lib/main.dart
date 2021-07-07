import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // A Flutter plugin for finding commonly used locations on the filesystem

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ListTask(),
    theme: ThemeData(primaryColor: Colors.white),
  ));
}

class ListTask extends StatefulWidget {
  const ListTask({Key? key}) : super(key: key);

  @override
  _ListTaskState createState() => _ListTaskState();
}

class _ListTaskState extends State<ListTask> {
  final _toDoController = TextEditingController();

  List _toDoList = [];

  Map<String, dynamic> _lastRemoved = {}; // último regustro excluído
  int _lastRemovedPos = 0; // Posição do último registro excluído

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  //Adicionar elementos a lista
  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;
      _toDoController.text = "";
      newToDo["ok"] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<Null> _reflesh() async{
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b){
        if(a["ok"] && b["ok"]) return 1;
        else if (!a["ok"] && b["ok"]) return -1;
        return 0;
      });
      _saveData();
    });

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                ElevatedButton(
                  child: Text("ADD"),
                  style: ElevatedButton.styleFrom(
                      primary: Colors.blueAccent,
                      textStyle: TextStyle(
                        color: Colors.white,
                      )),
                  onPressed: _addToDo, // Adiciona dados na lista
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(onRefresh: _reflesh,
                  child: ListView.builder(
                      padding: EdgeInsets.only(top: 10.0),
                      itemCount: _toDoList.length,
                      itemBuilder: buildItem),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      // Widget que permite arrastar o componente pro lado
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      // Identificador da lista
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
          title: Text(_toDoList[index]["title"] ?? ""),
          value: _toDoList[index]["ok"] ?? false,
          secondary: CircleAvatar(
            child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
          ),
          onChanged: (bool? value) {
            setState(() {
              //print("Selecionado: $value");
              _toDoList[index]["ok"] = value;
              _saveData(); // salva
            });
          }),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[
              index]); // Copia o Registro que está se tentando excluir
          _lastRemovedPos = index; // Copia a posição
          _toDoList.removeAt(index); // Exclui da lista

          _saveData();

          // Snack bar que exibirá a mensagem de exclusão e possibilidade de reversão
          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!!!"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPos,
                      _lastRemoved); // Caso clique em desfazer, reinsere registro na lista
                  _saveData(); // atualiza o registro
                });
              },
            ),
            duration: Duration(seconds: 2),
          );
          //Scaffold.of(context).showSnackBar(snack);
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

  // Get File
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  // Save File
  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  // Get File
  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return '';
    }
  }
}
