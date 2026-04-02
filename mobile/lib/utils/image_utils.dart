const String _baseUrl = 'https://gia-store-production.up.railway.app';

String resolveImageUrl(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) return '';
  if (imageUrl.startsWith('http')) return imageUrl;
  if (imageUrl.startsWith('/api')) return '$_baseUrl$imageUrl';
  return '$_baseUrl/api/upload/images/$imageUrl';
}
