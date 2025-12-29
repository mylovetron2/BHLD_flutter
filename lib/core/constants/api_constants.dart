class ApiConstants {
  // Base URL - thay đổi theo môi trường
  static const String baseUrl = 'http://diavatly.com/BHLD/api';

  // Endpoints
  static const String employees = '/employees.php';
  static const String certificates = '/certificates.php';
  static const String certificateDetails = '/certificate_details.php';
  static const String equipment = '/equipment.php';
  static const String allocate = '/allocate.php';
  static const String deallocate = '/deallocate.php';

  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };
}
