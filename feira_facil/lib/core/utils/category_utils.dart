import 'package:flutter/material.dart';

class CategoryInfo {
  final String name;
  final IconData icon;
  final Color color;

  const CategoryInfo({
    required this.name,
    required this.icon,
    required this.color,
  });
}

const List<CategoryInfo> AppCategories = [
  CategoryInfo(name: 'Hortifruti', icon: Icons.eco, color: Colors.green),
  CategoryInfo(name: 'Carnes', icon: Icons.kebab_dining, color: Colors.red),
  CategoryInfo(name: 'Laticínios', icon: Icons.egg, color: Colors.amber),
  CategoryInfo(name: 'Padaria', icon: Icons.bakery_dining, color: Colors.orange),
  CategoryInfo(name: 'Bebidas', icon: Icons.local_drink, color: Colors.blue),
  CategoryInfo(name: 'Grãos', icon: Icons.grain, color: Colors.brown),
  CategoryInfo(name: 'Limpeza', icon: Icons.cleaning_services, color: Colors.cyan),
  CategoryInfo(name: 'Higiene', icon: Icons.front_loader, color: Colors.purple),
  CategoryInfo(name: 'Congelados', icon: Icons.ac_unit, color: Colors.lightBlue),
  CategoryInfo(name: 'Outros', icon: Icons.more_horiz, color: Colors.grey),
];
