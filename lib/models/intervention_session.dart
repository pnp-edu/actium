import 'package:uuid/uuid.dart';

class InterventionDocument {
  final String id;
  String title;
  String content;

  InterventionDocument({
    String? id,
    required this.title,
    required this.content,
  }) : id = id ?? const Uuid().v4();
}

class DetaineeInfo {
  final String dni;
  String? names;
  String? paternalSurname;
  String? maternalSurname;
  bool fromApi;

  DetaineeInfo({
    required this.dni,
    this.names,
    this.paternalSurname,
    this.maternalSurname,
    this.fromApi = false,
  });
}

class InterventionSession {
  final String id;
  String name;
  String? typificationId;
  List<InterventionDocument> documents;
  List<DetaineeInfo> detainees;
  List<DetaineeInfo> agraviados;
  bool comunicacionFiscal;
  bool negoFirmar;

  InterventionSession({
    String? id,
    required this.name,
    this.typificationId,
    required this.documents,
    this.detainees = const [],
    this.agraviados = const [],
    this.comunicacionFiscal = true,
    this.negoFirmar = false,
  }) : id = id ?? const Uuid().v4();
}
