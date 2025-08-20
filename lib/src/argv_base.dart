import 'dart:math';

/// Callback function that will be attached on a command
typedef ArgvCallback = void Function(ArgvResult);

sealed class _Argument {
  _Argument(
    this.name, {
    this.abbr,
    this.help,
    this.description,
    this.required = false,
  });
  final String name;
  final String? abbr;
  final String? help;
  final String? description;
  final bool required;

  /// Checks if the given argument match with this object
  bool _match(String arg) {
    if (arg.isEmpty) return false;
    if (arg == '--$name') return true;
    return abbr != null && arg == '-$abbr';
  }

  /// Used to validate the given input
  ///
  /// It checks:
  /// * if the field [abbr] is a single character.
  /// * if [name] is not an empty string.
  /// * if [name] does not contains any special characters
  void _validate() {
    if (name.isEmpty) {
      throw ArgvException('Argument name cannot be empty');
    }
    if (name.contains(RegExp(r'[^a-zA-Z0-9\-_]'))) {
      throw ArgvException('Invalid argument name: $name');
    }
    if (abbr != null && abbr!.length != 1) {
      throw ArgvException('Abbreviation must be a single character: $abbr');
    }
  }
}

/// Option class represents the classic options in the CLI.
///
/// There's two way you can pass value options:
/// 1. --name value
/// 2. --name=value
///
/// Parameters:
/// * [name] the name of the option (parsed with two `-` before)
/// * [abbr] the abbreviation of the name (parsed with single `-`)
/// * [description] used for the [Argv.usage] method.
/// * [allowed] if setted the value must be one of these, else throws [ArgvException].
/// * [required] if enabled and not value provided throws a [ArgvException]
/// * [defaultValue] if setted and not value provided this is the value.
class Option extends _Argument {
  Option(
    super.name, {
    super.abbr,
    super.help,
    super.description,
    this.allowed = const [],
    super.required = false,
    this.defaultValue,
  });
  final List<String> allowed;
  final String? defaultValue;

  String _usage() {
    String short = '';
    String help = description ?? '-';
    String choices = '';

    if (abbr != null) short = '-$abbr, ';
    if (allowed.isNotEmpty) {
      choices = '{${allowed.join('|')}}';
    }

    final part = '$short--$name <value>$choices'.padRight(15);

    return '  $part$help';
  }
}

class Flag extends _Argument {
  Flag(
    super.name, {
    super.abbr,
    super.help,
    super.description,
    this.defaultTo = false,
    super.required = false,
  });
  final bool defaultTo;

  String _usage() {
    String short = '';
    String desc = '-';

    if (abbr != null) short = '-$abbr, ';
    if (description != null) desc = description!;

    final help = '$short--$name'.padRight(15);

    return '  $help$desc';
  }
}

class ArgvResult {
  final Map<String, bool> _flags = {};
  final Map<String, String> _options = {};
  final List<String> _commands = [];
  final Map<String, String> _positionals = {};

  bool flag(String name) => _flags[name] ?? false;
  String? option(String name) => _options[name];
  String? positional(String name) => _positionals[name];
}

class Argv {
  Argv(this.name, [this.description = '']);
  final String name;
  final String description;
  final Map<String, Option> _options = {};
  final Map<String, Flag> _flags = {};
  final Map<String, Argv> _commands = {};
  final List<String> _positionals = [];
  ArgvCallback? _on;
  Argv? _parent;

  Argv flag(
    String name, {
    String? abbr,
    String? help,
    String? description,
    bool required = false,
    bool defaultTo = false,
  }) {
    _checkAleadyInserted(_flags, name);
    _checkAbbreviation(abbr);
    final flag = Flag(
      name,
      abbr: abbr,
      help: help,
      description: description,
      defaultTo: defaultTo,
      required: required,
    );
    flag._validate();
    _flags[name] = flag;
    return this;
  }

