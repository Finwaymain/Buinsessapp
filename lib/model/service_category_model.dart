class ServiceCategoryData {
  int? id;
  String? libelle;
  String? image;
  bool hasChildren;

  ServiceCategoryData({this.id, this.libelle, this.image, this.hasChildren = false});

  ServiceCategoryData.fromJson(Map<String, dynamic> json)
      : id = json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
        libelle = json['libelle']?.toString(),
        image = json['image']?.toString(),
        hasChildren = json['has_children'] == true;
}
