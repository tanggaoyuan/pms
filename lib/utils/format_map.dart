class FormatMap {
  late Map<dynamic, dynamic> _map;

  FormatMap([Map<dynamic, dynamic>? map]) {
    _map = map ?? {};
  }

  T get<T>(List<dynamic> keys, T empty) {
    try {
      dynamic temp = _map ?? {};
      for (var key in keys) {
        temp = temp[key];
      }

      if (temp is String && temp.isEmpty) {
        return empty;
      }

      if (temp is List && temp.isEmpty) {
        return empty;
      }

      if (temp is Map && temp.isEmpty) {
        return empty;
      }

      return temp;
    } catch (e) {
      return empty;
    }
  }

  T? getDynamic<T>(List<dynamic> keys, [T? empty]) {
    return get(keys, empty);
  }

  Map getMap(List<dynamic> keys, [Map? empty]) {
    return get<Map>(keys, empty ?? {});
  }

  String getString(List<dynamic> keys, [String? empty]) {
    return get<String>(keys, empty ?? '');
  }

  int getInt(List<dynamic> keys, [int? empty]) {
    return get<int>(keys, empty ?? 0);
  }

  double getDouble(List<dynamic> keys, [double? empty]) {
    return get<double>(keys, empty ?? 0.0);
  }

  bool getBool(List<dynamic> keys, [bool? empty]) {
    return get<bool>(keys, empty ?? false);
  }

  List<T> getList<T>(List<dynamic> keys, [List<T>? empty]) {
    return get<List>(keys, empty ?? []).cast<T>();
  }

  bool set<T>(List<dynamic> keys, T value) {
    try {
      dynamic temp = _map;
      for (var i = 0; i < keys.length; i++) {
        var key = keys[i];
        if (keys.length - 1 == i) {
          temp[key] = value;
        } else {
          temp = temp[key] ??= {};
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  get map {
    return _map;
  }
}
