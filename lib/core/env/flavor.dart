enum Flavor { dev, prod }

extension FlavorParse on Flavor {
  static Flavor fromName(String name) {
    return Flavor.values.firstWhere(
      (f) => f.name == name,
      orElse: () => Flavor.dev,
    );
  }
}
