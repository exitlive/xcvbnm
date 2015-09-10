# xcvbnm
--------
This is intended as a Dart port of zxcvbn (see https://github.com/dropbox/zxcvbn), a realistic password strength 
estimator.

**Please note, that this is currently in development.**


# development
-------------

## guidelines and format

Before each commit format at the root of the project

    $ dartfmt -l 120 w .
    
## test

Run all tests in multiple platforms

    $ pub run test -p vm -p content-shell -p firefox

    
