# Argv

A lightweight, production-ready command-line argument parser for Dart.

## Features

- **Flags & Options** - Boolean flags and value options with validation
- **Commands** - Nested command structures (git-like CLIs)
- **Validation** - Required arguments, allowed values, typo suggestions
- **Simple API** - Fluent, chainable interface

## Quick Start

```dart
import 'package:argv/argv.dart';

void main(List<String> args) {
  final parser = Argv('myapp')
    .flag('verbose', abbr: 'v', description: 'Verbose output')
    .option('output', abbr: 'o', defaultValue: 'result.txt')
    .positional('input');

  final result = parser.run(args);
  
  if (result.flag('verbose')) {
    print('Processing ${result.positional('input')}...');
  }
}
```

## Commands

```dart
final git = Argv('git');

git.command('commit')
  .option('message', abbr: 'm', required: true)
  .flag('all', abbr: 'a')
  .on((result) {
    print('Committing: ${result.option('message')}');
  });

git.run(['commit', '-m', 'Initial commit', '--all']);
```

## Installation

```yaml
dependencies:
  argv: ^1.0.0
```

## Usage Examples

```bash
# Basic usage
myapp --verbose --output result.txt input.txt

# Commands with options  
git commit -m "Fix bug" --all
docker run -d --name myapp nginx:latest

# Validation with suggestions
myapp --verbos  # Error: Unknown argument --verbos. Did you mean --verbose?
```

