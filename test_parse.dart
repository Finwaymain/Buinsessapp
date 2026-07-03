import 'dart:convert';
import 'lib/model/model.dart';

void main() {
  var jsonResponse = {
    "success": "success",
    "data": [
      {"id": "1", "name": "Splendor Plus", "vehicle_type_id": "1"}
    ]
  };
  var model = Model.fromJson(jsonResponse);
  print('vehicleTypeId: ${model.data![0].vehicleTypeId}');
}
