import 'dart:math';

/// Callback function that will be attached on a command
///
/// This function is called when a command is executed, receiving
/// the parsed [ArgvResult] containing all the argument values.
///
/// Example:
/// ```dart
/// parser.command('build')
///   .flag('verbose')
///   .on((result) {
///     if (result.flag('verbose')) {
///       print('Building in verbose mode...');
///     }
///   });
/// ```
typedef ArgvCallback = void Function(ArgvResult);

/// Base class for all argument types (flags and options).
///
/// This sealed class provides common functionality for validating
/// and matching command-line arguments. It cannot be instantiated
/// directly - use [Flag] or [Option] instead.
sealed class _Argument {
  _Argument(
    this.name, {
    this.abbr,
    this.help,
    this.description,
    this.required = false,
  });

  /// The long name of the argument (used with --name)
  final String name;

  /// Optional single-character abbreviation (used with -x)
  final String? abbr;

  /// Help text for this argument
  final String? help;

  /// Detailed description used in usage generation
  final String? description;

  /// Whether this argument is required
  final bool required;

  /// Checks if the given argument match with this object
  ///
  /// Returns true if [arg] matches either the long form (--name)
  /// or short form (-abbr) of this argument.
  ///
  /// Example:
  /// ```dart
  /// final flag = Flag('verbose', abbr: 'v');
  /// flag._match('--verbose'); // true
  /// flag._match('-v');        // true
  /// flag._match('--help');    // false
  /// ```
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
  ///
  /// Throws [ArgvException] if validation fails.
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
/// Options are arguments that take values. They can be specified
/// in two ways:
/// 1. --name value (space-separated)
/// 2. --name=value (equals-separated)
///
/// Example:
/// ```dart
/// parser.option('output', abbr: 'o', defaultValue: 'result.txt');
/// // Can be used as: --output file.txt, -o file.txt, --output=file.txt
/// ```
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

  /// if set up these are the only values that can be inserted
  ///
  /// When non-empty, the option value must be one of the values
  /// in this list, otherwise an [ArgvException] is thrown.
  ///
  /// Example:
  /// ```dart
  /// parser.option('level', allowed: ['debug', 'info', 'error']);
  /// ```
  final List<String> allowed;

  /// This is the default value.
  ///
  /// Used when the option is not provided by the user.
  /// If null and the option is required, an error will be thrown.
  final String? defaultValue;

  /// Generates usage text for this option.
  ///
  /// Returns a formatted string showing how to use this option
  /// in the command line, including abbreviation and allowed values.
  ///
  /// Example output: "  -o, --output `value`    Output file path"
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

/// Flag class represents boolean command-line arguments.
///
/// Flags are arguments that don't take values - they are either
/// present (true) or absent (false/default value).
///
/// Example:
/// ```dart
/// parser.flag('verbose', abbr: 'v', description: 'Enable verbose output');
/// // Can be used as: --verbose, -v
/// ```
///
/// Parameters:
/// * [name] the name of the flag (parsed with two `-` before)
/// * [abbr] the abbreviation of the name (parsed with single `-`)
/// * [description] used for the [Argv.usage] method
/// * [defaultTo] the default value when the flag is not provided
/// * [required] if true, the flag must be present in the arguments
class Flag extends _Argument {
  Flag(
    super.name, {
    super.abbr,
    super.help,
    super.description,
    this.defaultTo = false,
    super.required = false,
  });

  /// This is the default value.
  ///
  /// The value returned when the flag is not provided by the user.
  /// Typically false, but can be set to true for flags that are
  /// "on by default".
  final bool defaultTo;

  /// Generates usage text for this flag.
  ///
  /// Returns a formatted string showing how to use this flag
  /// in the command line, including abbreviation and description.
  ///
  /// Example output: "  -v, --verbose    Enable verbose output"
  String _usage() {
    String short = '';
    String desc = '-';

    if (abbr != null) short = '-$abbr, ';
    if (description != null) desc = description!;

    final help = '$short--$name'.padRight(15);

    return '  $help$desc';
  }
}

/// Contains the parsed results from command-line arguments.
///
/// This class provides access to all parsed values including flags,
/// options, commands, and positional arguments. It is returned by
/// [Argv.run] and passed to command callbacks.
///
/// Example:
/// ```dart
/// final result = parser.run(['--verbose', '--output', 'file.txt', 'input.txt']);
/// print('Verbose: ${result.flag('verbose')}');
/// print('Output: ${result.option('output')}');
/// print('Input: ${result.positional('input')}');
/// ```
class ArgvResult {
  final Map<String, bool> _flags = {};
  final Map<String, String> _options = {};
  final List<String> _commands = [];
  final Map<String, String> _positionals = {};

