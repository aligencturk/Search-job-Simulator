class MarketItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final String description;
  final int mentalBonus;
  final String bonusType; // single, daily, monthly, yearly

  const MarketItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    this.mentalBonus = 0,
    this.bonusType = "single",
  });
}

