import 'package:argv/argv.dart';
import 'dart:io';
import 'dart:math';

void main() {
  print('Starting Production-Ready Argv Test Suite\n');

  final tester = ArgvTester();

  // Core functionality tests
  // tester.runBasicFlagTests();
  // tester.runBasicOptionTests();
  // tester.runPositionalTests();
  // tester.runCommandTests();

  // Critical production requirements
  // tester.runValidationTests();
  // tester.runRequiredArgumentTests();
  tester.runErrorHandlingTests();
  // tester.runUnknownArgumentTests();
  // tester.runInputSanitizationTests();

  // Edge cases and robustness
  // tester.runEdgeCaseTests();
  // tester.runRobustnessTests();
  // tester.runPerformanceTests();

  // Complex real-world scenarios
  // tester.runComplexScenarioTests();
  // tester.runUserExperienceTests();

  tester.printSummary();
}

class ArgvTester {
  int _passed = 0;
  int _failed = 0;
  final List<String> _failedTests = [];

  void test(String name, void Function() testFn) {
    try {
      print('Testing: $name');
      testFn();
      print('PASSED: $name\n');
      _passed++;
    } catch (e) {
      print('FAILED: $name');
      print('   Error: $e\n');
      _failed++;
      _failedTests.add(name);
    }
  }

  void expect(dynamic actual, dynamic expected, [String? message]) {
    if (actual != expected) {
      final msg = message ?? 'Expected $expected, got $actual';
      throw Exception(msg);
    }
  }

  void expectThrows<T extends Exception>(
    void Function() fn, [
    String? message,
  ]) {
    try {
      fn();
      throw Exception(message ?? 'Expected exception to be thrown');
    } catch (e) {
      if (e is! T) {
        throw Exception('Expected ${T.toString()}, got ${e.runtimeType}: $e');
      }
    }
  }

  void runBasicFlagTests() {
    print('=== BASIC FLAG TESTS ===\n');

    test('Single flag parsing', () {
      final parser = Argv('test').flag('verbose', abbr: 'v');

      final result = parser.run(['--verbose']);
      expect(result.flag('verbose'), true);
    });

    test('Short flag parsing', () {
      final parser = Argv('test').flag('verbose', abbr: 'v');

      final result = parser.run(['-v']);
      expect(result.flag('verbose'), true);
    });

    test('Multiple independent flags', () {
      final parser = Argv('test')
          .flag('verbose', abbr: 'v')
          .flag('debug', abbr: 'd')
          .flag('quiet', abbr: 'q');

      final result = parser.run(['-v', '--debug']);
      expect(result.flag('verbose'), true);
      expect(result.flag('debug'), true);
      expect(result.flag('quiet'), false);
    });

    test('Flag defaults are preserved when other flags are set', () {
      final parser = Argv('test')
          .flag('auto', defaultTo: true)
          .flag('manual', defaultTo: false)
          .flag('verbose');

      final result = parser.run(['--verbose']);
      expect(result.flag('verbose'), true);
      expect(result.flag('auto'), true, 'Default true should be preserved');
      expect(result.flag('manual'), false, 'Default false should be preserved');
    });

    test('Flag with default true when not specified', () {
      final parser = Argv('test').flag('auto', defaultTo: true);

      final result = parser.run([]);
      expect(result.flag('auto'), true);
    });

    test('Flag explicitly set overrides default', () {
      final parser = Argv('test').flag('auto', defaultTo: true);

      final result = parser.run(['--auto']);
      expect(result.flag('auto'), true);
    });
  }

  void runBasicOptionTests() {
    print('=== BASIC OPTION TESTS ===\n');

    test('Option with space-separated value', () {
      final parser = Argv('test').option('name');

      final result = parser.run(['--name', 'John']);
      expect(result.option('name'), 'John');
    });

    test('Short option parsing', () {
      final parser = Argv('test').option('name', abbr: 'n');

      final result = parser.run(['-n', 'John']);
      expect(result.option('name'), 'John');
    });

    test('Option with equals-separated value', () {
      final parser = Argv('test').option('name');

      final result = parser.run(['--name=John']);
      expect(result.option('name'), 'John');
    });

    test('Option allowed values validation', () {
      final parser = Argv(
        'test',
      ).option('level', allowed: ['debug', 'info', 'error']);

      final result = parser.run(['--level', 'debug']);
      expect(result.option('level'), 'debug');
    });

    test('Option default values when not specified', () {
      final parser = Argv('test')
          .option('port', defaultValue: '8080')
          .option('host', defaultValue: 'localhost');

      final result = parser.run([]);
      expect(result.option('port'), '8080');
      expect(result.option('host'), 'localhost');
    });

    test('Option explicitly set overrides default', () {
      final parser = Argv('test')
          .option('port', defaultValue: '8080')
          .option('host', defaultValue: 'localhost');

      final result = parser.run(['--port', '3000']);
      expect(result.option('port'), '3000');
      expect(result.option('host'), 'localhost');
    });

    test('Multiple options with mixed defaults and explicit values', () {
      final parser = Argv('test')
          .option('host', defaultValue: 'localhost')
          .option('port', defaultValue: '8080')
          .option('protocol', defaultValue: 'http');

      final result = parser.run(['--port', '3000', '--protocol', 'https']);
      expect(result.option('host'), 'localhost');
      expect(result.option('port'), '3000');
      expect(result.option('protocol'), 'https');
    });
  }

