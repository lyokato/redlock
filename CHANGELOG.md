# Change Log

## [1.0.21] - 2024/03/12


## [1.0.20] - 2024/01/18

- Add default database - redix 1.3.0 - nimble_options 1.0 compatibility (https://github.com/lyokato/redlock/pull/47). Thanks to carrascoacd.

## [1.0.19] - 2024/01/18

### CHANGED

- Allow specification of log level. https://github.com/lyokato/redlock/pull/41/files. Thanks to colin-nl.
- Drop support for elixir 1.12 and 1.13. https://github.com/lyokato/redlock/pull/43. Thanks to warmwaffles.
- Logger.warning instead of Logger.warn. https://github.com/lyokato/redlock/pull/45. Thanks to warmwaffles.
- Upgrade redix to 1.3.0. https://github.com/lyokato/redlock/pull/44. Thanks to warmwaffles.

## [1.0.18] - 2023/04/05

### CHANGED

- Allow passing socket opts + improve retry logic (https://github.com/lyokato/redlock/pull/40). Thanks to colin-nl.

## [1.0.17] - 2023/04/02

### CHANGED

- Add extend functionality (https://github.com/lyokato/redlock/pull/39). Thanks to colin-nl.

## [1.0.16] - 2023/02/20

### CHANGED

- Updates dependencies (https://github.com/lyokato/redlock/pull/37). Thanks to warmwaffles.

## [1.0.15] - 2021/09/03

### CHANGED

- adds formatter
- removes warnings for deprecated supervisor() spec definition

## [1.0.14] - 2021/09/03

### CHANGED

- Bump redix to 1.1.0 (https://github.com/lyokato/redlock/pull/36). Thanks to carrascoacd

## [1.0.13] - 2021/08/21

### CHANGED

- Avoid max.pow to overflow with values >= 1016 (https://github.com/lyokato/redlock/pull/35). Thanks to carrascoacd

## [1.0.12] - 2020/03/14

### CHANGED

- Upgrade redix to 0.10.7 (https://github.com/lyokato/redlock/pull/34). Thanks to carrascoacd

## [1.0.10] - 2019/03/01

### CHANGED

- Fix :milliseconds -> :millisecond (https://github.com/lyokato/redlock/pull/33). Thanks to parallel588

## [1.0.9] - 2019/02/26

### CHANGED

- Fix authentication(https://github.com/lyokato/redlock/pull/32). Thanks to bernardd

## [1.0.8] - 2019/02/25

### CHANGED

- ex_doc 0.15 -> 0.19

## [1.0.7] - 2019/02/25

### CHANGED

- add SSL support(https://github.com/lyokato/redlock/pull/30). Thanks to bernardd

## [1.0.6] - 2018/11/13

### CHANGED

- Dyalyzer and test fixed(https://github.com/lyokato/redlock/pull/29). Thanks to bernardd

## [1.0.5] - 2018/09/21

### CHANGED

- update redix to v0.8.1(https://github.com/lyokato/redlock/pull/28). Thanks to MihailDV.

## [1.0.4] - 2018/09/06

### CHANGED

- adds 'database' config param(https://github.com/lyokato/redlock/pull/26). Thanks to geofflane.
