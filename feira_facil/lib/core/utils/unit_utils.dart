enum ItemUnit {
  un('Unidade', 'un'),
  kg('Quilo', 'kg'),
  g('Grama', 'g'),
  l('Litro', 'l'),
  ml('Mililitro', 'ml'),
  bandeja('Bandeja', 'bdj'),
  pacote('Pacote', 'pct'),
  caixa('Caixa', 'cx');

  final String label;
  final String abbreviation;
  const ItemUnit(this.label, this.abbreviation);

  static ItemUnit fromString(String? value) {
    return ItemUnit.values.firstWhere(
      (u) => u.name == value || u.abbreviation == value,
      orElse: () => ItemUnit.un,
    );
  }
}