  void runPositionalTests() {
    print('=== POSITIONAL ARGUMENT TESTS ===\n');

    test('Single positional argument', () {
      final parser = Argv('test').positional('file');

      final result = parser.run(['input.txt']);
      expect(result.positional('file'), 'input.txt');
    });

    test('Multiple positional arguments in order', () {
      final parser = Argv(
        'test',
      ).positional('source').positional('destination').positional('format');

      final result = parser.run(['src.txt', 'dst.txt', 'json']);
      expect(result.positional('source'), 'src.txt');
      expect(result.positional('destination'), 'dst.txt');
      expect(result.positional('format'), 'json');
    });

    test('Positional arguments mixed with flags and options', () {
      final parser = Argv('test')
          .flag('force', abbr: 'f')
          .option('output', abbr: 'o')
          .positional('input');

      final result = parser.run(['--force', 'input.txt', '-o', 'output.txt']);
      expect(result.flag('force'), true);
      expect(result.option('output'), 'output.txt');
      expect(result.positional('input'), 'input.txt');
    });

    test('Positional arguments with complex mixing', () {
      final parser = Argv('test')
          .flag('verbose', abbr: 'v')
          .option('format', abbr: 'f')
          .positional('source')
          .positional('dest');

      final result = parser.run([
        'src.txt',
        '-v',
        'dest.txt',
        '--format',
        'json',
      ]);
      expect(result.flag('verbose'), true);
      expect(result.option('format'), 'json');
      expect(result.positional('source'), 'src.txt');
      expect(result.positional('dest'), 'dest.txt');
    });
  }

  void runCommandTests() {
    print('=== COMMAND TESTS ===\n');

    test('Simple command execution', () {
      var executed = false;
      final parser = Argv('git')
        ..command('status').on((result) {
          executed = true;
        });

      parser.run(['status']);
      expect(executed, true);
    });

    test('Command with flags', () {
      var commandExecuted = false;
      final parser = Argv('git');
      parser
        ..command('status').flag('short', abbr: 's')
        ..on((result) {
          commandExecuted = true;
          print('executed');
          expect(result.flag('short'), true);
        });

      parser.run(['status', '--short']);
      expect(commandExecuted, true);
    });

    test('Command with options', () {
      var commandExecuted = false;
      final parser = Argv('git');
      parser.command('commit').option('message', abbr: 'm').on((result) {
        commandExecuted = true;
        expect(result.option('message'), 'Fix bug');
      });

      parser.run(['commit', '-m', 'Fix bug']);
      expect(commandExecuted, true);
    });

    test('Command with positional arguments', () {
      var commandExecuted = false;
      final parser = Argv('cp');
      parser.command('copy').positional('source').positional('dest').on((
        result,
      ) {
        commandExecuted = true;
        expect(result.positional('source'), 'file1.txt');
        expect(result.positional('dest'), 'file2.txt');
      });

      parser.run(['copy', 'file1.txt', 'file2.txt']);
      expect(commandExecuted, true);
    });

    test('Command with mixed arguments', () {
      var commandExecuted = false;
      final parser = Argv('docker');
      parser
          .command('run')
          .flag('detach', abbr: 'd')
          .option('name')
          .positional('image')
          .on((result) {
            commandExecuted = true;
            expect(result.flag('detach'), true);
            expect(result.option('name'), 'my-container');
            expect(result.positional('image'), 'nginx:latest');
          });

      parser.run(['run', '-d', '--name', 'my-container', 'nginx:latest']);
      expect(commandExecuted, true);
    });

    test('Multiple separate commands', () {
      var addExecuted = false;
      var commitExecuted = false;

      // Test add command separately
      final addParser = Argv('git');
      addParser.command('add').flag('all', abbr: 'A').positional('files').on((
        result,
      ) {
        addExecuted = true;
        expect(result.flag('all'), true);
        expect(result.positional('files'), '.');
      });

      addParser.run(['add', '-A', '.']);
      expect(addExecuted, true);

      // Test commit command separately
      final commitParser = Argv('git');
      commitParser
          .command('commit')
          .option('message', abbr: 'm')
          .flag('all', abbr: 'a')
          .on((result) {
            commitExecuted = true;
            expect(result.option('message'), 'Initial commit');
            expect(result.flag('all'), true);
          });

      commitParser.run(['commit', '-m', 'Initial commit', '-a']);
      expect(commitExecuted, true);
    });

    test('Nested commands - two levels', () {
      var executed = false;
      final parser = Argv('docker');
      parser.command('container').command('list').flag('all', abbr: 'a').on((
        result,
      ) {
        executed = true;
        expect(result.flag('all'), true);
      });

      parser.run(['container', 'list', '--all']);
      expect(executed, true);
    });

    test('Nested commands - three levels', () {
      var executed = false;
      final parser = Argv('kubectl');
      parser
          .command('get')
          .command('pods')
          .command('logs')
          .flag('follow', abbr: 'f')
          .positional('pod-name')
          .on((result) {
            executed = true;
            expect(result.flag('follow'), true, 'flag follow');
            expect(
              result.positional('pod-name'),
              'my-pod',
              'positional parameter',
            );
          });

      parser.run(['get', 'pods', 'logs', '-f', 'my-pod']);
      expect(executed, true, 'executed callback');
    });

    test('Commands with same flag names in different contexts', () {
      var buildExecuted = false;
      var testExecuted = false;

      // Build command with 'all' flag
      final buildParser = Argv('tool');
      buildParser.command('build').flag('all', abbr: 'a').on((result) {
        buildExecuted = true;
        expect(result.flag('all'), true);
      });

      buildParser.run(['build', '--all']);
      expect(buildExecuted, true);

      // Test command with different 'all' flag
      final testParser = Argv('tool');
      testParser.command('test').flag('all', abbr: 'a').on((result) {
        testExecuted = true;
        expect(result.flag('all'), true);
      });

      testParser.run(['test', '-a']);
      expect(testExecuted, true);
    });
  }

