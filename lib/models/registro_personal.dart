class BienIncautado {
  String cantidad;
  String unidadMedida;
  String descripcion;
  String condicionLegal;
  String? marcaRotulo;

  BienIncautado({
    required this.cantidad,
    required this.unidadMedida,
    required this.descripcion,
    required this.condicionLegal,
    this.marcaRotulo,
  });

  Map<String, dynamic> toJson() => {
        'cantidad': cantidad,
        'unidadMedida': unidadMedida,
        'descripcion': descripcion,
        'condicionLegal': condicionLegal,
        'marcaRotulo': marcaRotulo,
      };

  factory BienIncautado.fromJson(Map<String, dynamic> json) {
    return BienIncautado(
      cantidad: json['cantidad'],
      unidadMedida: json['unidadMedida'],
      descripcion: json['descripcion'],
      condicionLegal: json['condicionLegal'],
      marcaRotulo: json['marcaRotulo'],
    );
  }
}

class RegistroPersonalData {
  List<BienIncautado> bienes;

  RegistroPersonalData({
    List<BienIncautado>? bienes,
  }) : bienes = bienes ?? [];

  Map<String, dynamic> toJson() => {
        'bienes': bienes.map((e) => e.toJson()).toList(),
      };

  factory RegistroPersonalData.fromJson(Map<String, dynamic> json) {
    return RegistroPersonalData(
      bienes: (json['bienes'] as List?)
              ?.map((e) => BienIncautado.fromJson(e))
              .toList() ??
          [],
    );
  }
}