  /// Return the value of the flag [name]
  ///
  /// If there's no flag with this name it return false;
  ///
  /// Example:
  /// ```dart
  /// if (result.flag('verbose')) {
  ///   print('Verbose mode enabled');
  /// }
  /// ```
  bool flag(String name) => _flags[name] ?? false;

  /// Return the option value.
  ///
  /// Returns the value of the option with the given [name],
  /// or null if the option was not provided and has no default value.
  ///
  /// Example:
  /// ```dart
  /// final output = result.option('output') ?? 'default.txt';
  /// ```
  String? option(String name) => _options[name];

  /// Return the positional value.
  ///
  /// Returns the value of the positional argument with the given [name],
  /// or null if no value was provided for this position.
  ///
  /// Example:
  /// ```dart
  /// final inputFile = result.positional('input');
  /// if (inputFile != null) {
  ///   processFile(inputFile);
  /// }
  /// ```
  String? positional(String name) => _positionals[name];
}

/// This class is the main core of argv library.
///
/// It is the parser of arguments and the builder for command-line interfaces.
/// Use this class to define your CLI structure with commands, flags, options,
/// and positional arguments.
///
/// Example:
/// ```dart
/// final parser = Argv('myapp', 'My awesome CLI application')
///   .flag('verbose', abbr: 'v', description: 'Verbose output')
///   .option('output', abbr: 'o', defaultValue: 'result.txt')
///   .positional('input-file');
///
/// final result = parser.run(args);
/// ```
///
/// Parameters:
/// * [name] It is the command name.
/// * [description] (optional) it is the description (it affects the usage string).
class Argv {
  Argv(this.name, [this.description = '']);

  /// Name of the command
  ///
  /// This is used in usage generation and error messages.
  /// For root commands, this is typically the executable name.
  /// For subcommands, this is the command name.
  final String name;

  /// Description of the command
  ///
  /// Optional description that appears in usage/help text.
  /// Provides context about what this command does.
  final String description;

  final Map<String, Option> _options = {};
  final Map<String, Flag> _flags = {};
  final Map<String, Argv> _commands = {};
  final List<String> _positionals = [];
  ArgvCallback? _on;
  Argv? _parent;

  /// Method to add a flag into the current command
  ///
  /// Flags are boolean arguments that don't take values.
  /// They can be specified in long form (--name) or short form (-abbr).
  ///
  /// For parameters see [Flag].
  /// Example:
  /// ```dart
  /// final git = Argv('git');
  /// git.command('push').flag('force', abbr: 'f')
  ///
  /// git.run(args);
  /// ```
  ///
  /// It can be parsed as '--force' or '-f'
  /// Note:
  /// * [name] and [abbr] if they're not unique it throws [ArgvException]
  ///
  /// Parameters:
  /// * [name] the name of the flag
  /// * [abbr] the abbreviation of the flag
  /// * [help] the help that will used in the [usage] string
  /// * [description] also used in the [usage] string
  /// * [required] if true it must be included in the input else throws [ArgvException]
  /// * [defaultTo] The default value if not provided in the input
  ///
  /// Returns this [Argv] instance for method chaining.
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

  /// Method to add an option into the current command.
  ///
  /// Options are arguments that take values. They can be specified
  /// in two formats:
  /// - Space-separated: --name value, -abbr value
  /// - Equals-separated: --name=value
  ///
  /// Example:
  /// ```dart
  /// parser.option('output', abbr: 'o', defaultValue: 'result.txt')
  ///   .option('format', allowed: ['json', 'xml', 'csv']);
  /// ```
  ///
  /// Parameters:
  /// * [name] the name of the option
  /// * [abbr] single-character abbreviation
  /// * [help] help text for usage generation
  /// * [required] whether this option must be provided
  /// * [description] detailed description for usage generation
  /// * [allowed] list of valid values (if not empty, value must be one of these)
  /// * [defaultValue] value to use if option is not provided
  ///
  /// Returns this [Argv] instance for method chaining.
  ///
  /// Throws [ArgvException] if name/abbreviation conflicts with existing arguments.
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

