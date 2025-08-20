import 'package:argv/argv.dart';

void main() {
  basicExample();
  commandExample();
  errorExample();
}

void basicExample() {
  print('=== BASIC EXAMPLE ===');

  final parser = Argv('myapp')
      .flag('verbose', abbr: 'v')
      .option('output', abbr: 'o', defaultValue: 'result.txt')
      .positional('input');

  final result = parser.run(['-v', '--output', 'out.txt', 'input.txt']);

  print('verbose: ${result.flag('verbose')}');
  print('output: ${result.option('output')}');
  print('input: ${result.positional('input')}\n');
}

void commandExample() {
  print('=== COMMAND EXAMPLE ===');

  final git = Argv('git');

  git
      .command('commit')
      .option('message', abbr: 'm', required: true)
      .flag('all', abbr: 'a')
      .on((result) {
        print('Committing with message: ${result.option('message')}');
        print('Stage all: ${result.flag('all')}');
      });

  git.command('push').flag('force', abbr: 'f').positional('remote').on((
    result,
  ) {
    print('Pushing to: ${result.positional('remote')}');
    print('Force: ${result.flag('force')}');
  });

  git.run(['commit', '-m', 'Initial commit', '--all']);
  git.run(['push', 'origin']);
  print('');
}

void errorExample() {
  print('=== ERROR HANDLING ===');

  final parser = Argv('test')
      .option('level', allowed: ['debug', 'info', 'error'])
      .flag('confirm', required: true);

  try {
    parser.run(['--level', 'invalid']);
  } catch (e) {
    print('Invalid value: $e');
  }

  try {
    parser.run(['--level', 'debug']);
  } catch (e) {
    print('Missing required: $e');
  }

  try {
    parser.run(['--unknown']);
  } catch (e) {
    print('Unknown argument: $e');
  }
}
