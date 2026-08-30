/// Supabase loyihasi uchun umumiy sozlamalar. Storage va Edge
/// Function chaqiruvlari shu yerdan foydalanadi — bitta joyda
/// saqlanadi, ikki marta yozilmaydi.
class SupabaseConfig {
  static const String url = 'https://dsbnguwyokxcxfcbeaym.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzYm5ndXd5b2t4Y3hmY2JlYXltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYzNDk3ODksImV4cCI6MjEwMTkyNTc4OX0.H56khBA8cHnvEQ5nJvOjqdRc4kHHN4y4K9cCuXFSzhk';

  /// Edge Functions manzili odatda "<project-url>/functions/v1/<name>".
  static String functionUrl(String name) => '$url/functions/v1/$name';
}