  Argv option(
    String name, {
    String? abbr,
    String? help,
    bool required = false,
    String? description,
    List<String> allowed = const [],
    String? defaultValue,
  }) {
    _checkAleadyInserted(_options, name);
    _checkAbbreviation(abbr);
    final opt = Option(
      name,
      abbr: abbr,
      help: help,
      allowed: allowed,
      description: description,
      defaultValue: defaultValue,
      required: required,
    );
    opt._validate();
    _options[name] = opt;
    return this;
  }

  Argv command(String name, {String? abbr, String? help, String? description}) {
    _checkAleadyInserted(_commands, name);
    final child = Argv(name);
    _commands[name] = child;
    child._parent = this;
    return child;
  }

  Argv on(ArgvCallback callback) {
    _on = callback;
    return this;
  }

  Argv positional(String name) {
    _positionals.add(name);
    return this;
  }

  String usage() {
    final b = StringBuffer();

    b.write('Usage: ${_getPath().join(' ')}');

    if (_commands.isNotEmpty) b.write(' <command>');
    if (_options.isNotEmpty || _flags.isNotEmpty) b.write(' [options]');

    for (final p in _positionals) {
      b.write(' $p');
    }

    b.writeln();

    if (_commands.isNotEmpty) {
      b.writeln('Commands:');
      for (final cmd in _commands.values) {
        String desc = cmd.description;
        if (desc.isEmpty) {
          desc = '-';
        }
        b.writeln('  ${cmd.name.padRight(15)}$desc');
      }
    }

    b.writeln();

    final flags = _collectFlag();
    if (flags.isNotEmpty) {
      b.writeln('Flags:');
      for (final flag in flags) {
        b.writeln(flag._usage());
      }
    }

    b.writeln();

    final options = _collectOption();
    if (options.isNotEmpty) {
      b.writeln('Options:');
      for (final opt in options) {
        b.writeln(opt._usage());
      }
    }

    return b.toString();
  }

  void _checkAleadyInserted<T>(Map<T, dynamic> args, T key) {
    if (args.containsKey(key)) {
      throw ArgvException('$key already resistered');
    }
  }

  void _checkAbbreviation(String? abbr) {
    if (abbr == null) return;
    final exception = ArgvException('Abbreviation $abbr already inserted');
    for (final flag in _flags.values) {
      if (flag.abbr == abbr) throw exception;
    }
    for (final opt in _options.values) {
      if (opt.abbr == abbr) throw exception;
    }
  }

  List<String> _getPath() {
    return _fold(<String>[], (acc, p) => [p.name, ...acc]);
  }

  List<Flag> _collectFlag() {
    final seen = <String>{};
    List<Flag> reduce(List<Flag> acc, Argv p) {
      for (final flag in p._flags.values) {
        if (seen.contains(flag.name)) continue;
        seen.add(flag.name);
        acc.add(flag);
      }
      return acc;
    }

    return _fold(<Flag>[], reduce);
  }

  List<Option> _collectOption() {
    final seen = <String>{};
    List<Option> reduce(List<Option> acc, Argv p) {
      for (final opt in p._options.values) {
        if (seen.contains(opt.name)) continue;
        seen.add(opt.name);
        acc.add(opt);
      }
      return acc;
    }

    return _fold(<Option>[], reduce);
  }

  T _fold<T>(T initial, T Function(T, Argv) reduce) {
    T acc = initial;

    Argv curr = this;

    while (curr._parent != null) {
      acc = reduce(acc, curr);
      curr = curr._parent!;
    }
    return acc;
  }

  bool _parseFlag(String arg, ArgvResult res) {
    bool parsed = false;
    for (final flag in _flags.values) {
      if (flag._match(arg)) {
        parsed = true;
        res._flags[flag.name] = true;
      } else if (!res._flags.containsKey(flag.name)) {
        res._flags[flag.name] = flag.defaultTo;
      }
    }
    return parsed;
  }

