import 'package:globens_flutter_client/entities/JobApplication.dart';
import 'package:globens_flutter_client/entities/GlobensUser.dart';
import 'package:globens_flutter_client/entities/AppUser.dart';
import 'package:globens_flutter_client/entities/Job.dart';
import 'package:globens_flutter_client/entities/Product.dart';
import 'package:globens_flutter_client/utils/Locale.dart';
import 'package:globens_flutter_client/utils/Utils.dart';
import 'package:globens_flutter_client/utils/DriveHelper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'dart:typed_data';
import 'dart:io';

class JobApplicationCreatorModalView extends StatefulWidget {
  final Job job;

  JobApplicationCreatorModalView(this.job);

  @override
  State<StatefulWidget> createState() => _JobApplicationCreatorModalViewState();
}

class _JobApplicationCreatorModalViewState extends State<JobApplicationCreatorModalView> {
  final TextEditingController _applicantMessage = TextEditingController();
  GlobensUser applicantUser;
  List<File> _applicationAttachments = <File>[];
  Set<String> _uploadingFiles = Set();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 10.0, bottom: 30.0 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              margin: EdgeInsets.only(right: 30.0),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(icon: Icon(Icons.arrow_back_ios), onPressed: _onBackButtonPressed),
                getTitleWidget(Locale.get('Application form'), textColor: Colors.black, margin: EdgeInsets.zero),
              ])),
          getSectionSplitter(Locale.get('Apply to "${Locale.REPLACE}"', widget.job.title)),
          Card(
            margin: EdgeInsets.only(top: 5.0, left: 15.0, right: 15.0),
            child: Container(
              padding: EdgeInsets.only(left: 5.0, right: 5.0),
              child: TextField(
                maxLines: 1,
                controller: _applicantMessage,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(labelText: Locale.get("Your message goes here"), labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: Colors.blueAccent), hintText: Locale.get("e.g., I'm the applicant recommended by mr. John Doe"), border: InputBorder.none),
              ),
            ),
          ),
          if (_applicationAttachments.length > 0)
            Column(
                children: _applicationAttachments
                    .map((file) => Card(margin: EdgeInsets.only(top: 10.0, left: 15.0, right: 15.0), child: Container(padding: EdgeInsets.only(left: 5.0, right: 5.0, top: 2.5, bottom: 2.5), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Image.file(file, width: 30.0), Text(RegExp(r'^(.+/)(.+)$').firstMatch(file.path).group(2)), IconButton(onPressed: () => _removeFileContent(file), icon: Icon(Icons.highlight_remove_outlined, color: Colors.redAccent))]))))
                    .toList()),

          if(_uploadingFiles.isNotEmpty)
            SizedBox(child: CircularProgressIndicator(), height: 24.0, width: 24.0),
          Container(
                margin: EdgeInsets.only(top: 15.0),
                child: RaisedButton.icon(onPressed: _uploadingFiles.isNotEmpty ? null : _uploadFilePressed, color: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))), icon: Icon(Icons.attachment_outlined, color: Colors.white), label: Text(_applicationAttachments.length == 0 ? Locale.get("Attach files (e.g., CV, recommendations)") : Locale.get("Reselect attachments (e.g., CV)"), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),

          Container(
              margin: EdgeInsets.only(top: 10.0, left: 30.0, right: 30.0),
              child: RaisedButton.icon(onPressed: () => _onSubmitApplicationFormPressed(widget.job), color: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))), icon: Icon(Icons.send_rounded, color: Colors.white), label: Text(Locale.get("Submit application form"), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
        ],
      ),
    );
  }

  void _onBackButtonPressed() {
    Navigator.of(context).pop();
  }

  void _uploadFilePressed() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null) {
      setState(() {
        _applicationAttachments = result.paths.map((path) => File(path)).toList();
      });
    } else {
      toast(Locale.get("Selection cancelled!"));
    }
  }

  void _removeFileContent(File file) {
    setState(() {
      _applicationAttachments.remove(file);
    });
  }

  void _onSubmitApplicationFormPressed(Job job) async {
    if (_applicantMessage.text.length < 5) {
      await toast(Locale.get("Message can't be less than 5 characters."));
      return;
    }

    Map<String, dynamic> contents;
    bool success = true;
    contents = {'ids': <int>[]};

    if (_applicationAttachments.length == 0) {
      await toast(Locale.get("Your job application must have at least one attachment!"));
      return;
    } else {
      for (File localFile in _applicationAttachments){
        var fileName = path.basename(localFile.path);
        var tp = await grpcCreateNewContent(AppUser.sessionKey, Content.create(fileName, "", ""));
        success &= tp.item1;
        if (success) {
          var id = tp.item2;
          var uploadedFile = await DriveHelper.uploadFile(fileName, localFile);
          success &= uploadedFile != null;
          if (success) {
            grpcUpdateContent(AppUser.sessionKey, Content.create(fileName, uploadedFile.item1, uploadedFile.item2, id: id));
            contents['ids'].add(id);
            setState(() {
              _uploadingFiles.remove(localFile.path);
            });
          }
        }
      }
    }

    success = await grpcCreateJobApplication(AppUser.sessionKey, job, JobApplication.create(_applicantMessage.text, contents, job));
    if (success) {
      await toast(Locale.get("Submitted"));
      Navigator.of(context).pop();
    } else {
      await AppUser.signOut();
      await Navigator.of(context).pushReplacementNamed('/');
    }
  }
}