  void runValidationTests() {
    print('=== VALIDATION TESTS ===\n');

    test('Duplicate flag names rejected', () {
      expectThrows<ArgvException>(() {
        Argv('test').flag('verbose').flag('verbose');
      });
    });

    test('Duplicate option names rejected', () {
      expectThrows<ArgvException>(() {
        Argv('test').option('name').option('name');
      });
    });

    test('Duplicate command names rejected', () {
      expectThrows<ArgvException>(() {
        Argv('test')
          ..command('build')
          ..command('build');
      });
    });

    test('Duplicate abbreviations across flags rejected', () {
      expectThrows<ArgvException>(() {
        Argv('test').flag('verbose', abbr: 'v').flag('version', abbr: 'v');
      });
    });

    test('Duplicate abbreviations across options rejected', () {
      expectThrows<ArgvException>(() {
        Argv('test').option('name', abbr: 'n').option('number', abbr: 'n');
      });
    });

    test('Duplicate abbreviations between flags and options rejected', () {
      expectThrows<ArgvException>(() {
        Argv('test').flag('verbose', abbr: 'v').option('version', abbr: 'v');
      });
    });

    test('Invalid option values rejected', () {
      final parser = Argv(
        'test',
      ).option('level', allowed: ['debug', 'info', 'error']);

      expectThrows<ArgvException>(() {
        parser.run(['--level', 'invalid']);
      });
    });

    test('Empty argument names rejected', () {
      expectThrows<ArgvException>(() {
        Argv('test').flag('');
      });
    });

    test('Invalid argument names with special characters rejected', () {
      expectThrows<ArgvException>(() {
        Argv('test').flag('invalid@name');
      });
    });

    test('Invalid abbreviations (not single character) rejected', () {
      expectThrows<ArgvException>(() {
        Argv('test').flag('verbose', abbr: 'abc');
      });
    });

    test('Valid argument names with allowed characters accepted', () {
      final parser = Argv('test')
          .flag('valid-name')
          .flag('valid_name2')
          .option('option-1')
          .option('option_2');

      // Should not throw
      final result = parser.run(['--valid-name', '--option-1', 'value']);
      expect(result.flag('valid-name'), true);
      expect(result.option('option-1'), 'value');
    });
  }

  void runRequiredArgumentTests() {
    print('=== REQUIRED ARGUMENT TESTS ===\n');

    test('Required flag validation when missing', () {
      final parser = Argv('test').flag('accept', required: true);

      expectThrows<ArgvException>(() {
        parser.run([]);
      }, 'Required flag not provided should throw');
    });

    test('Required flag validation when provided', () {
      final parser = Argv('test').flag('accept', required: true);

      final result = parser.run(['--accept']);
      expect(result.flag('accept'), true);
    });

    test('Required option validation when missing', () {
      final parser = Argv('test').option('name', required: true);

      expectThrows<ArgvException>(() {
        parser.run([]);
      }, 'Required option not provided should throw');
    });

    test('Required option validation when provided', () {
      final parser = Argv('test').option('name', required: true);

      final result = parser.run(['--name', 'John']);
      expect(result.option('name'), 'John');
    });

    test('Required positional validation when missing', () {
      final parser = Argv('test').positional('file');

      expectThrows<ArgvException>(() {
        parser.run([]);
      }, 'Missing positional argument should throw');
    });

    test('Required positional validation when provided', () {
      final parser = Argv('test').positional('file');

      final result = parser.run(['input.txt']);
      expect(result.positional('file'), 'input.txt');
    });

    test('Multiple required arguments validation', () {
      final parser = Argv('test')
          .flag('accept', required: true)
          .option('name', required: true)
          .positional('file');

      final result = parser.run(['--accept', '--name', 'John', 'input.txt']);
      expect(result.flag('accept'), true);
      expect(result.option('name'), 'John');
      expect(result.positional('file'), 'input.txt');
    });

    test('Mix of required and optional arguments', () {
      final parser = Argv('test')
          .flag('required-flag', required: true)
          .flag('optional-flag', required: false)
          .option('required-opt', required: true)
          .option('optional-opt', required: false, defaultValue: 'default');

      final result = parser.run(['--required-flag', '--required-opt', 'value']);
      expect(result.flag('required-flag'), true);
      expect(result.flag('optional-flag'), false);
      expect(result.option('required-opt'), 'value');
      expect(result.option('optional-opt'), 'default');
    });
  }

  void runErrorHandlingTests() {
    print('=== ERROR HANDLING TESTS ===\n');

    test('Option missing value throws descriptive error', () {
      final parser = Argv('test').option('name');

      expectThrows<ArgvException>(() {
        parser.run(['--name']);
      });
    });

    test('Too many positional arguments throws error', () {
      final parser = Argv('test').positional('file');

      expectThrows<ArgvException>(() {
        parser.run(['file1.txt', 'file2.txt']);
      });
    });

    test('Malformed equals syntax throws error', () {
      final parser = Argv('test').option('config');

      expectThrows<ArgvException>(() {
        parser.run(['--config=val=ue=invalid']);
      });
    });

    test('Error messages contain relevant information', () {
      final parser = Argv('test').option('level', allowed: ['debug', 'info']);

      try {
        parser.run(['--level', 'invalid']);
        throw Exception('Should have thrown');
      } catch (e) {
        expect(e.toString().contains('not allowed'), true);
        expect(e.toString().contains('level'), true);
        expect(e.toString().contains('invalid'), true);
      }
    });

    test('Option without value at end of arguments', () {
      final parser = Argv('test').option('output').positional('input');

      expectThrows<ArgvException>(() {
        parser.run(['input.txt', '--output']);
      });
    });

    test('Short option without value', () {
      final parser = Argv('test').option('name', abbr: 'n');

      expectThrows<ArgvException>(() {
        parser.run(['-n']);
      });
    });
  }