  /// Creates a subcommand under this command.
  ///
  /// Commands allow creating hierarchical CLI structures like
  /// `git commit`, `docker container run`, etc.
  ///
  /// Example:
  /// ```dart
  /// final git = Argv('git');
  /// git.command('commit')
  ///   .option('message', abbr: 'm', required: true)
  ///   .flag('all', abbr: 'a');
  ///
  /// // Usage: git commit -m "message" --all
  /// ```
  ///
  /// Note: This method returns the child command, not the parent.
  /// This allows you to chain methods to configure the subcommand.
  ///
  /// Parameters:
  /// * [name] the name of the subcommand
  /// * [abbr] optional abbreviation (currently unused)
  /// * [help] optional help text
  /// * [description] description for usage generation
  ///
  /// Returns the child [Argv] instance representing the subcommand.
  ///
  /// Throws [ArgvException] if a command with this name already exists.
  Argv command(String name, {String? abbr, String? help, String? description}) {
    _checkAleadyInserted(_commands, name);
    final child = Argv(name);
    _commands[name] = child;
    child._parent = this;
    return child;
  }

  /// Attaches a callback function to this command.
  ///
  /// The callback is executed when this command is invoked,
  /// receiving the parsed [ArgvResult] as a parameter.
  ///
  /// Example:
  /// ```dart
  /// parser.command('build')
  ///   .flag('verbose')
  ///   .on((result) {
  ///     print('Building project...');
  ///     if (result.flag('verbose')) {
  ///       print('Verbose mode enabled');
  ///     }
  ///   });
  /// ```
  ///
  /// Parameters:
  /// * [callback] function to execute when command is run
  ///
  /// Returns this [Argv] instance for method chaining.
  Argv on(ArgvCallback callback) {
    _on = callback;
    return this;
  }

  /// Adds a positional argument to this command.
  ///
  /// Positional arguments are values that don't have names or flags.
  /// They are parsed in the order they are defined.
  ///
  /// Example:
  /// ```dart
  /// parser.positional('source')
  ///   .positional('destination');
  ///
  /// // Usage: myapp source.txt dest.txt
  /// ```
  ///
  /// Parameters:
  /// * [name] identifier for this positional argument
  ///
  /// Returns this [Argv] instance for method chaining.
  Argv positional(String name) {
    _positionals.add(name);
    return this;
  }

  /// Generates usage/help text for this command.
  ///
  /// Creates a comprehensive help string showing:
  /// - Command usage syntax
  /// - Available subcommands
  /// - Available flags and their descriptions
  /// - Available options and their descriptions
  ///
  /// Example output:
  /// ```
  /// Usage: git commit [options] message
  ///
  /// Flags:
  ///   -a, --all          Stage all modified files
  ///   --amend            Amend the previous commit
  ///
  /// Options:
  ///   -m, --message <value>    Commit message
  /// ```
  ///
  /// Returns formatted usage string.
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

  /// Checks if a key already exists in the given map.
  ///
  /// Throws [ArgvException] if the key is already present,
  /// preventing duplicate argument names.
  void _checkAleadyInserted<T>(Map<T, dynamic> args, T key) {
    if (args.containsKey(key)) {
      throw ArgvException('$key already resistered');
    }
  }

  /// Validates that an abbreviation is unique within this command.
  ///
  /// Checks both flags and options to ensure no abbreviation
  /// conflicts exist. Throws [ArgvException] if conflict found.
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

  /// Gets the full command path from root to current command.
  ///
  /// Returns a list of command names representing the path
  /// from the root command to this command.
  List<String> _getPath() {
    return _fold(<String>[], (acc, p) => [p.name, ...acc]);
  }

  /// Collects all flags from this command and its ancestors.
  ///
  /// Used for usage generation to show all available flags
  /// in the command hierarchy.
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

  /// Collects all options from this command and its ancestors.
  ///
  /// Used for usage generation to show all available options
  /// in the command hierarchy.
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

  /// Folds over the command hierarchy from current to root.
  ///
  /// Applies the reduce function to each command in the hierarchy,
  /// accumulating results from child to parent commands.
  T _fold<T>(T initial, T Function(T, Argv) reduce) {
    T acc = initial;

    Argv curr = this;

    while (curr._parent != null) {
      acc = reduce(acc, curr);
      curr = curr._parent!;
    }
    return acc;
  }

  /// Parses a flag argument from the input.
  ///
  /// Checks if the argument matches any defined flags and
  /// sets the appropriate values in the result. Sets defaults
  /// for flags that weren't explicitly provided.
  ///
  /// Returns true if the argument was successfully parsed as a flag.
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

  /// Parses an option argument from the input.
  ///
  /// Handles both space-separated (--name value) and equals-separated
  /// (--name=value) option formats. Validates against allowed values
  /// if specified.
  ///
  /// Returns a tuple of (parsed, consumed) where:
  /// - parsed: true if argument was successfully parsed as an option
  /// - consumed: number of arguments consumed (1 for equals, 1 for space-separated)
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

