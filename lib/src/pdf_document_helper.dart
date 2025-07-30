// lib/common/helpers/pdf_document_helper.dart

abstract final class PdfDocumentHelper {
  static bool isPdf(String url) => url.toLowerCase().endsWith('.pdf');
}
