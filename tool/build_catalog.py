"""Builds assets/exercises/ from free-exercise-db (public domain, Unlicense).

Usage: python tool/build_catalog.py <path-to-free-exercise-db>
Writes assets/exercises/catalog.json and a resized pair of frames per exercise
(<id>_0.jpg = start position, <id>_1.jpg = end position).
"""
import json, os, sys
from PIL import Image

SRC = sys.argv[1]
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'exercises')

# (family_pt, family_en, [(id, name_pt, name_en), ...])
CATALOG = [
 ("Supino", "Bench press", [
   ("Barbell_Bench_Press_-_Medium_Grip", "Supino reto com barra", "Flat barbell bench press"),
   ("Barbell_Incline_Bench_Press_-_Medium_Grip", "Supino inclinado com barra", "Incline barbell bench press"),
   ("Decline_Barbell_Bench_Press", "Supino declinado com barra", "Decline barbell bench press"),
   ("Dumbbell_Bench_Press", "Supino reto com halteres", "Flat dumbbell bench press"),
   ("Incline_Dumbbell_Press", "Supino inclinado com halteres", "Incline dumbbell press"),
   ("Close-Grip_Barbell_Bench_Press", "Supino pegada fechada", "Close-grip bench press"),
   ("Smith_Machine_Bench_Press", "Supino na Smith", "Smith machine bench press"),
   ("Machine_Bench_Press", "Supino na máquina", "Machine chest press"),
 ]),
 ("Aberturas (peito)", "Chest fly", [
   ("Dumbbell_Flyes", "Aberturas com halteres", "Dumbbell fly"),
   ("Incline_Dumbbell_Flyes", "Aberturas inclinadas", "Incline dumbbell fly"),
   ("Butterfly", "Peck deck (máquina)", "Pec deck / butterfly"),
   ("Cable_Crossover", "Crossover na polia alta", "Cable crossover"),
   ("Low_Cable_Crossover", "Crossover na polia baixa", "Low cable crossover"),
 ]),
 ("Flexões", "Push-ups", [
   ("Pushups", "Flexões", "Push-ups"),
   ("Push-Up_Wide", "Flexões pegada larga", "Wide push-ups"),
   ("Push-Ups_-_Close_Triceps_Position", "Flexões fechadas (tríceps)", "Close-grip push-ups"),
   ("Incline_Push-Up", "Flexões inclinadas", "Incline push-ups"),
   ("Decline_Push-Up", "Flexões declinadas", "Decline push-ups"),
 ]),
 ("Agachamento", "Squat", [
   ("Barbell_Squat", "Agachamento com barra", "Barbell back squat"),
   ("Front_Barbell_Squat", "Agachamento frontal", "Front squat"),
   ("Goblet_Squat", "Agachamento goblet", "Goblet squat"),
   ("Bodyweight_Squat", "Agachamento livre", "Bodyweight squat"),
   ("Plie_Dumbbell_Squat", "Agachamento sumo", "Sumo (plié) squat"),
   ("Hack_Squat", "Hack squat", "Hack squat"),
   ("Smith_Machine_Squat", "Agachamento na Smith", "Smith machine squat"),
   ("Split_Squat_with_Dumbbells", "Agachamento búlgaro / split", "Split squat"),
 ]),
 ("Leg press", "Leg press", [
   ("Leg_Press", "Leg press", "Leg press"),
   ("Narrow_Stance_Leg_Press", "Leg press pés juntos", "Narrow-stance leg press"),
 ]),
 ("Afundos", "Lunges", [
   ("Dumbbell_Lunges", "Afundos com halteres", "Dumbbell lunges"),
   ("Barbell_Lunge", "Afundos com barra", "Barbell lunges"),
   ("Barbell_Walking_Lunge", "Afundos a caminhar", "Walking lunges"),
   ("Dumbbell_Rear_Lunge", "Afundos para trás", "Reverse lunges"),
   ("Dumbbell_Step_Ups", "Step-up com halteres", "Dumbbell step-ups"),
 ]),
 ("Pernas (máquinas)", "Leg machines", [
   ("Leg_Extensions", "Cadeira extensora", "Leg extension"),
   ("Lying_Leg_Curls", "Curl femoral deitado", "Lying leg curl"),
   ("Seated_Leg_Curl", "Curl femoral sentado", "Seated leg curl"),
 ]),
 ("Peso morto", "Deadlift", [
   ("Barbell_Deadlift", "Peso morto", "Barbell deadlift"),
   ("Romanian_Deadlift", "Peso morto romeno", "Romanian deadlift"),
   ("Stiff-Legged_Barbell_Deadlift", "Stiff com barra", "Stiff-legged deadlift"),
   ("Stiff-Legged_Dumbbell_Deadlift", "Stiff com halteres", "Stiff-legged dumbbell deadlift"),
   ("Sumo_Deadlift", "Peso morto sumo", "Sumo deadlift"),
   ("Trap_Bar_Deadlift", "Peso morto com trap bar", "Trap bar deadlift"),
 ]),
 ("Glúteos", "Glutes", [
   ("Barbell_Hip_Thrust", "Hip thrust com barra", "Barbell hip thrust"),
   ("Barbell_Glute_Bridge", "Ponte de glúteos com barra", "Barbell glute bridge"),
   ("Single_Leg_Glute_Bridge", "Ponte de glúteos unilateral", "Single-leg glute bridge"),
   ("Glute_Kickback", "Coice de glúteo", "Glute kickback"),
 ]),
 ("Gémeos", "Calves", [
   ("Standing_Calf_Raises", "Gémeos em pé", "Standing calf raise"),
   ("Seated_Calf_Raise", "Gémeos sentado", "Seated calf raise"),
   ("Calf_Press_On_The_Leg_Press_Machine", "Gémeos no leg press", "Calf press on leg press"),
 ]),
 ("Remada", "Row", [
   ("Bent_Over_Barbell_Row", "Remada curvada com barra", "Bent-over barbell row"),
   ("Reverse_Grip_Bent-Over_Rows", "Remada curvada supinada", "Reverse-grip barbell row"),
   ("One-Arm_Dumbbell_Row", "Remada unilateral com halter", "One-arm dumbbell row"),
   ("Seated_Cable_Rows", "Remada sentada na polia", "Seated cable row"),
   ("T-Bar_Row_with_Handle", "Remada cavalinho (T-bar)", "T-bar row"),
   ("Inverted_Row", "Remada invertida", "Inverted row"),
 ]),
 ("Puxada", "Lat pulldown", [
   ("Wide-Grip_Lat_Pulldown", "Puxada frontal aberta", "Wide-grip lat pulldown"),
   ("Close-Grip_Front_Lat_Pulldown", "Puxada pegada fechada", "Close-grip lat pulldown"),
   ("V-Bar_Pulldown", "Puxada com triângulo", "V-bar pulldown"),
   ("Underhand_Cable_Pulldowns", "Puxada supinada", "Underhand pulldown"),
   ("Straight-Arm_Pulldown", "Pulldown braços esticados", "Straight-arm pulldown"),
 ]),
 ("Elevações (barra fixa)", "Pull-ups", [
   ("Pullups", "Elevações pronadas", "Pull-ups"),
   ("Chin-Up", "Elevações supinadas", "Chin-ups"),
   ("Band_Assisted_Pull-Up", "Elevações assistidas com elástico", "Band-assisted pull-ups"),
 ]),
 ("Lombar", "Lower back", [
   ("Hyperextensions_Back_Extensions", "Extensões lombares", "Back extensions"),
   ("Good_Morning", "Good morning", "Good morning"),
 ]),
 ("Desenvolvimento (ombros)", "Shoulder press", [
   ("Barbell_Shoulder_Press", "Desenvolvimento com barra", "Barbell shoulder press"),
   ("Dumbbell_Shoulder_Press", "Desenvolvimento com halteres", "Dumbbell shoulder press"),
   ("Arnold_Dumbbell_Press", "Arnold press", "Arnold press"),
   ("Standing_Military_Press", "Press militar em pé", "Standing military press"),
   ("Machine_Shoulder_Military_Press", "Desenvolvimento na máquina", "Machine shoulder press"),
 ]),
 ("Elevações de ombros", "Shoulder raises", [
   ("Side_Lateral_Raise", "Elevação lateral", "Lateral raise"),
   ("Cable_Seated_Lateral_Raise", "Elevação lateral na polia", "Cable lateral raise"),
   ("Front_Dumbbell_Raise", "Elevação frontal", "Front raise"),
   ("Reverse_Flyes", "Aberturas invertidas (deltoide posterior)", "Reverse fly"),
   ("Face_Pull", "Face pull", "Face pull"),
   ("Upright_Barbell_Row", "Remada alta", "Upright row"),
 ]),
 ("Trapézio", "Traps", [
   ("Barbell_Shrug", "Encolhimentos com barra", "Barbell shrug"),
   ("Dumbbell_Shrug", "Encolhimentos com halteres", "Dumbbell shrug"),
 ]),
 ("Bíceps", "Biceps curl", [
   ("Barbell_Curl", "Curl de bíceps com barra", "Barbell curl"),
   ("EZ-Bar_Curl", "Curl com barra EZ", "EZ-bar curl"),
   ("Dumbbell_Bicep_Curl", "Curl com halteres", "Dumbbell curl"),
   ("Hammer_Curls", "Curl martelo", "Hammer curl"),
   ("Preacher_Curl", "Curl Scott", "Preacher curl"),
   ("Concentration_Curls", "Curl concentrado", "Concentration curl"),
   ("Incline_Dumbbell_Curl", "Curl inclinado", "Incline dumbbell curl"),
 ]),
 ("Tríceps", "Triceps", [
   ("Triceps_Pushdown", "Tríceps na polia (barra)", "Triceps pushdown"),
   ("Triceps_Pushdown_-_Rope_Attachment", "Tríceps na polia (corda)", "Rope pushdown"),
   ("EZ-Bar_Skullcrusher", "Tríceps testa", "Skullcrusher"),
   ("Standing_Dumbbell_Triceps_Extension", "Tríceps francês (acima da cabeça)", "Overhead triceps extension"),
   ("Tricep_Dumbbell_Kickback", "Tríceps coice", "Triceps kickback"),
   ("Bench_Dips", "Fundos no banco", "Bench dips"),
   ("Dips_-_Triceps_Version", "Fundos nas paralelas", "Parallel bar dips"),
 ]),
 ("Abdominais", "Abs", [
   ("Crunches", "Abdominais (crunch)", "Crunches"),
   ("Plank", "Prancha", "Plank"),
   ("Reverse_Crunch", "Abdominal invertido", "Reverse crunch"),
   ("Hanging_Leg_Raise", "Elevação de pernas suspenso", "Hanging leg raise"),
   ("Russian_Twist", "Russian twist", "Russian twist"),
   ("Cable_Crunch", "Abdominal na polia", "Cable crunch"),
   ("Oblique_Crunches_-_On_The_Floor", "Abdominal oblíquo", "Oblique crunch"),
   ("Mountain_Climbers", "Mountain climbers", "Mountain climbers"),
 ]),
]

