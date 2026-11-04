class ImageSearchResult {
  final String id;
  final String title;
  final String thumbnail;
  final String imageUrl;
  final String creator;
  final String? creatorUrl;
  final String license;
  final String? licenseVersion;
  final String? licenseUrl;
  final String? foreignLandingUrl;

  const ImageSearchResult({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.imageUrl,
    required this.creator,
    this.creatorUrl,
    required this.license,
    this.licenseVersion,
    this.licenseUrl,
    this.foreignLandingUrl,
  });

  bool get isPublicDomainOrCc0 {
    final l = license.toLowerCase();
    return l == 'cc0' || l == 'pdm' || l.contains('zero') || l.contains('publicdomain');
  }

  factory ImageSearchResult.fromJson(Map<String, dynamic> json) {
    return ImageSearchResult(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled AAC Image',
      thumbnail: json['thumbnail']?.toString() ?? json['url']?.toString() ?? '',
      imageUrl: json['url']?.toString() ?? '',
      creator: json['creator']?.toString() ?? 'Anonymous',
      creatorUrl: json['creator_url']?.toString(),
      license: json['license']?.toString().toLowerCase() ?? 'cc0',
      licenseVersion: json['license_version']?.toString(),
      licenseUrl: json['license_url']?.toString(),
      foreignLandingUrl: json['foreign_landing_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'thumbnail': thumbnail,
    'imageUrl': imageUrl,
    'creator': creator,
    'creatorUrl': creatorUrl,
    'license': license,
    'licenseVersion': licenseVersion,
    'licenseUrl': licenseUrl,
    'foreignLandingUrl': foreignLandingUrl,
  };
}
