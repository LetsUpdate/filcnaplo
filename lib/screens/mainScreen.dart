import 'dart:async';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:filcnaplo/Cards/TomorrowLessonCard.dart';
import 'package:filcnaplo/Dialog/CardChooserDialog.dart';
//import 'package:filcnaplo/Dialog/TOSDialog.dart';
import 'package:filcnaplo/generated/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Cards/SummaryCards.dart';
import '../Cards/AbsenceCard.dart';
import '../Cards/ChangedLessonCard.dart';
import '../Cards/EvaluationCard.dart';
import '../Cards/LessonCard.dart';
import '../Cards/NoteCard.dart';
import '../Datas/Account.dart';
import '../Datas/Lesson.dart';
import '../Datas/Note.dart';
import '../Datas/Student.dart';
import '../GlobalDrawer.dart';
import '../Helpers/BackgroundHelper.dart';
import '../Helpers/SettingsHelper.dart';
import '../Helpers/TimetableHelper.dart';
import '../globals.dart' as globals;

void main() {
  runApp(new MaterialApp(
    home: new MainScreen(),
  ));
}

class MainScreen extends StatefulWidget {
  @override
  MainScreenState createState() => new MainScreenState();
}

_launchDownloadWebsite() async {
  const url = 'https://www.filcnaplo.hu/download/';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

class MainScreenState extends State<MainScreen> {
  List mainScreenCards;
  List<Evaluation> evaluations = new List();
  Map<String, List<Absence>> absents = new Map();
  List<Note> notes = new List();
  List<Lesson> lessons = new List();
  // for testing
  // DateTime get now => DateTime.parse("2019-06-03 08:00:00Z");
  DateTime get now => DateTime.now();
  DateTime startDate;
  //DateTime startDate = DateTime.now();
  bool hasOfflineLoaded = false;
  bool hasLoaded = true;

  void _initSettings() async {
    DynamicTheme.of(context).setBrightness(await SettingsHelper().getDarkTheme()
        ? Brightness.dark
        : Brightness.light);
    BackgroundHelper().configure();
    // refresh color settings
    globals.color1 = await SettingsHelper().getEvalColor(0);
    globals.color2 = await SettingsHelper().getEvalColor(1);
    globals.color3 = await SettingsHelper().getEvalColor(2);
    globals.color4 = await SettingsHelper().getEvalColor(3);
    globals.color5 = await SettingsHelper().getEvalColor(4);
    globals.colorF1 =
        globals.color1.computeLuminance() >= 0.5 ? Colors.black : Colors.white;
    globals.colorF2 =
        globals.color2.computeLuminance() >= 0.5 ? Colors.black : Colors.white;
    globals.colorF3 =
        globals.color3.computeLuminance() >= 0.5 ? Colors.black : Colors.white;
    globals.colorF4 =
        globals.color4.computeLuminance() >= 0.5 ? Colors.black : Colors.white;
    globals.colorF5 =
        globals.color5.computeLuminance() >= 0.5 ? Colors.black : Colors.white;

    if (globals.users.length == 1) {
      globals.isSingle = true;
      SettingsHelper().setSingleUser(true);
    }
  }

  Future showUpdateDialog() async {
    //print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
    return showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new SimpleDialog(
              children: <Widget>[
                new Text("Töltsd le most a legújabb verziót:"),
                new Text(
                  globals.latestVersion + "\n",
                  style: new TextStyle(
                      color: Theme.of(context).accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
                new Row(
                  children: <Widget>[
                    new RaisedButton(
                      onPressed: _launchDownloadWebsite(),
                      child: Text("Letöltés"),
                    )
                  ],
                )
              ],
              title: Text("Frissítés elérhető!"),
              contentPadding: EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                side: BorderSide(style: BorderStyle.none, width: 1),
                borderRadius: BorderRadius.circular(10),
              ));
        });
  }

  @override
  void initState() {
    _initSettings();
    super.initState();
    /*
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!(await SettingsHelper().getAcceptTOS()))
            showTOSDialog();
          else if (!(await SettingsHelper().getAcceptBlock())) showBlockDialog();
        });
        */
    //print("####################################");

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (globals.version != globals.latestVersion &&
          globals.latestVersion != "") {
        //print("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&");
        showUpdateDialog();
      }
    });

    _onRefresh(offline: true, showErrors: false).then((var a) async {
      mainScreenCards = await feedItems();
    });
    if (globals.firstMain) {
      _onRefresh(offline: false, showErrors: false).then((var a) async {
        mainScreenCards = await feedItems();
      });
      globals.firstMain = false;
    }
    startDate = now;
    new Timer.periodic(
        Duration(seconds: 10),
        (Timer t) => () async {
              mainScreenCards = await feedItems();
              setState(() {});
            });
  }

  Future<List<Widget>> feedItems() async {
    int maximumFeedLength = 100;
    List<Widget> feedCards = new List();

    for (Account account in globals.accounts) {
      List<Evaluation> firstQuarterEvaluations = (evaluations.where(
          (Evaluation evaluation) => (evaluation.isFirstQuarter() &&
              evaluation.owner == account.user))).toList();
      List<Evaluation> halfYearEvaluations = (evaluations.where(
          (Evaluation evaluation) => (evaluation.isHalfYear() &&
              evaluation.owner == account.user))).toList();
      List<Evaluation> thirdQuarterEvaluations = (evaluations.where(
          (Evaluation evaluation) => (evaluation.isThirdQuarter() &&
              evaluation.owner == account.user))).toList();
      List<Evaluation> endYearEvaluations = (evaluations.where(
              (Evaluation evaluation) =>
                  (evaluation.isEndYear() && evaluation.owner == account.user)))
          .toList();

      if (firstQuarterEvaluations.isNotEmpty)
        feedCards.add(new SummaryCard(firstQuarterEvaluations, context,
            "Első negyedévi jegyek", false, true, !globals.isSingle));
      if (halfYearEvaluations.isNotEmpty)
        feedCards.add(new SummaryCard(halfYearEvaluations, context,
            "Félévi jegyek", false, true, !globals.isSingle));
      if (thirdQuarterEvaluations.isNotEmpty)
        feedCards.add(new SummaryCard(thirdQuarterEvaluations, context,
            "Harmadik negyedévi jegyek", false, true, !globals.isSingle));
      if (endYearEvaluations.isNotEmpty)
        feedCards.add(new SummaryCard(endYearEvaluations, context,
            "Év végi jegyek", false, true, !globals.isSingle));
    }

    for (String day in absents.keys.toList())
      feedCards.add(new AbsenceCard(absents[day], globals.isSingle, context));
    for (Evaluation evaluation in evaluations.where((Evaluation evaluation) =>
        !evaluation.isSummaryEvaluation())) //Only add non-summary evals
      feedCards.add(new EvaluationCard(
          evaluation, globals.isColor, globals.isSingle, context));
    for (Note note in notes)
      feedCards.add(new NoteCard(note, globals.isSingle, context));
    for (Lesson l in lessons.where((Lesson lesson) =>
        (lesson.isMissed || lesson.isSubstitution) && lesson.date.isAfter(now)))
      feedCards.add(ChangedLessonCard(l, context));

    List realLessons = lessons.where((Lesson l) => !l.isMissed).toList();
    bool isLessonsToday = false;
    bool isLessonsTomorrow = false;
    for (Lesson l in realLessons) {
      if (l.start.isAfter(now) && l.start.day == now.day) {
        isLessonsToday = true;
        break;
      }
    }
    if (realLessons.length > 0 && isLessonsToday) {
      feedCards.add(new LessonCard(realLessons, context, now));
    }
    try {
      feedCards.sort((Widget a, Widget b) {
        return b.key.toString().compareTo(a.key.toString());
      });
    } catch (e) {
      print(e);
    }
    //TODO homework cards
    /*for (Lesson l in lessons) {
          if (l.homework != null){
            print(l.homework);
            List<Homework> homeworks = await HomeworkHelper().getHomeworksByLesson(l);
            for (Homework homework in homeworks)
              print(homework.text);
              //feedCards.add(HomeworkCard(homework, globals.isSingle, context));
          }
        }
        */
    for (Lesson l in realLessons) {
      if (l.start.isAfter(now) &&
          l.start.day == now.add(Duration(days: 1)).day) {
        isLessonsTomorrow = true;
        break;
      }
    }
    if (realLessons.length > 0 && isLessonsTomorrow)
      feedCards.add(new TomorrowLessonCard(realLessons, context, now));
    try {
      feedCards.sort((Widget a, Widget b) {
        return b.key.toString().compareTo(a.key.toString());
      });
    } catch (e) {
      print(e);
    }
    if (maximumFeedLength > feedCards.length)
      maximumFeedLength = feedCards.length;
    return feedCards.sublist(0, maximumFeedLength);
  }

  Future<bool> _onWillPop() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text(S.of(context).sure),
          content: new Text(S.of(context).confirm_close),
          actions: <Widget>[
            new FlatButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: new Text(S.of(context).no),
            ),
            new FlatButton(
              onPressed: () async {
                await SystemChannels.platform
                    .invokeMethod<void>('SystemNavigator.pop');
              },
              child: new Text(S.of(context).yes),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
            drawer: GDrawer(),
            appBar: new AppBar(
              title: new Text(globals.isSingle
                  ? globals.selectedAccount.user.name
                  : S.of(context).title),
              actions: <Widget>[
                //TODO search maybe?
                /*new IconButton( //TODO Finish card chooser
                  icon: new Icon(Icons.queue),
                  onPressed: () {
                    cardChooserDialog().then((b) {
                      Navigator.pushNamed(context, "/main");
                    });
                  }
                )*/
              ],
            ),
            body: hasOfflineLoaded &&
                    globals.isColor != null &&
                    mainScreenCards != null
                ? new Container(
                    child: Column(children: <Widget>[
                    !hasLoaded
                        ? Container(
                            child: new LinearProgressIndicator(
                              value: null,
                            ),
                            height: 3,
                          )
                        : Container(
                            height: 3,
                          ),
                    new Expanded(
                      child: new RefreshIndicator(
                        child: new ListView(
                          children: mainScreenCards,
                        ),
                        onRefresh: () {
                          Completer<Null> completer = new Completer<Null>();
                          _onRefresh().then((bool b) async {
                            mainScreenCards = await feedItems();
                            setState(() {
                              completer.complete();
                            });
                          });
                          return completer.future;
                        },
                      ),
                    ),
                  ]))
                : new Center(child: new CircularProgressIndicator())));
  }

  Future<Null> cardChooserDialog() {
    return showDialog(
        barrierDismissible: true,
        context: context,
        builder: (BuildContext context) {
          return new CardChooserDialog();
        });
  }

  Future<Null> _onRefresh(
      {bool offline = false, bool showErrors = true}) async {
    List<Evaluation> tempEvaluations = new List();
    Map<String, List<Absence>> tempAbsents = new Map();
    List<Note> tempNotes = new List();
    setState(() {
      if (offline)
        hasOfflineLoaded = false;
      else
        hasLoaded = false;
    });
    if (globals.isSingle) {
      try {
        await globals.selectedAccount.refreshStudentString(offline, showErrors);
        tempEvaluations.addAll(globals.selectedAccount.student.Evaluations);
        tempNotes.addAll(globals.selectedAccount.notes);
        tempAbsents.addAll(globals.selectedAccount.absents);
      } catch (exception) {
        Fluttertoast.showToast(
            msg: "Hiba",
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
        print("singleexcp: " + exception.toString());
      }
    } else {
      for (Account account in globals.accounts) {
        try {
          try {
            await account.refreshStudentString(offline, showErrors);
          } catch (e) {
            print("error, needs relogin");
          }
          tempEvaluations.addAll(account.student.Evaluations);
          tempNotes.addAll(account.notes);
          tempAbsents.addAll(account.absents);
        } catch (exception) {
          print(exception);
        }
      }
    }
    if (tempEvaluations.length > 0) evaluations = tempEvaluations;
    if (tempAbsents.length > 0) absents = tempAbsents;
    if (tempNotes.length > 0) notes = tempNotes;
    startDate = now;
    //startDate = startDate.add(new Duration(days: (-1 * startDate.weekday + 1)));
    if (offline) {
      if (globals.lessons.length > 0) {
        lessons.addAll(globals.lessons);
      } else {
        try {
          lessons = await getLessonsOffline(startDate,
              startDate.add(Duration(days: 6)), globals.selectedUser);
        } catch (exception) {
          print(exception);
        }
        if (lessons.length > 0) globals.lessons.addAll(lessons);
      }
    } else {
      try {
        lessons = await getLessons(startDate, startDate.add(Duration(days: 6)),
            globals.selectedUser, showErrors);
      } catch (exception) {
        print(exception);
      }
    }
    try {
      lessons.sort((Lesson a, Lesson b) => a.start.compareTo(b.start));
      if (lessons.length > 0) globals.lessons = lessons;
    } catch (e) {
      print(e);
    }
    Completer<Null> completer = new Completer<Null>();
    if (!offline) hasLoaded = true;
    hasOfflineLoaded = true;
    if (mounted) {
      setState(() {
        completer.complete();
      });
    }
    return completer.future;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
