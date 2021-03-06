import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:unicollab/app/home/mail.dart';
import 'package:unicollab/services/firestore_service.dart';

class CreateAssignment extends StatefulWidget {
  const CreateAssignment(this.data);
  final String data;
  @override
  _CreateAssignmentState createState() => _CreateAssignmentState();
}

class _CreateAssignmentState extends State<CreateAssignment> {
  var title = TextEditingController(),
      description = TextEditingController(),
      marks = TextEditingController(),
      time;
  bool titlevalidation = false;
  bool marksvalidation = false;
  var recipients, classname;
  FirebaseAuth auth = FirebaseAuth.instance;
  List<PlatformFile> result = [];

  void initstate() {
    super.initState();
    getStudents();
    setState(() {});
  }

  adjustText(String text) {
    if (text.length > 45) {
      return text.substring(0, 45) + "...";
    }
    return text;
  }

  Future<void> _createAssignment() async {
    var fireStore = Provider.of<FireStoreService>(context, listen: false);

    try {
      await fireStore.create(
          code: widget.data,
          title: title.text,
          description: description.text,
          marks: int.parse(marks.text),
          type: 2,
          dueDate: time,
          files: result);
    } catch (e) {
      print(e);
    }
  }

  getStudents() {
    FirebaseFirestore _firestore = FirebaseFirestore.instance;
    var students = _firestore
        .collection('classes')
        .doc(widget.data)
        .get()
        .then((value) => {
              {
                recipients = value.data()['students'].cast<String>(),
                classname = value.data()['subject'],
              }
            });
    setState(() {});
  }

  takeFile() async {
    FilePickerResult res =
        await FilePicker.platform.pickFiles(allowMultiple: true);

    setState(() {
      if (res != null) {
        res.files.forEach((element) {
          result.add(element);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    getStudents();
    SendMail sendMail = SendMail();
    var body = auth.currentUser.email + " Added new Assignment in ";
    return Scaffold(
      appBar: AppBar(
        title: Text('Create a assignment'),
        actions: [
          IconButton(
            onPressed: () => takeFile(),
            icon: Icon(Icons.attachment_outlined),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                title.text.isEmpty
                    ? titlevalidation = true
                    : titlevalidation = false;

                marks.text.isEmpty
                    ? marksvalidation = true
                    : marksvalidation = false;
              });
              if (title.text.isNotEmpty && marks.text.isNotEmpty) {
                _createAssignment();
                Navigator.pop(context);
                sendMail.mail(recipients, 'New Assignment', body + classname);
              }
            },
            icon: Icon(Icons.send),
          ),
        ],
      ),
      body: Container(
        color: Colors.black12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Flexible(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: result.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: EdgeInsets.all(10.0),
                              child: TextFormField(
                                autofocus: true,
                                controller: title,
                                decoration: InputDecoration(
                                  filled: true,
                                  labelText: 'Title',
                                  errorText: titlevalidation
                                      ? 'Title can not be empty'
                                      : null,
                                ),
                                textCapitalization:
                                    TextCapitalization.sentences,
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.all(10.0),
                              child: TextFormField(
                                controller: description,
                                decoration: InputDecoration(
                                  filled: true,
                                  labelText: 'Description',
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.all(10.0),
                              child: TextFormField(
                                controller: marks,
                                decoration: InputDecoration(
                                  filled: true,
                                  labelText: 'Marks',
                                  errorText: marksvalidation
                                      ? 'Marks can not be empty'
                                      : null,
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.all(10.0),
                              child: Text(
                                'Deadline of assignment: ',
                                style: GoogleFonts.sourceSansPro(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                DatePicker.showDateTimePicker(context,
                                    showTitleActions: true,
                                    minTime: DateTime.now(),
                                    currentTime: DateTime.now(),
                                    locale: LocaleType.en, onConfirm: (date) {
                                  setState(() {
                                    time = date;
                                  });
                                });
                              },
                              child: Text(
                                (time == null)
                                    ? 'No deadline'
                                    : time.toString(),
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.all(10.0),
                              child: Text(
                                'Attachments: ',
                                style: GoogleFonts.sourceSansPro(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return Container(
                        margin: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            InputChip(
                              backgroundColor: Colors.white,
                              label: Text(
                                adjustText(result[index - 1].name.toString()),
                              ),
                              onDeleted: () {
                                print(index);
                                setState(() {
                                  print('deleted');
                                  result.removeAt(index - 1);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
              ),
            )
          ],
        ),
      ),
    );
  }
}
