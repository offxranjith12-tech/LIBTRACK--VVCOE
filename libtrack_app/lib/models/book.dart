enum BookAvailability { available, issued }

class Book {
  final String id;
  final String title;
  final String author;
  final String isbn;
  final String category;
  final String department;
  final String publisher;
  final String edition;
  final String rackNumber;
  final String shelfNumber;
  final int totalCopies;
  final int availableCopies;
  final String description;
  final String coverColorHex;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.category,
    required this.department,
    required this.publisher,
    required this.edition,
    required this.rackNumber,
    required this.shelfNumber,
    required this.totalCopies,
    required this.availableCopies,
    required this.description,
    this.coverColorHex = 'B71C1C',
  });

  BookAvailability get availability =>
      availableCopies > 0 ? BookAvailability.available : BookAvailability.issued;

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'].toString(),
        title: json['title'] ?? '',
        author: json['author'] ?? '',
        isbn: json['isbn'] ?? '',
        category: json['category'] ?? '',
        department: json['department'] ?? '',
        publisher: json['publisher'] ?? '',
        edition: json['edition'] ?? '',
        rackNumber: json['rackNumber'] ?? '',
        shelfNumber: json['shelfNumber'] ?? '',
        totalCopies: json['totalCopies'] ?? 0,
        availableCopies: json['availableCopies'] ?? 0,
        description: json['description'] ?? '',
        coverColorHex: json['coverColorHex'] ?? 'B71C1C',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'isbn': isbn,
        'category': category,
        'department': department,
        'publisher': publisher,
        'edition': edition,
        'rackNumber': rackNumber,
        'shelfNumber': shelfNumber,
        'totalCopies': totalCopies,
        'availableCopies': availableCopies,
        'description': description,
        'coverColorHex': coverColorHex,
      };
}
