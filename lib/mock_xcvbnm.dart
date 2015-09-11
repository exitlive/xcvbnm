library xcvbnm.mock;

import 'src/xcvbnm_common.dart' hide Xcvbnm;
export 'src/xcvbnm_common.dart' hide Xcvbnm;
export 'src/mock_xcvbnm_impl.dart';
import 'src/mock_xcvbnm_impl.dart';

/**
 * the one and only entrypoint needed for the mock implementation
 */
Result xcvbnm(String password, {List<String> userInputs}) {
  Xcvbnm impl = new Xcvbnm();
  return impl.estimate(password);
}