  void runUnknownArgumentTests() {
    print('=== UNKNOWN ARGUMENT HANDLING ===\n');

    test('Unknown long flag throws error', () {
      final parser = Argv('test').flag('verbose');

      expectThrows<ArgvException>(() {
        parser.run(['--unknown']);
      }, 'Unknown arguments should be rejected');
    });

    test('Unknown short flag throws error', () {
      final parser = Argv('test').flag('verbose', abbr: 'v');

      expectThrows<ArgvException>(() {
        parser.run(['-x']);
      }, 'Unknown short flags should be rejected');
    });

    test('Unknown option throws error', () {
      final parser = Argv('test').option('name');

      expectThrows<ArgvException>(() {
        parser.run(['--unknown', 'value']);
      }, 'Unknown options should be rejected');
    });

    test('Unknown command throws error', () {
      final parser = Argv('test').command('build');

      expectThrows<ArgvException>(() {
        parser.run(['unknown-command']);
      }, 'Unknown commands should be rejected');
    });

    test('Typo suggestions in error messages for flags', () {
      final parser = Argv('test').flag('verbose').flag('version');

      try {
        parser.run(['--verbos']); // Typo
        throw Exception('Should have thrown');
      } catch (e) {
        // Should suggest 'verbose' as a close match
        expect(e.toString().toLowerCase().contains('verbose'), true);
      }
    });

    test('Typo suggestions in error messages for options', () {
      final parser = Argv('test').option('output').option('format');

      try {
        parser.run(['--outpu', 'value']); // Typo
        throw Exception('Should have thrown');
      } catch (e) {
        // Should suggest 'output' as a close match
        expect(e.toString().toLowerCase().contains('output'), true);
      }
    });

    test('Multiple similar options suggest closest match', () {
      final parser = Argv(
        'test',
      ).option('verbose').option('version').option('verify');

      try {
        parser.run(['--ver', 'value']); // Ambiguous typo
        throw Exception('Should have thrown');
      } catch (e) {
        // Should suggest one of the ver* options
        final errorMsg = e.toString().toLowerCase();
        expect(
          errorMsg.contains('verbose') ||
              errorMsg.contains('version') ||
              errorMsg.contains('verify'),
          true,
        );
      }
    });
  }

  void runInputSanitizationTests() {
    print('=== INPUT SANITIZATION TESTS ===\n');

    test('Unicode characters in values preserved', () {
      final parser = Argv('test').option('message').positional('file');

      final result = parser.run(['--message', '🚀 Hello, 世界!', 'файл.txt']);
      expect(result.option('message'), '🚀 Hello, 世界!');
      expect(result.positional('file'), 'файл.txt');
    });

    test('Very long argument values handled', () {
      final parser = Argv('test').option('data');

      final longValue = 'x' * 10000;
      final result = parser.run(['--data', longValue]);
      expect(result.option('data'), longValue);
    });

    test('Special shell characters in values preserved', () {
      final parser = Argv('test').option('command').positional('pattern');

      final result = parser.run(['--command', 'rm -rf /', '*.txt']);
      expect(result.option('command'), 'rm -rf /');
      expect(result.positional('pattern'), '*.txt');
    });

    test('Null bytes and control characters preserved', () {
      final parser = Argv('test').option('data');

      final result = parser.run(['--data', 'hello\x00world\x01\x02']);
      expect(result.option('data'), 'hello\x00world\x01\x02');
    });

    test('Empty string values are preserved', () {
      final parser = Argv('test').option('empty').positional('file');

      final result = parser.run(['--empty=', '']);
      expect(result.option('empty'), '');
      expect(result.positional('file'), '');
    });

    test('Whitespace-only values preserved', () {
      final parser = Argv('test').option('spaces').option('tabs');

      final result = parser.run(['--spaces', '   ', '--tabs', '\t\t\t']);
      expect(result.option('spaces'), '   ');
      expect(result.option('tabs'), '\t\t\t');
    });

    test('Newlines and carriage returns preserved', () {
      final parser = Argv('test').option('multiline');

      final result = parser.run(['--multiline', 'line1\nline2\r\nline3']);
      expect(result.option('multiline'), 'line1\nline2\r\nline3');
    });
  }

  void runEdgeCaseTests() {
    print('=== EDGE CASE TESTS ===\n');

    test('Arguments that look like flags/options as values', () {
      final parser = Argv('test').option('prefix').positional('file');

      final result = parser.run(['--prefix', '--not-a-flag', '-not-an-option']);
      expect(result.option('prefix'), '--not-a-flag');
      expect(result.positional('file'), '-not-an-option');
    });

    test('Single and double dashes as values', () {
      final parser = Argv('test').option('separator').positional('file');

      final result = parser.run(['--separator', '--', '-']);
      expect(result.option('separator'), '--');
      expect(result.positional('file'), '-');
    });

    test('Empty equals assignment', () {
      final parser = Argv('test').option('empty');

      final result = parser.run(['--empty=']);
      expect(result.option('empty'), '');
    });

    test('Equals in option value', () {
      final parser = Argv('test').option('equation');

      final result = parser.run(['--equation=x=y+z']);
      expect(result.option('equation'), 'x=y+z');
    });

    test('Mixed argument order handling', () {
      final parser = Argv('test')
          .flag('verbose', abbr: 'v')
          .option('output', abbr: 'o')
          .positional('input')
          .positional('format');

      final result = parser.run([
        'input.txt',
        '-v',
        'json',
        '--output',
        'out.txt',
      ]);
      expect(result.flag('verbose'), true);
      expect(result.option('output'), 'out.txt');
      expect(result.positional('input'), 'input.txt');
      expect(result.positional('format'), 'json');
    });

    test('Numeric values and edge numbers', () {
      final parser = Argv(
        'test',
      ).option('port').option('weight').positional('count');

      final result = parser.run(['--port', '0', '--weight', '-1.5', '999999']);
      expect(result.option('port'), '0');
      expect(result.option('weight'), '-1.5');
      expect(result.positional('count'), '999999');
    });

    test('Boolean-like strings as option values', () {
      final parser = Argv('test').option('enabled').option('debug');

      final result = parser.run(['--enabled', 'true', '--debug', 'false']);
      expect(result.option('enabled'), 'true');
      expect(result.option('debug'), 'false');
    });

    test('Paths with spaces and special characters', () {
      final parser = Argv('test').option('config').positional('output');

      final result = parser.run([
        '--config',
        '/path/to/my config.json',
        '/output/file name.txt',
      ]);
      expect(result.option('config'), '/path/to/my config.json');
      expect(result.positional('output'), '/output/file name.txt');
    });
  }

