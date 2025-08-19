typedef ArgvCallback = void Function(ArgvResult);

sealed class _Argument {
  _Argument(this.name, {this.abbr, this.help, this.description});
  final String name;
  final String? abbr;
  final String? help;
  final String? description;
}

class Command extends _Argument {
  Command(super.name, {super.abbr, super.help, super.description});
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
}

class Argv {
  final Map<String, Option> _options = {};
  final Map<String, Flag> _flags = {};
  final Map<String, Command> _commands = {};
  final List<Argv> _children = [];
  final List<Positional> _positionals = [];

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
    _checkAleadyInserted(_commands, name);
    _commands[name] = Command(
      name,
      abbr: abbr,
      help: help,
      description: description,
    );
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
}

class ArgvException implements Exception {
  ArgvException(this.message);
  final String message;

  @override
  String toString() => 'ArgvException: $message';
}
