## 0.4.0-nullsafety.0

- Initial alpha version 0.4.0 (version starting with aligment to other packages)
- Designed for null-safety (requires sdk: '>=2.12.0-0 <3.0.0')
- Uses as dependency: `equatable` (^2.0.0-nullsafety.0)
- Uses as dependency: `meta` (^1.3.0-nullsafety.6)
- Uses as dependency: `http` (^0.12.2)
- Uses as dependency: `http_parser` (^3.1.4)
- "client", "client_http" and "utils" libs were moved here from `geodata`
- "meta" with Link class was moved here from `geocore`
- Structure of lib/src folder:
  - client
    - base
    - http
  - meta
    - link
  - utils
    - format
- Mini-libraries provided by the package:
  - 'package:datatools/client_base.dart'
  - 'package:datatools/client_http.dart'
  - 'package:datatools/meta_link.dart'
- The whole library is available by:
  - 'package:datatools/datatools.dart'
