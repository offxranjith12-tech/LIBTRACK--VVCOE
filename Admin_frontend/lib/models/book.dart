enum BookStatus { available, issued, reserved, lost, damaged }

class Book {
  final String id;
  final String title;
  final String author;
  final String publisher;
  final String isbn;
  final String edition;
  final String category;
  final String department;
  final String rackNumber;
  final String shelfNumber;
  final String regulation;
  final int totalCopies;
  final int availableCopies;
  final String description;
  final String coverUrl;
  final String qrCode;
  final DateTime addedOn;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.publisher,
    required this.isbn,
    required this.edition,
    required this.category,
    required this.department,
    required this.rackNumber,
    required this.shelfNumber,
    this.regulation = '',
    required this.totalCopies,
    required this.availableCopies,
    required this.description,
    required this.coverUrl,
    required this.qrCode,
    required this.addedOn,
  });

  BookStatus get status {
    if (availableCopies <= 0) return BookStatus.issued;
    return BookStatus.available;
  }

  int get issuedCopies => totalCopies - availableCopies;

  String get location => 'Rack $rackNumber • Shelf $shelfNumber';

  Book copyWith({
    String? title,
    String? author,
    String? publisher,
    String? isbn,
    String? edition,
    String? category,
    String? department,
    String? rackNumber,
    String? shelfNumber,
    String? regulation,
    int? totalCopies,
    int? availableCopies,
    String? description,
    String? coverUrl,
    String? qrCode,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
      isbn: isbn ?? this.isbn,
      edition: edition ?? this.edition,
      category: category ?? this.category,
      department: department ?? this.department,
      rackNumber: rackNumber ?? this.rackNumber,
      shelfNumber: shelfNumber ?? this.shelfNumber,
      regulation: regulation ?? this.regulation,
      totalCopies: totalCopies ?? this.totalCopies,
      availableCopies: availableCopies ?? this.availableCopies,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      qrCode: qrCode ?? this.qrCode,
      addedOn: addedOn,
    );
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      publisher: json['publisher'] ?? '',
      isbn: json['isbn'] ?? '',
      edition: json['edition'] ?? '',
      category: json['category'] ?? '',
      department: json['department'] ?? '',
      rackNumber: json['rackNumber'] ?? '',
      shelfNumber: json['shelfNumber'] ?? '',
      regulation: json['regulation'] ?? '',
      totalCopies: json['totalCopies'] ?? 0,
      availableCopies: json['availableCopies'] ?? 0,
      description: json['description'] ?? '',
      coverUrl: json['coverUrl'] ?? '',
      qrCode: json['qrCode'] ?? '',
      addedOn: DateTime.tryParse(json['addedOn'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'publisher': publisher,
        'isbn': isbn,
        'edition': edition,
        'category': category,
        'department': department,
        'rackNumber': rackNumber,
        'shelfNumber': shelfNumber,
        'regulation': regulation,
        'totalCopies': totalCopies,
        'availableCopies': availableCopies,
        'description': description,
        'coverUrl': coverUrl,
        'qrCode': qrCode,
        'addedOn': addedOn.toIso8601String(),
      };
}
