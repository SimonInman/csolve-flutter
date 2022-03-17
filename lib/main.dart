import 'package:csolve/components/home_page.dart';
import 'package:csolve/components/letter_grid.dart';
import 'package:csolve/models/cell.dart';
import 'package:csolve/models/cell_index.dart';
import 'package:csolve/models/clue.dart';
import 'package:csolve/models/grid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'crossword_model.dart';
//TODO need to change something in android manifest file?

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crossword',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(
          title: Text('DOUBLE CROSS'),
        ),
        body: Center(
          // child: HomePage(),
          child: DoubleCross(),
        ),
      ),
    );
  }
}

CellModel _darkSquare() => CellModel( value: Value(open: false, filled: false), isAcrossWordEnd: false, isDownWordEnd: false);

CellModel _plainLightSquare() => CellModel( value: Value(open: true, filled: false), isAcrossWordEnd: false, isDownWordEnd: false);

List<CellModel> _topRow = [
  CellModel(number: 1, value: Value(open: true, filled: false), isAcrossWordEnd: false, isDownWordEnd: false),
  _plainLightSquare(),
  CellModel(number: 2, value: Value(open: true, filled: false), isAcrossWordEnd: false, isDownWordEnd: false),
  _plainLightSquare(),
  CellModel(number: 3, value: Value(open: true, filled: false), isAcrossWordEnd: true, isDownWordEnd: false),
  ];

List<CellModel> _secondRow = [
  _plainLightSquare(),
  _darkSquare(),
  _plainLightSquare(),
  _darkSquare(),
  _plainLightSquare(),
  ];


List<CellModel> _thirdRow = [
  CellModel(number: 4, value: Value(open: true, filled: false), isAcrossWordEnd: false, isDownWordEnd: false),
  _plainLightSquare(),
  _plainLightSquare(),
  _plainLightSquare(),
  CellModel(value: Value(open: true, filled: false), isAcrossWordEnd: true, isDownWordEnd: false),
  ];

List<CellModel> _fourthRow = [
  _plainLightSquare(),
  _darkSquare(),
  _plainLightSquare(),
  _darkSquare(),
  _plainLightSquare(),
  ];

List<CellModel> _bottomRow = [
  CellModel(number: 5, value: Value(open: true, filled: false), isAcrossWordEnd: false, isDownWordEnd: true),
  _plainLightSquare(),
  CellModel( value: Value(open: true, filled: false), isAcrossWordEnd: false, isDownWordEnd: true),
  _plainLightSquare(),
  CellModel( value: Value(open: true, filled: false), isAcrossWordEnd: true, isDownWordEnd: true),
  ];

List<Clue> _downClueMaker(
  downClue1, downAnswer1,
  downClue2, downAnswer2,
  downClue3, downAnswer3,
  ) {
    List<Index> colMaker(int col) => [0,1,2,3,4].map((e) => Index(e, col)).toList();
    return [

  Clue(number: 1, 
  surface:downClue1, 
  length: 5, 
  answer:downAnswer1, 
  position: Index(0,0), 
  span: colMaker(0)),

  Clue(number: 2, 
  surface:downClue2, 
  length: 5, 
  answer:downAnswer2, 
  position: Index(0,2), 
  span: colMaker(2)),

  Clue(number: 3, 
  surface:downClue3, 
  length: 5, 
  answer:downAnswer3, 
  position: Index(0,4), 
  span: colMaker(4)),

    ];


  }


List<Clue> _acrossClueMaker(
  acrossClue1,  acrossAnswer1,
  acrossClue2,  acrossAnswer2,
  acrossClue3,  acrossAnswer3,
  ) {
    List<Index> rowMaker(int row) => [0,1,2,3,4].map((e) => Index(row, e)).toList();

    return [

  Clue(number: 1, 
  surface:acrossClue1, 
  length: 5, 
  answer:acrossAnswer1, 
  position: Index(0,0), 
  span: rowMaker(0)),

  Clue(number: 4, 
  surface:acrossClue2, 
  length: 5, 
  answer:acrossAnswer2, 
  position: Index(2,0), 
  span: rowMaker(2)),

  Clue(number: 5, 
  surface:acrossClue3, 
  length: 5, 
  answer:acrossAnswer3, 
  position: Index(4,0), 
  span: rowMaker(4)),

    ];

  }


class DoubleCross extends StatelessWidget {

Widget build(BuildContext context) {
  final clue = Clue(number: 1, surface: 'a clue', length: 5, answer: 'BEAST', position: Index(0,0), 
  span: [0,1,2,3,4].map((e) => Index(0, e)).toList());

  final rows = [
    _topRow,
    _secondRow,
    _thirdRow,
    _fourthRow,
    _bottomRow,

  ];

return Column(
  mainAxisAlignment: MainAxisAlignment.start,
  children: [
    SizedBox.square(dimension: 50.0,),
    Text('One set of clues. Two sets of answers.', ),
    SizedBox.square(dimension: 50.0,),
        StaticCrossword(
      acrossClues: _acrossClueMaker('Brazillian export', 'clue 1 across', 'Tune', 'clue 2 across', 'Classes', 'clue 3 across'), 
    downClues: _downClueMaker('First-rate', 'downAnswer1', 'Links site', 'downAnswer2', 'Sax section', 'downAnswer3'), 
    grid: Grid(width: 5, height: 5, rows: rows), 
    crosswordPath: 'crosswordPath', 
    crosswordId: 'crosswordId'),
  ],
);

  // return Column(children: [
  //   LetterGrid(width: 5, height: 5, rows: rows, streamController: null, 
  //   currentClue: clue, 
  //   updateFocus: (_) {}),
  //   clue

  // ],);

}
}