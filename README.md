# xcvbnm

This is intended as a Dart port of zxcvbn (see https://github.com/dropbox/zxcvbn), a realistic password strength 
estimator.

**Please note, that this is currently in development.**

## usage

    
    library xcvbnm.example.bin;
    
    import 'package:xcvbnm/xcvbnm.dart';
    
    test1() {
      String password = "my_pwd_1";
      // Use the direct helper API
      Result result = xcvbnm(password);
      print(result.toMap());
    }
    
    test2() {
      String password = "my_pwd_1";
      // Use the object (can allow mocking)
      Xcvbnm xcvbnm = new Xcvbnm();
      Result result = xcvbnm.estimate(password);
      print(result.toMap());
    }
    
    main() {
      test1();
      test2();
    }

    
### mock

Mock Xcvbnm can be mocked. there is a dummy mock implementation. This can be replaced for your needs

    import 'package:xcvbnm/mock_xcvbnm.dart';
    
    main() {
      String password = "my_pwd_1";
    
      Xcvbnm xcvbnm = new Xcvbnm();
      Result result = xcvbnm.estimate(password);
      print(result.toMap());
    }
    
## demo

### browser

[Online demo](http://gstest.tekartik.com/xcvbnm/demo/) dart code compiled with dart2js

### command line

    $  dart bin/xcvbnm_demo.dart --help
      -h, --help     Usage help
      -m, --match    Max number max of match to display
                     (defaults to "4")
    $ dart bin/xcvbnm_demo.dart
    $ dart bin/xcvbnm_demo.dart 9IOksjdopwd
    $ dart bin/xcvbnm_demo.dart "my password"
    $ dart bin/xcvbnm_demo.dart pwd1 pwd2 -m 1

## development

### guidelines and format

Before each commit format at the root of the project

    $ dartfmt -l 120 -w .
    
### test

Run all tests in multiple platforms

    $ pub run test -p vm -p content-shell -p firefox

    