  (bool, int) _parseOption(String arg, List<String> args, ArgvResult res) {
    final splitted = arg.split('=');
    int consumed = 0;
    int expected = 0;
    String? value;
    bool parsed = false;

    if (splitted.length == 1) {
      if (args.isEmpty) {
        throw ArgvException('Option value for $arg not provided');
      }
      expected = 1;
      if (args.length >= 2) {
        value = args[1];
      }
    } else {
      arg = splitted[0];
      value = splitted.sublist(1).join('=');
    }

    for (final opt in _options.values) {
      if (opt._match(arg)) {
        parsed = true;
        consumed = expected;
        if (opt.allowed.isNotEmpty && !opt.allowed.contains(value)) {
          throw ArgvException('Option ${opt.name} value $value not allowed');
        }
        if (value == null) {
          if (opt.defaultValue == null) {
            throw ArgvException('Missing option value for $arg');
          }
          value = opt.defaultValue;
        }
        res._options[opt.name] = value!;
      }
    }

    return (parsed, consumed);
  }

  String _findClosestMatch(String input, List<String> candidates) {
    int index = -1;
    int max = 0;

    for (int i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      final curr = _getDistance(candidate, input);
      if (curr > max) {
        index = i;
        max = curr;
      }
    }
    return candidates[index];
  }

  void _handleUnknownArgument(String arg) {
    final candidates = <String>[];
    for (final c in [..._flags.values, ..._options.values]) {
      candidates.add('--${c.name}');
      if (c.abbr != null) candidates.add('-${c.abbr}');
    }
    final closest = _findClosestMatch(arg, candidates);

    throw ArgvException('Unknown argument $arg. Did you mean $closest?');
  }

  int _getDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    String trimmedA = a.substring(0, a.length - 1);
    String trimmedB = b.substring(0, b.length - 1);
    if (a[a.length - 1] == b[b.length - 1]) {
      return _getDistance(trimmedA, trimmedB);
    }

    int res = _getDistance(trimmedA, b);
    res = min(res, _getDistance(a, trimmedB));
    res = min(res, _getDistance(trimmedA, trimmedB));

    return 1 + res;
  }

  void _parsePositional(String arg, ArgvResult res) {
    if (_positionals.length <= res._positionals.length) {
      _handleUnknownArgument(arg);
    }
    final idx = res._positionals.length;
    res._positionals[_positionals.elementAt(idx)] = arg;
  }

  ArgvResult _parse(List<String> args) {
    final res = ArgvResult();

    Argv curr = this;

    for (int i = 0; i < args.length; i++) {
      final arg = args[i];
      if (curr._commands.containsKey(arg)) {
        curr = curr._commands[arg]!;
        res._commands.add(arg);
        continue;
      }

      if (curr._parseFlag(arg, res)) {
        continue;
      }

      final (handled, consumed) = curr._parseOption(arg, args.sublist(i), res);
      if (handled) {
        i += consumed;
        continue;
      }
      curr._parsePositional(arg, res);
    }
    return res;
  }

  void _validate(ArgvResult res) {
    for (final flag in _flags.values) {
      if (!res._flags.containsKey(flag.name)) {
        if (flag.required) {
          throw ArgvException('Flag ${flag.name} is required');
        }
        res._flags[flag.name] = flag.defaultTo;
      }
    }
    for (final opt in _options.values) {
      if (!res._options.containsKey(opt.name)) {
        if (opt.defaultValue == null && opt.required) {
          throw ArgvException('Missing required option ${opt.name}');
        }
        if (opt.defaultValue != null) {
          res._options[opt.name] = opt.defaultValue!;
        }
      } else if (opt.allowed.isNotEmpty) {
        if (!opt.allowed.contains(res._options[opt.name]!)) {
          throw ArgvException(
            'Option ${opt.name} not allow value ${res._options[opt.name]!}',
          );
        }
      }
    }

    if (_positionals.length > res._positionals.length) {
      throw ArgvException('Missing positionals argument: $_positionals');
    }
  }

  ArgvResult run(List<String> args) {
    final res = _parse(args);
    _validate(res);
    Argv curr = this;

    if (curr._on != null) curr._on!(res);

    for (final cmd in res._commands) {
      if (!curr._commands.containsKey(cmd)) break;
      curr = curr._commands[cmd]!;
      if (curr._on != null) {
        curr._on!(res);
      }
    }

    return res;
  }
}

class ArgvException implements Exception {
  ArgvException(this.message);
  final String message;

  @override
  String toString() => 'ArgvException: $message';
}
