import 'package:image/image.dart' as img;

void main() {
  final image = img.Image(width: 100, height: 100);
  
  // Try writing text
  try {
    img.drawString(image, 'Hello', font: img.arial24, x: 10, y: 10);
    print('drawString arial24 success');
  } catch (e) {
    print('drawString error: $e');
  }
}
