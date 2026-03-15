class ZenithIntelligenceConfig {
  const ZenithIntelligenceConfig({
    this.hydrationTargetLiters = 2.0,
    this.energyDropThreshold = 1.0,
    this.weightRapidChangeKg = 1.5,
    this.puffinessConcernThreshold = 4.0,
    this.consistencyStrongDays = 5,
    this.minConfidenceSampleCount = 4,
    this.hydrationVolatilityThreshold = 0.8,
    this.energyVolatilityThreshold = 1.5,
    this.puffinessRisingThreshold = 0.75,
  });

  final double hydrationTargetLiters;
  final double energyDropThreshold;
  final double weightRapidChangeKg;
  final double puffinessConcernThreshold;
  final int consistencyStrongDays;
  final int minConfidenceSampleCount;
  final double hydrationVolatilityThreshold;
  final double energyVolatilityThreshold;
  final double puffinessRisingThreshold;
}
