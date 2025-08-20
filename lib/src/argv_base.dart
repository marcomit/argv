typedef ArgvCallback = void Function(ArgvResult);

sealed class _Argument {
  _Argument(this.name, {this.abbr, this.help, this.description});
  final String name;
  final String? abbr;
  final String? help;
  final String? description;
}

class Option extends _Argument {
  Option(super.name, {super.abbr, super.help, super.description});
}

class Flag extends _Argument {
  Flag(super.name, {super.abbr, super.help, super.description});
}

class Positional extends _Argument {
  Positional(super.name, {super.abbr, super.help, super.description});
}

class ArgvResult {
  final Map<String, bool> _flags = {};
  final Map<String, String> _options = {};
  final List<String> _commands = [];
  final Map<String, String> _positionals = {};
}

class Argv {
  final Map<String, Option> _options = {};
  final Map<String, Flag> _flags = {};
  final Map<String, Argv> _commands = {};
  final List<Positional> _positionals = [];
  Argv? parent;

  Argv flag(String name, {String? abbr, String? help, String? description}) {
    _checkAleadyInserted(_flags, name);
    final flag = Flag(name, abbr: abbr, help: help, description: description);
    _flags[name] = flag;
    return this;
  }

  Argv option(String name, {String? abbr, String? help, String? description}) {
    _checkAleadyInserted(_options, name);
    final opt = Option(name, abbr: abbr, help: help, description: description);
    _options[name] = opt;
    return this;
  }

  Argv command(String name, {String? abbr, String? help, String? description}) {
    if (_commands.containsKey(name))
      throw ArgvException('Command $name already registered');
    _commands[name] = Argv();
    return this;
  }

  Argv positional(
    String name, {
    String? abbr,
    String? help,
    String? description,
  }) {
    _positionals.add(
      Positional(name, abbr: abbr, help: help, description: description),
    );
    return this;
  }

  void _checkAleadyInserted(Map<String, _Argument> args, String key) {
    if (args.containsKey(key)) {
      throw ArgvException('$key already resistered');
    }
  }

  bool _parseFlag(String arg) {
    for (final flag in _flags.values) {
      if (arg == '--${flag.name}') return true;
      if (flag.abbr != null && arg == '-${flag.abbr}') return true;
    }
    return false;
  }

  (bool, int) _parseOption(String arg, List<String> args, ArgvResult res) {
    return (false, 0);
  }

  ArgvResult parse(List<String> args) {
    if (args.isEmpty) {
      print('no arguments provided');
    }
    final res = ArgvResult();

    Argv curr = this;

    for (int i = 0; i < args.length; i++) {
      final arg = args[i];
      if (curr._commands.containsKey(arg)) {
        curr = curr._commands[arg]!;
        res._commands.add(arg);
        continue;
      }

      if (_parseFlag(arg)) {
        res._flags[arg] = true;
        i++;
        continue;
      }
      final (handled, consumed) = _parseOption(arg, args.sublist(i), res);
      if (handled) {
        i += consumed;
        continue;
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