  void runRobustnessTests() {
    print('=== ROBUSTNESS TESTS ===\n');

    test('Fuzzing with random valid arguments', () {
      final parser = Argv('test')
          .flag('flag1', abbr: 'a')
          .flag('flag2', abbr: 'b')
          .option('opt1', abbr: 'x')
          .option('opt2', abbr: 'y')
          .positional('pos1')
          .positional('pos2');

      final random = Random(42); // Fixed seed for reproducibility

      for (int i = 0; i < 100; i++) {
        final args = <String>[];

        // Add random flags
        if (random.nextBool()) args.add('--flag1');
        if (random.nextBool()) args.add('-b');

        // Add random options
        if (random.nextBool()) {
          args.addAll(['--opt1', 'value${random.nextInt(100)}']);
        }
        if (random.nextBool()) {
          args.addAll(['-y', 'data${random.nextInt(100)}']);
        }

        // Add positionals
        args.add('pos1_${random.nextInt(100)}');
        args.add('pos2_${random.nextInt(100)}');

        // Should not throw
        final result = parser.run(args);
        expect(result.positional('pos1')?.startsWith('pos1_'), true);
      }
    });

    test('Deeply nested command structure', () {
      var executed = false;

      // Create parser with 10 levels of nesting
      final parser = Argv('root');
      parser
          .command('level0')
          .command('level1')
          .command('level2')
          .command('level3')
          .command('level4')
          .command('level5')
          .command('level6')
          .command('level7')
          .command('level8')
          .command('level9')
          .flag('deep')
          .on((result) {
            executed = true;
            expect(result.flag('deep'), true);
          });

      final args = [
        'level0',
        'level1',
        'level2',
        'level3',
        'level4',
        'level5',
        'level6',
        'level7',
        'level8',
        'level9',
        '--deep',
      ];

      parser.run(args);
      expect(executed, true);
    });

    test('Large number of arguments', () {
      final parser = Argv('test');

      // Add 100 flags and options
      for (int i = 0; i < 100; i++) {
        parser.flag('flag$i');
        parser.option('opt$i', defaultValue: 'default$i');
      }

      // Add 20 positionals
      for (int i = 0; i < 20; i++) {
        parser.positional('pos$i');
      }

      final args = <String>[];
      // Set every 5th flag
      for (int i = 0; i < 100; i += 5) {
        args.add('--flag$i');
      }
      // Set every 7th option
      for (int i = 0; i < 100; i += 7) {
        args.addAll(['--opt$i', 'value$i']);
      }
      // Add all positionals
      for (int i = 0; i < 20; i++) {
        args.add('positional$i');
      }

      final result = parser.run(args);

      // Verify some results
      expect(result.flag('flag0'), true);
      expect(result.flag('flag1'), false);
      expect(result.option('opt0'), 'value0');
      expect(result.option('opt1'), 'default1');
      expect(result.positional('pos0'), 'positional0');
    });

    test('Stress test with random argument combinations', () {
      final parser = Argv('stress')
          .flag('flag-a', abbr: 'a')
          .flag('flag-b', abbr: 'b')
          .flag('flag-c', abbr: 'c')
          .option('opt-x', abbr: 'x', defaultValue: 'default-x')
          .option('opt-y', abbr: 'y', defaultValue: 'default-y')
          .option('opt-z', abbr: 'z', defaultValue: 'default-z')
          .positional('pos1')
          .positional('pos2')
          .positional('pos3');

      final random = Random(123);

      for (int iteration = 0; iteration < 50; iteration++) {
        final args = <String>[];
        final expectedFlags = <String, bool>{};
        final expectedOptions = <String, String>{};

        // Randomly add flags
        for (final flag in ['flag-a', 'flag-b', 'flag-c']) {
          if (random.nextBool()) {
            args.add('--$flag');
            expectedFlags[flag] = true;
          } else {
            expectedFlags[flag] = false;
          }
        }

        // Randomly add options
        for (final opt in ['opt-x', 'opt-y', 'opt-z']) {
          if (random.nextBool()) {
            final value = 'value-$iteration-$opt';
            args.addAll(['--$opt', value]);
            expectedOptions[opt] = value;
          } else {
            expectedOptions[opt] = 'default-$opt';
          }
        }

        // Add positionals
        final pos1 = 'pos1-$iteration';
        final pos2 = 'pos2-$iteration';
        final pos3 = 'pos3-$iteration';
        args.addAll([pos1, pos2, pos3]);

        final result = parser.run(args);

        // Verify all expectations
        for (final entry in expectedFlags.entries) {
          expect(
            result.flag(entry.key),
            entry.value,
            'Iteration $iteration: ${entry.key} should be ${entry.value}',
          );
        }

        for (final entry in expectedOptions.entries) {
          expect(
            result.option(entry.key),
            entry.value,
            'Iteration $iteration: ${entry.key} should be ${entry.value}',
          );
        }

        expect(result.positional('pos1'), pos1);
        expect(result.positional('pos2'), pos2);
        expect(result.positional('pos3'), pos3);
      }
    });
  }

