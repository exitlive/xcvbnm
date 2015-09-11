library xcvbnm;

import 'src/xcvbnm_common.dart' hide Xcvbnm;
export 'src/xcvbnm_common.dart' hide Xcvbnm;
export 'src/xcvbnm_impl.dart';
import 'src/xcvbnm_impl.dart';

/**
 * the one and only entrypoint needed
 */
Result xcvbnm(String password, {List<String> userInputs}) {
  Xcvbnm impl = new Xcvbnm();
  return impl.estimate(password);
}
