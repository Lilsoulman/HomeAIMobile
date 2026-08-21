class CourierShipmentCreateDto {
  const CourierShipmentCreateDto({
    required this.trackingNumber,
    this.carrier,
    this.label,
    this.isFreshFood = false,
    this.expectedDeliveryAt,
  });

  final String trackingNumber;
  final String? carrier;
  final String? label;
  final bool isFreshFood;
  final DateTime? expectedDeliveryAt;

  Map<String, dynamic> toJson() => {
    'trackingNumber': trackingNumber,
    if (carrier != null && carrier!.trim().isNotEmpty) 'carrier': carrier,
    if (label != null && label!.trim().isNotEmpty) 'label': label,
    'isFreshFood': isFreshFood,
    if (expectedDeliveryAt != null)
      'expectedDeliveryAt': expectedDeliveryAt!.toUtc().toIso8601String(),
  };
}

class CourierShipmentDto {
  const CourierShipmentDto({
    required this.id,
    required this.trackingNumberMasked,
    required this.carrier,
    required this.label,
    required this.isFreshFood,
    required this.expectedDeliveryAt,
    required this.latestStatus,
    required this.latestDescription,
    required this.latestLocation,
    required this.latestEventAt,
    required this.lastCheckedAt,
  });

  factory CourierShipmentDto.fromJson(
    Map<String, dynamic> json,
  ) => CourierShipmentDto(
    id: _int(json['Id'] ?? json['id']),
    trackingNumberMasked:
        (json['TrackingNumberMasked'] ?? json['trackingNumberMasked'] ?? '****')
            .toString(),
    carrier: _string(json['Carrier'] ?? json['carrier']),
    label: _string(json['Label'] ?? json['label']),
    isFreshFood: _bool(json['IsFreshFood'] ?? json['isFreshFood']),
    expectedDeliveryAt: _date(
      json['ExpectedDeliveryAt'] ?? json['expectedDeliveryAt'],
    ),
    latestStatus: (json['LatestStatus'] ?? json['latestStatus'] ?? 'in_transit')
        .toString(),
    latestDescription: _string(
      json['LatestDescription'] ?? json['latestDescription'],
    ),
    latestLocation: _string(json['LatestLocation'] ?? json['latestLocation']),
    latestEventAt: _date(json['LatestEventAt'] ?? json['latestEventAt']),
    lastCheckedAt: _date(json['LastCheckedAt'] ?? json['lastCheckedAt']),
  );

  final int id;
  final String trackingNumberMasked;
  final String? carrier;
  final String? label;
  final bool isFreshFood;
  final DateTime? expectedDeliveryAt;
  final String latestStatus;
  final String? latestDescription;
  final String? latestLocation;
  final DateTime? latestEventAt;
  final DateTime? lastCheckedAt;
}

class CourierShipmentEventDto {
  const CourierShipmentEventDto({
    required this.status,
    required this.description,
    required this.location,
    required this.occurredAt,
  });

  factory CourierShipmentEventDto.fromJson(Map<String, dynamic> json) =>
      CourierShipmentEventDto(
        status: (json['Status'] ?? json['status'] ?? '').toString(),
        description: (json['Description'] ?? json['description'] ?? '')
            .toString(),
        location: _string(json['Location'] ?? json['location']),
        occurredAt:
            _date(json['OccurredAt'] ?? json['occurredAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  final String status;
  final String description;
  final String? location;
  final DateTime occurredAt;
}

class CourierAnomalyDto {
  const CourierAnomalyDto({
    required this.shipmentId,
    required this.type,
    required this.title,
    required this.description,
    required this.suggestedAction,
    required this.confirmationId,
  });

  factory CourierAnomalyDto.fromJson(
    Map<String, dynamic> json,
  ) => CourierAnomalyDto(
    shipmentId: _int(json['ShipmentId'] ?? json['shipmentId']),
    type: (json['Type'] ?? json['type'] ?? '').toString(),
    title: (json['Title'] ?? json['title'] ?? '').toString(),
    description: (json['Description'] ?? json['description'] ?? '').toString(),
    suggestedAction: (json['SuggestedAction'] ?? json['suggestedAction'] ?? '')
        .toString(),
    confirmationId: _nullableInt(
      json['ConfirmationId'] ?? json['confirmationId'],
    ),
  );

  final int shipmentId;
  final String type;
  final String title;
  final String description;
  final String suggestedAction;
  final int? confirmationId;
}

class CourierRefreshDto {
  const CourierRefreshDto({
    required this.shipment,
    required this.newEvents,
    required this.anomalies,
  });

  factory CourierRefreshDto.fromJson(Map<String, dynamic> json) =>
      CourierRefreshDto(
        shipment: CourierShipmentDto.fromJson(
          _map(json['Shipment'] ?? json['shipment']),
        ),
        newEvents: _list(
          json['NewEvents'] ?? json['newEvents'],
        ).map(CourierShipmentEventDto.fromJson).toList(growable: false),
        anomalies: _list(
          json['Anomalies'] ?? json['anomalies'],
        ).map(CourierAnomalyDto.fromJson).toList(growable: false),
      );

  final CourierShipmentDto shipment;
  final List<CourierShipmentEventDto> newEvents;
  final List<CourierAnomalyDto> anomalies;
}

int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
int? _nullableInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
bool _bool(dynamic value) =>
    value is bool ? value : value?.toString() == 'true';
String? _string(dynamic value) => value?.toString();
DateTime? _date(dynamic value) => DateTime.tryParse(value?.toString() ?? '');
Map<String, dynamic> _map(dynamic value) =>
    value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};
List<Map<String, dynamic>> _list(dynamic value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList(growable: false)
    : const [];
