const String templateMobilityRecovery = 'mobility_recovery';
const String templateStrengthA = 'strength_full_body_a';
const String templateStrengthB = 'strength_full_body_b';
const String templateMixedLight = 'mixed_light_conditioning';
const String templateZone2 = 'conditioning_zone2';

const Map<String, Map<String, dynamic>> workoutTemplates = {
  templateMobilityRecovery: {
    'name': 'Mobility / Recovery',
    'warmup': [
      {'name': 'Nasal Breathing Walk', 'time': '3 min'},
      {'name': 'Cat-Camel', 'sets': 2, 'reps': '8 reps'},
      {'name': 'World\'s Greatest Stretch', 'sets': 2, 'reps': '4/side'},
    ],
    'main': [
      {'name': 'Hip Flexor Stretch', 'sets': 2, 'time': '45 sec/side'},
      {'name': 'Thoracic Rotations', 'sets': 2, 'reps': '10/side'},
      {'name': 'Glute Bridge Hold', 'sets': 2, 'time': '30 sec'},
      {'name': 'Easy Walk', 'time': '8-12 min'},
    ],
    'cooldown': [
      {'name': 'Box Breathing', 'time': '2 min'},
      {'name': 'Hamstring Stretch', 'sets': 1, 'time': '60 sec/side'},
    ],
  },
  templateStrengthA: {
    'name': 'Strength Full Body A',
    'warmup': [
      {'name': 'Brisk Walk', 'time': '4 min'},
      {'name': 'Bodyweight Squat', 'sets': 2, 'reps': '10 reps'},
      {'name': 'Shoulder Circles', 'sets': 2, 'reps': '15 reps'},
    ],
    'main': [
      {
        'name': 'Goblet Squat / Air Squat',
        'sets': 3,
        'reps': '8-12',
        'restSec': 75,
        'note': 'Keep 1-2 reps in reserve.'
      },
      {
        'name': 'Push-Up (elevated if needed)',
        'sets': 3,
        'reps': '6-12',
        'restSec': 75,
        'note': 'Keep 1-2 reps in reserve.'
      },
      {
        'name': 'Reverse Lunge',
        'sets': 3,
        'reps': '8/side',
        'restSec': 60,
        'note': 'Keep 1-2 reps in reserve.'
      },
      {
        'name': 'Plank',
        'sets': 3,
        'time': '30-45 sec',
        'restSec': 45,
      },
    ],
    'finisher': {'name': 'Zone-2 Walk', 'time': '6-10 min'},
    'cooldown': [
      {'name': 'Calf Stretch', 'sets': 1, 'time': '45 sec/side'},
      {'name': 'Deep Breathing', 'time': '2 min'},
    ],
  },
  templateStrengthB: {
    'name': 'Strength Full Body B',
    'warmup': [
      {'name': 'Stationary March', 'time': '3 min'},
      {'name': 'Hip Hinge Drill', 'sets': 2, 'reps': '10 reps'},
      {'name': 'Scapular Retraction Drill', 'sets': 2, 'reps': '12 reps'},
    ],
    'main': [
      {
        'name': 'Romanian Deadlift (dumbbell optional)',
        'sets': 3,
        'reps': '8-10',
        'restSec': 75,
        'note': 'Keep 1-2 reps in reserve.'
      },
      {
        'name': 'One-Arm Row (backpack/dumbbell)',
        'sets': 3,
        'reps': '10/side',
        'restSec': 60,
        'note': 'Keep 1-2 reps in reserve.'
      },
      {
        'name': 'Split Squat',
        'sets': 3,
        'reps': '8/side',
        'restSec': 60,
        'note': 'Keep 1-2 reps in reserve.'
      },
      {
        'name': 'Dead Bug',
        'sets': 3,
        'reps': '10/side',
        'restSec': 45,
      },
    ],
    'cooldown': [
      {'name': 'Quad Stretch', 'sets': 1, 'time': '45 sec/side'},
      {'name': 'Supine Breathing', 'time': '2 min'},
    ],
  },
  templateMixedLight: {
    'name': 'Mixed Light Conditioning',
    'warmup': [
      {'name': 'Walk + Arm Swings', 'time': '4 min'},
      {'name': 'Dynamic Lunge Reach', 'sets': 2, 'reps': '6/side'},
    ],
    'main': [
      {
        'name': 'Circuit x3: Squat, Incline Push-Up, Bird Dog',
        'sets': 3,
        'reps': '10 each',
        'restSec': 75,
        'note': 'Strength reps should keep 1-2 reps in reserve.'
      },
      {'name': 'Low-Impact Cardio (walk/cycle)', 'time': '10-15 min'},
    ],
    'cooldown': [
      {'name': 'Hip Opener Stretch', 'sets': 1, 'time': '60 sec/side'},
      {'name': 'Nasal Breathing', 'time': '2 min'},
    ],
  },
  templateZone2: {
    'name': 'Conditioning Zone-2',
    'warmup': [
      {'name': 'Easy Walk', 'time': '5 min'},
      {'name': 'Ankle Mobility', 'sets': 2, 'reps': '8/side'},
    ],
    'main': [
      {
        'name': 'Zone-2 Cardio (walking/cycling)',
        'time': '20-35 min',
        'note': 'Comfortable pace. Full sentence breathing should be possible.'
      },
    ],
    'cooldown': [
      {'name': 'Slow Walk', 'time': '3 min'},
      {'name': 'Calming Breath Work', 'time': '2 min'},
    ],
  },
};
