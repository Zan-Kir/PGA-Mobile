// Configurações centralizadas da aplicação
class AppConfig {
  // URL base do backend
  static const String baseUrl = 'http://192.168.50.54:3000';
  
  // Endpoints da API
  static const String loginEndpoint = '$baseUrl/auth/login';
  static const String meEndpoint = '$baseUrl/auth/me';
  static const String refreshEndpoint = '$baseUrl/auth/refresh';
  
  // Endpoints de projetos
  static const String projectsEndpoint = '$baseUrl/project1';
  static const String createProjectEndpoint = '$baseUrl/project1';
  
  // Endpoints de cursos
  static const String coursesEndpoint = '$baseUrl/courses';
  
  // Endpoints de usuários
  static const String usersEndpoint = '$baseUrl/users';
  
  // Endpoints de anexos
  static const String attachmentsEndpoint = '$baseUrl/attachments';
  
  // Endpoints de auditorias
  static const String auditsEndpoint = '$baseUrl/audits';
  
  // Outros endpoints conforme necessário
  static String getProjectEndpoint(int id) => '$baseUrl/projects/$id';
  static String getUserEndpoint(int id) => '$baseUrl/users/$id';
  static String getAttachmentEndpoint(int id) => '$baseUrl/attachments/$id';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Assets
  static const String appLogoAsset = 'assets/icons/app_icon.png';
}
