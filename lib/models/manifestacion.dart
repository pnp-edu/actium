class ManifestacionQA {
  String pregunta;
  String respuesta;

  ManifestacionQA({required this.pregunta, required this.respuesta});

  Map<String, dynamic> toJson() => {
        'pregunta': pregunta,
        'respuesta': respuesta,
      };

  factory ManifestacionQA.fromJson(Map<String, dynamic> json) {
    return ManifestacionQA(
      pregunta: json['pregunta'],
      respuesta: json['respuesta'],
    );
  }
}

class ManifestacionOptions {
  bool includeAbogado;
  bool includeFiscal;
  bool includeInterprete;
  bool includeTestigoRuego;

  ManifestacionOptions({
    this.includeAbogado = false,
    this.includeFiscal = false,
    this.includeInterprete = false,
    this.includeTestigoRuego = false,
  });

  Map<String, dynamic> toJson() => {
        'includeAbogado': includeAbogado,
        'includeFiscal': includeFiscal,
        'includeInterprete': includeInterprete,
        'includeTestigoRuego': includeTestigoRuego,
      };

  factory ManifestacionOptions.fromJson(Map<String, dynamic> json) {
    return ManifestacionOptions(
      includeAbogado: json['includeAbogado'] ?? false,
      includeFiscal: json['includeFiscal'] ?? false,
      includeInterprete: json['includeInterprete'] ?? false,
      includeTestigoRuego: json['includeTestigoRuego'] ?? false,
    );
  }
}

class ManifestacionData {
  String pregunta01Respuesta;
  List<ManifestacionQA> qaList;
  String preguntaUltimaRespuesta;
  ManifestacionOptions options;

  ManifestacionData({
    this.pregunta01Respuesta = '',
    List<ManifestacionQA>? qaList,
    this.preguntaUltimaRespuesta = '',
    ManifestacionOptions? options,
  })  : qaList = qaList ?? [],
        options = options ?? ManifestacionOptions();

  Map<String, dynamic> toJson() => {
        'pregunta01Respuesta': pregunta01Respuesta,
        'qaList': qaList.map((e) => e.toJson()).toList(),
        'preguntaUltimaRespuesta': preguntaUltimaRespuesta,
        'options': options.toJson(),
      };

  factory ManifestacionData.fromJson(Map<String, dynamic> json) {
    return ManifestacionData(
      pregunta01Respuesta: json['pregunta01Respuesta'] ?? '',
      qaList: (json['qaList'] as List?)
              ?.map((e) => ManifestacionQA.fromJson(e))
              .toList() ??
          [],
      preguntaUltimaRespuesta: json['preguntaUltimaRespuesta'] ?? '',
      options: json['options'] != null
          ? ManifestacionOptions.fromJson(json['options'])
          : ManifestacionOptions(),
    );
  }
}