  void runPerformanceTests() {
    print('=== PERFORMANCE TESTS ===\n');

    test('Performance with many arguments', () {
      final parser = Argv('perf-test');

      for (int i = 0; i < 1000; i++) {
        parser.flag('flag$i');
        parser.option('opt$i');
      }

      final args = <String>[];
      for (int i = 0; i < 500; i++) {
        args.add('--flag$i');
      }
      for (int i = 500; i < 1000; i++) {
        args.addAll(['--opt$i', 'value$i']);
      }

      final stopwatch = Stopwatch()..start();
      parser.run(args);
      stopwatch.stop();

      // Should complete in reasonable time (< 100ms on most systems)
      expect(
        stopwatch.elapsedMilliseconds < 100,
        true,
        'Performance test took ${stopwatch.elapsedMilliseconds}ms',
      );
    });

    test('Memory usage with large inputs', () {
      final parser = Argv('memory-test');

      for (int i = 0; i < 100; i++) {
        parser.option('opt$i');
      }

      // Create large argument values
      final largeValue = 'x' * 1000;
      final args = <String>[];
      for (int i = 0; i < 100; i++) {
        args.addAll(['--opt$i', '$largeValue$i']);
      }

      final result = parser.run(args);

      // Verify results are stored correctly
      for (int i = 0; i < 100; i++) {
        expect(result.option('opt$i'), '$largeValue$i');
      }
    });

    test('Repeated parsing performance', () {
      final parser = Argv('repeat-test')
          .flag('verbose', abbr: 'v')
          .option('output', abbr: 'o')
          .positional('input');

      final args = ['-v', '--output', 'out.txt', 'input.txt'];

      final stopwatch = Stopwatch()..start();

      // Parse the same arguments 1000 times
      for (int i = 0; i < 1000; i++) {
        final result = parser.run(args);
        expect(result.flag('verbose'), true);
        expect(result.option('output'), 'out.txt');
        expect(result.positional('input'), 'input.txt');
      }

      stopwatch.stop();

      // Should complete 1000 parses in reasonable time
      expect(
        stopwatch.elapsedMilliseconds < 500,
        true,
        'Repeated parsing took ${stopwatch.elapsedMilliseconds}ms',
      );
    });
  }

