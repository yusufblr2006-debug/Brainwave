class Lawyer {
  final String name, specialization, city, contact;
  final double rating;
  factory Lawyer.fromJson(Map<String,dynamic> j) => Lawyer(
    name: j['name'], specialization: j['specialization'],
    city: j['city'], contact: j['contact'],
    rating: j['rating'].toDouble());

  Lawyer({required this.name, required this.specialization, required this.city, required this.contact, required this.rating});
}
