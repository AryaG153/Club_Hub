import 'env_loader_io.dart'
    if (dart.library.html) 'env_loader_web.dart';

Future<Map<String, String>> loadRuntimeEnv() => loadRuntimeEnvImpl();