  /// Finds the closest matching argument name for typo suggestions.
  ///
  /// Uses a distance algorithm to find the most similar argument
  /// name from the available candidates. Used for providing
  /// helpful error messages when users make typos.
  ///
  /// Parameters:
  /// * [input] the incorrect argument provided by user
  /// * [candidates] list of valid argument names to compare against
  ///
  /// Returns the closest matching candidate.
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

  /// Handles unknown arguments by providing helpful suggestions.
  ///
  /// When an argument is not recognized, this method generates
  /// a list of similar valid arguments and suggests the closest
  /// match to help users correct their typos.
  ///
  /// Always throws [ArgvException] with a helpful error message.
  void _handleUnknownArgument(String arg) {
    final candidates = <String>[];
    for (final c in [..._flags.values, ..._options.values]) {
      candidates.add('--${c.name}');
      if (c.abbr != null) candidates.add('-${c.abbr}');
    }
    final closest = _findClosestMatch(arg, candidates);

    throw ArgvException('Unknown argument $arg. Did you mean $closest?');
  }

  /// Calculates edit distance between two strings.
  ///
  /// Uses a recursive approach to calculate the minimum number
  /// of edits needed to transform string [a] into string [b].
  /// Used for finding similar argument names for typo suggestions.
  ///
  /// Returns the edit distance as an integer.
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

  /// Parses a positional argument from the input.
  ///
  /// Positional arguments are non-flag, non-option values that
  /// are parsed in the order they are defined. If more positional
  /// arguments are provided than expected, treats them as unknown.
  ///
  /// Throws [ArgvException] if too many positional arguments provided.
  void _parsePositional(String arg, ArgvResult res) {
    if (_positionals.length <= res._positionals.length) {
      _handleUnknownArgument(arg);
    }
    final idx = res._positionals.length;
    res._positionals[_positionals.elementAt(idx)] = arg;
  }

  /// Internal method that parses the command-line arguments.
  ///
  /// This method processes the argument list, identifying commands,
  /// flags, options, and positional arguments. It handles command
  /// navigation and delegates to specific parsing methods.
  ///
  /// Parameters:
  /// * [args] list of command-line arguments to parse
  ///
  /// Returns [ArgvResult] containing all parsed values.
  ///
  /// This method does not perform validation - use [run] for
  /// complete parsing with validation.
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

  /// Validates the parsed results against the defined constraints.
  ///
  /// Performs post-parsing validation including:
  /// - Checking required flags and options are present
  /// - Setting default values for optional arguments
  /// - Validating option values against allowed lists
  /// - Ensuring all required positional arguments are provided
  ///
  /// Parameters:
  /// * [res] the parsed result to validate
  ///
  /// Throws [ArgvException] if validation fails.
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

  /// Parses and executes the command-line arguments.
  ///
  /// This is the main entry point for the argument parser. It:
  /// 1. Parses the arguments into structured data
  /// 2. Validates all constraints and requirements
  /// 3. Executes callbacks for the root command and any subcommands
  ///
  /// Example:
  /// ```dart
  /// final parser = Argv('myapp')
  ///   .flag('verbose')
  ///   .option('output', defaultValue: 'result.txt')
  ///   .positional('input');
  ///
  /// final result = parser.run(['--verbose', '--output', 'out.txt', 'input.txt']);
  /// ```
  ///
  /// Parameters:
  /// * [args] list of command-line arguments (typically from main function)
  ///
  /// Returns [ArgvResult] containing all parsed and validated values.
  ///
  /// Throws [ArgvException] if parsing or validation fails.
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

/// Exception thrown when argument parsing or validation fails.
///
/// This exception is thrown in various scenarios:
/// - Invalid argument names or abbreviations
/// - Duplicate argument definitions
/// - Missing required arguments
/// - Invalid option values
/// - Unknown arguments
/// - Malformed input
///
/// The exception message provides specific details about what went wrong
/// and often includes suggestions for correction.
///
/// Example:
/// ```dart
/// try {
///   parser.run(['--unknown-flag']);
/// } catch (e) {
///   if (e is ArgvException) {
///     print('Argument error: ${e.message}');
///   }
/// }
/// ```
class ArgvException implements Exception {
  /// Creates a new argument parsing exception.
  ///
  /// Parameters:
  /// * [message] descriptive error message explaining what went wrong
  ArgvException(this.message);

  /// The error message describing what went wrong.
  ///
  /// This message is designed to be user-friendly and often includes
  /// suggestions for how to fix the problem.
  final String message;

  /// Returns a string representation of the exception.
  ///
  /// The format is "ArgvException: [message]" which provides
  /// clear identification of the error type and details.
  @override
  String toString() => 'ArgvException: $message';
}
