# xcvbnm

This is a dart port of the great [dropbox/zxcvbn](https://github.com/dropbox/zxcvbn) library, a realistic password strength 
estimator.

**Please note, that this is currently in development.**

## Usage

    
    library xcvbnm.example.bin;
    
    import 'package:xcvbnm/xcvbnm.dart';
    
    main() {
      String password = "my_pwd_1";
      // Use the direct helper API
      Result result = new Xcvbnm().estimate(password);
      print(result.toMap());
    }


## Demo

### Browser

[Online demo](http://gstest.tekartik.com/xcvbnm/demo/) dart code compiled with dart2js

### Command line

    $  dart bin/xcvbnm_demo.dart --help
      -h, --help     Usage help
      -m, --match    Max number max of match to display
                     (defaults to "4")
    $ dart bin/xcvbnm_demo.dart
    $ dart bin/xcvbnm_demo.dart 9IOksjdopwd
    $ dart bin/xcvbnm_demo.dart "my password"
    $ dart bin/xcvbnm_demo.dart pwd1 pwd2 -m 1

## Development

### Guidelines and format

Before each commit format at the root of the project

    $ dartfmt -l 120 -w .
    
### Test

Run all tests in multiple platforms

    $ ./test/bin/run_tests.sh

    