  void runComplexScenarioTests() {
    print('=== COMPLEX SCENARIO TESTS ===\n');

    test('Git-like command structure simulation', () {
      var addExecuted = false;
      var commitExecuted = false;
      var pushExecuted = false;

      // Simulate git add command
      final gitAdd = Argv('git');
      gitAdd
          .command('add')
          .flag('all', abbr: 'A', description: 'Add all files')
          .flag('interactive', abbr: 'i', description: 'Interactive mode')
          .positional('files')
          .on((result) {
            addExecuted = true;
            expect(result.flag('all'), true);
            expect(result.flag('interactive'), false);
            expect(result.positional('files'), '.');
          });

      gitAdd.run(['add', '-A', '.']);
      expect(addExecuted, true);

      // Simulate git commit command
      final gitCommit = Argv('git');
      gitCommit
          .command('commit')
          .option(
            'message',
            abbr: 'm',
            required: true,
            description: 'Commit message',
          )
          .flag('all', abbr: 'a', description: 'Commit all changes')
          .flag('amend', description: 'Amend previous commit')
          .on((result) {
            commitExecuted = true;
            expect(result.option('message'), 'Initial commit');
            expect(result.flag('all'), true);
            expect(result.flag('amend'), false);
          });

      gitCommit.run(['commit', '-m', 'Initial commit', '-a']);
      expect(commitExecuted, true);

      // Simulate git push command
      final gitPush = Argv('git');
      gitPush
          .command('push')
          .flag('force', abbr: 'f', description: 'Force push')
          .flag('set-upstream', abbr: 'u', description: 'Set upstream')
          .positional('remote')
          .positional('branch')
          .on((result) {
            pushExecuted = true;
            expect(result.flag('force'), false);
            expect(result.flag('set-upstream'), true);
            expect(result.positional('remote'), 'origin');
            expect(result.positional('branch'), 'main');
          });

      gitPush.run(['push', '-u', 'origin', 'main']);
      expect(pushExecuted, true);
    });

    test('Docker-like complex command structure', () {
      var runExecuted = false;
      var buildExecuted = false;

      // Simulate docker run
      final dockerRun = Argv('docker');
      dockerRun
          .command('run')
          .flag('detach', abbr: 'd', description: 'Run in background')
          .flag('interactive', abbr: 'i', description: 'Interactive mode')
          .flag('tty', abbr: 't', description: 'Allocate TTY')
          .option('name', description: 'Container name')
          .option('port', abbr: 'p', description: 'Port mapping')
          .option('volume', abbr: 'v', description: 'Volume mapping')
          .positional('image')
          .positional('command')
          .on((result) {
            runExecuted = true;
            expect(result.flag('detach'), true);
            expect(result.flag('interactive'), false);
            expect(result.flag('tty'), false);
            expect(result.option('name'), 'my-app');
            expect(result.option('port'), '8080:80');
            expect(result.option('volume'), '/host:/container');
            expect(result.positional('image'), 'nginx:latest');
            expect(result.positional('command'), 'bash');
          });

      dockerRun.run([
        'run',
        '-d',
        '--name',
        'my-app',
        '-p',
        '8080:80',
        '-v',
        '/host:/container',
        'nginx:latest',
        'bash',
      ]);
      expect(runExecuted, true);

      // Simulate docker build
      final dockerBuild = Argv('docker');
      dockerBuild
          .command('build')
          .flag('no-cache', description: 'Do not use cache')
          .option('tag', abbr: 't', description: 'Tag for the image')
          .option('file', abbr: 'f', description: 'Dockerfile path')
          .positional('context')
          .on((result) {
            buildExecuted = true;
            expect(result.flag('no-cache'), true);
            expect(result.option('tag'), 'myapp:latest');
            expect(result.option('file'), 'Dockerfile.prod');
            expect(result.positional('context'), '.');
          });

      dockerBuild.run([
        'build',
        '--no-cache',
        '-t',
        'myapp:latest',
        '-f',
        'Dockerfile.prod',
        '.',
      ]);
      expect(buildExecuted, true);
    });

    test('CLI tool with complex validation', () {
      var executed = false;

      final parser = Argv('deploy-tool');
      parser
          .option(
            'environment',
            abbr: 'e',
            required: true,
            allowed: ['dev', 'staging', 'production'],
            description: 'Deployment environment',
          )
          .option(
            'config',
            abbr: 'c',
            defaultValue: 'config.json',
            description: 'Configuration file',
          )
          .flag('dry-run', description: 'Show what would be deployed')
          .flag('force', abbr: 'f', description: 'Force deployment')
          .flag('verbose', abbr: 'v', description: 'Verbose output')
          .positional('version')
          .on((result) {
            executed = true;
            expect(result.option('environment'), 'staging');
            expect(result.option('config'), 'staging.json');
            expect(result.flag('dry-run'), false);
            expect(result.flag('force'), true);
            expect(result.flag('verbose'), true);
            expect(result.positional('version'), 'v1.2.3');
          });

      parser.run([
        '-e',
        'staging',
        '--config',
        'staging.json',
        '--force',
        '-v',
        'v1.2.3',
      ]);
      expect(executed, true);
    });
    //
    //   test('Multi-level command with shared options', () {
    //     var listExecuted = false;
    //     var createExecuted = false;
    //     var deleteExecuted = false;
    //
    //     // Simulate kubectl get pods
    //     final kubectlGetPods = Argv('kubectl');
    //     kubectlGetPods.command('get')
    //         .command('pods')
    //         .flag('all-namespaces', abbr: 'A')
    //         .option('namespace', abbr: 'n', defaultValue: 'default')
    //         .option('output', abbr: 'o', allowed: ['json', 'yaml', 'wide'])
    //         .on((result) {
    //           listExecuted = true;
    //           expect(result.flag('all-namespaces'), true);
    //           expect(result.option('namespace'), 'kube-system');
    //           expect(result.option('output'), 'wide');
    //         });
    //
    //     kubectlGetPods.run(['get', 'pods', '-A', '-n', 'kube-system', '-o', 'wide']);
    //     expect(listExecuted, true);
    //
    //     // Simulate kubectl create deployment
    //     final kubectlCreate = Argv('kubectl');
    //     kubectlCreate.command('create')
    //         .command('deployment')
    //         .option('image', required: true)
    //         .option('replicas', defaultValue: '1')
    //         .positional('name')
    //         .on((result) {
    //           createExecuted = true;
    //           expect(result.option('image'), 'nginx:latest');
    //           expect(result.option('replicas'), '3');
    //           expect(result.positional('name'), 'my-deployment');
    //         });
    //
    //     kubectlCreate.run(['create', 'deployment', 'my-deployment',
    //                        '--image', 'nginx:latest', '--replicas', '3']);
    //     expect(createExecuted, true);
    //
    //     // Simulate kubectl delete pod
    //     final kubectlDelete = Argv('kubectl');
    //     kubectlDelete.command('delete')
    //         .command('pod')
    //         .flag('force', description: 'Force deletion')
    //         .option('grace-period', defaultValue: '30')
    //         .positional('pod-name')
    //         .on((result) {
    //           deleteExecuted = true;
    //           expect(result.flag('force'), true);
    //           expect(result.option('grace-period'), '0');
    //           expect(result.positional('pod-name'), 'my-pod-123');
    //         });
    //
    //     kubectlDelete.run(['delete', 'pod', 'my-pod-123',
    //                        '--force', '--grace-period', '0']);
    //     expect(deleteExecuted, true);
    //   });default')
    //         .option('output', abbr: 'o', allowed: ['json', 'yaml', 'wide'])
    //         .on((result) {
    //           listExecuted = true;
    //           expect(result.flag('all-namespaces'), true);
    //           expect(result.option('namespace'), 'kube-system');
    //           expect(result.option('output'), 'wide');
    //         });
    //
    //     kubectlGetPods.run(['get', 'pods', '-A', '-n', 'kube-system', '-o', 'wide']);
    //     expect(listExecuted, true);
    //
    //     // Simulate kubectl create deployment
    //     final kubectlCreate = Argv('kubectl')
    //         .command('create')
    //         .command('deployment')
    //         .option('image', required: true)
    //         .option('replicas', defaultValue: '1')
    //         .positional('name')
    //         .on((result) {
    //           createExecuted = true;
    //           expect(result.option('image'), 'nginx:latest');
    //           expect(result.option('replicas'), '3');
    //           expect(result.positional('name'), 'my-deployment');
    //         });
    //
    //     kubectlCreate.run(['create', 'deployment', 'my-deployment',
    //                        '--image', 'nginx:latest', '--replicas', '3']);
    //     expect(createExecuted, true);
    //
    //     // Simulate kubectl delete pod
    //     final kubectlDelete = Argv('kubectl')
    //         .command('delete')
    //         .command('pod')
    //         .flag('force', description: 'Force deletion')
    //         .option('grace-period', defaultValue: '30')
    //         .positional('pod-name')
    //         .on((result) {
    //           deleteExecuted = true;
    //           expect(result.flag('force'), true);
    //           expect(result.option('grace-period'), '0');
    //           expect(result.positional('pod-name'), 'my-pod-123');
    //         });
    //
    //     kubectlDelete.run(['delete', 'pod', 'my-pod-123',
    //                        '--force', '--grace-period', '0']);
    //     expect(deleteExecuted, true);
    //   });
  }