db = {e['id']: e for e in json.load(open(os.path.join(SRC, 'dist', 'exercises.json')))}
os.makedirs(OUT, exist_ok=True)
families = []
missing = []
for fpt, fen, items in CATALOG:
    variants = []
    for ex_id, pt, en in items:
        e = db.get(ex_id)
        if not e:
            missing.append(ex_id); continue
        frames = []
        for i, rel in enumerate(e['images'][:2]):
            im = Image.open(os.path.join(SRC, 'exercises', rel)).convert('RGB')
            im.thumbnail((480, 480))
            # Flat folder: Flutter asset folders are not recursive.
            im.save(os.path.join(OUT, f'{ex_id}_{i}.jpg'), quality=72, optimize=True, progressive=True)
            frames.append(f'assets/exercises/{ex_id}_{i}.jpg')
        variants.append({
            'id': ex_id, 'pt': pt, 'en': en, 'frames': frames,
            'equipment': e.get('equipment') or '', 'level': e.get('level') or '',
            'primary': e.get('primaryMuscles', []), 'secondary': e.get('secondaryMuscles', []),
            'instructions': e.get('instructions', []),
        })
    families.append({'pt': fpt, 'en': fen, 'variants': variants})

json.dump({'source': 'free-exercise-db (public domain, Unlicense) - https://github.com/yuhonas/free-exercise-db',
           'families': families}, open(os.path.join(OUT, 'catalog.json'), 'w'), ensure_ascii=False, indent=1)
print('families', len(families), 'variants', sum(len(f['variants']) for f in families), 'missing', missing)
