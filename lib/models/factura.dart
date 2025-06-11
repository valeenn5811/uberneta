class Factura {
  final int id;
  final double precio;
  final String concepto;
  final String fecha;
  final String nombre;
  final String enlace;
  final String observaciones;
  final String nombreCliente;
  final String dniCliente;
  final String direccionCliente;
  final String provinciaCliente;
  final String codigoPostalCliente;
  final String nombreTaxista;
  final String dniTaxista;
  final String direccionTaxista;
  final String provinciaTaxista;
  final String codigoPostalTaxista;
  final int numeroLicencia;
  final int iva;

  Factura({
    required this.id,
    required this.precio,
    required this.concepto,
    required this.fecha,
    required this.nombre,
    required this.enlace,
    required this.observaciones,
    required this.nombreCliente,
    required this.dniCliente,
    required this.direccionCliente,
    required this.provinciaCliente,
    required this.codigoPostalCliente,
    required this.nombreTaxista,
    required this.dniTaxista,
    required this.direccionTaxista,
    required this.provinciaTaxista,
    required this.codigoPostalTaxista,
    required this.numeroLicencia,
    required this.iva,
  });

  factory Factura.fromJson(Map<String, dynamic> json) {
    return Factura(
      id: json['IdFactura'],
      precio: (json['Precio'] as num).toDouble(),
      concepto: json['Concepto'],
      fecha: json['FechaFactura'],
      nombre: json['RazonSocial'],
      enlace: json['Enlace'],
      observaciones: json['ObservacionesFactura'],
      nombreCliente: json['NombreCliente'],
      dniCliente: json['DNICliente'],
      direccionCliente: json['DireccionCliente'],
      provinciaCliente: json['ProvinciaCliente'],
      codigoPostalCliente: json['CodigoPostalCliente'],
      nombreTaxista: json['NombreTaxista'],
      dniTaxista: json['DNITaxista'],
      direccionTaxista: json['DireccionTaxista'] ?? '',
      provinciaTaxista: json['ProvinciaTaxista'] ?? '',
      codigoPostalTaxista: json['CodigoPostalTaxista'] ?? '',
      numeroLicencia: json['CodUsuarioTaxista'],
      iva: json['IVA'],
    );
  }
}