  //
  void runUserExperienceTests() {
    print('=== USER EXPERIENCE TESTS ===\n');

    test('Helpful error messages for argument typos', () {
      final parser = Argv('test')
          .flag('verbose')
          .flag('version')
          .flag('validate')
          .option('output')
          .option('format')
          .option('config');

      final testCases = [
        ('--verbos', 'verbose'),
        ('--versio', 'version'),
        ('--validat', 'validate'),
        ('--outpu', 'output'),
        ('--forma', 'format'),
        ('--confi', 'config'),
      ];

      for (final (typo, correct) in testCases) {
        try {
          parser.run([typo]);
          throw Exception('Should have thrown for $typo');
        } catch (e) {
          expect(
            e.toString().toLowerCase().contains(correct),
            true,
            'Error for $typo should suggest $correct',
          );
        }
      }
    });

    test('Consistent behavior across argument forms', () {
      final parser = Argv('test')
          .flag('flag1', abbr: 'a')
          .flag('flag2', abbr: 'b')
          .option('opt1', abbr: 'x')
          .option('opt2', abbr: 'y');

      // Test that all forms work consistently
      final testCases = [
        (
          ['--flag1', '-b', '--opt1', 'val1', '-y', 'val2'],
          {'flag1': true, 'flag2': true, 'opt1': 'val1', 'opt2': 'val2'},
        ),
        (
          ['-a', '--flag2', '-x', 'val1', '--opt2', 'val2'],
          {'flag1': true, 'flag2': true, 'opt1': 'val1', 'opt2': 'val2'},
        ),
        (
          ['--opt1=val1', '--opt2=val2', '--flag1', '--flag2'],
          {'flag1': true, 'flag2': true, 'opt1': 'val1', 'opt2': 'val2'},
        ),
      ];

      for (final (args, expected) in testCases) {
        final result = parser.run(args);
        for (final entry in expected.entries) {
          final name = entry.key;
          final value = entry.value;
          if (value is bool) {
            expect(result.flag(name), value, 'Failed for args: $args');
          } else {
            expect(result.option(name), value, 'Failed for args: $args');
          }
        }
      }
    });

    test('Graceful handling of edge input patterns', () {
      final parser = Argv(
        'test',
      ).option('config').option('message').positional('file');

      // Test various edge cases that users might accidentally create
      final edgeCases = [
        (['--config='], '', null), // Empty value with equals
        (
          ['--config', '--', 'file.txt'],
          '--',
          'file.txt',
        ), // Double dash as value
        (
          ['--message', '', 'input.txt'],
          '',
          'input.txt',
        ), // Explicit empty string
      ];

      for (final c in edgeCases) {
        final args = c.$1;
        final expectedConfig = c.$2;
        final expectedFile = c.$3;

        final result = parser.run(args);
        expect(result.option('config'), expectedConfig);
        if (expectedFile != null) {
          expect(result.positional('file'), expectedFile);
        }
      }
    });

    test('Robust validation with clear error context', () {
      final parser = Argv('test')
          .option(
            'level',
            required: true,
            allowed: ['debug', 'info', 'warn', 'error'],
          )
          .flag('confirm', required: true)
          .positional('input-file');

      // Test missing required arguments
      try {
        parser.run(['input.txt']);
        throw Exception('Should have failed validation');
      } catch (e) {
        final errorMsg = e.toString().toLowerCase();
        expect(errorMsg.contains('required'), true);
        // Should mention which required arguments are missing
        expect(
          errorMsg.contains('level') || errorMsg.contains('confirm'),
          true,
        );
      }

      // Test invalid allowed value with suggestions
      try {
        parser.run(['--level', 'invalid', '--confirm', 'input.txt']);
        throw Exception('Should have failed validation');
      } catch (e) {
        final errorMsg = e.toString();
        expect(errorMsg.contains('not allowed'), true);
        // Should suggest valid options
        expect(
          errorMsg.contains('debug') ||
              errorMsg.contains('info') ||
              errorMsg.contains('warn') ||
              errorMsg.contains('error'),
          true,
        );
      }
    });

    test('Argument parsing order independence', () {
      final parser = Argv('test')
          .flag('verbose', abbr: 'v')
          .option('output', abbr: 'o')
          .option('format', abbr: 'f')
          .positional('input')
          .positional('target');

      // Same arguments in different orders should produce same result
      final expectedFlags = {'verbose': true};
      final expectedOptions = {'output': 'out.txt', 'format': 'json'};
      final expectedPositionals = {
        'input': 'input.txt',
        'target': 'target.txt',
      };

      final argVariations = [
        ['-v', '-o', 'out.txt', '-f', 'json', 'input.txt', 'target.txt'],
        [
          'input.txt',
          '-v',
          'target.txt',
          '--output',
          'out.txt',
          '--format',
          'json',
        ],
        [
          '--output',
          'out.txt',
          'input.txt',
          '--verbose',
          '--format',
          'json',
          'target.txt',
        ],
        ['-o', 'out.txt', '-f', 'json', '-v', 'input.txt', 'target.txt'],
      ];

      for (final args in argVariations) {
        final result = parser.run(args);

        for (final entry in expectedFlags.entries) {
          expect(
            result.flag(entry.key),
            entry.value,
            'Flag ${entry.key} failed for args: $args',
          );
        }

        for (final entry in expectedOptions.entries) {
          expect(
            result.option(entry.key),
            entry.value,
            'Option ${entry.key} failed for args: $args',
          );
        }

        for (final entry in expectedPositionals.entries) {
          expect(
            result.positional(entry.key),
            entry.value,
            'Positional ${entry.key} failed for args: $args',
          );
        }
      }
    });
  }

  void printSummary() {
    print('=== PRODUCTION READINESS TEST SUMMARY ===');
    print('Total tests: ${_passed + _failed}');
    print('Passed: $_passed');
    print('Failed: $_failed');

    if (_failed > 0) {
      print('\n❌ NOT PRODUCTION READY');
      print('\nFailed tests:');
      for (final test in _failedTests) {
        print('  - $test');
      }
      print('\nFix these issues to achieve production readiness.');
      exit(1);
    } else {
      print('\n PRODUCTION READY!');
    }
  }
}
