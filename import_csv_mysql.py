import sys
import random
from datetime import datetime, timedelta
import mysql.connector
from faker import Faker

sys.stdout.reconfigure(encoding='utf-8')

fake = Faker(['fr_FR'])
random.seed(42)

# ════════════════════════════════════════════════════════
# CONFIG
# ════════════════════════════════════════════════════════
DB_CONFIG = {
    'host':     'localhost',
    'port':     3308,
    'user':     'root',
    'password': '',
    'database': 'gym_smartbell',
    'charset':  'utf8mb4',
}

TODAY     = datetime.now()
DUMMY_PWD = '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LMzS360n.06'

# Plans: duration en mois (schema: duration_months)
PLANS = {
    'CrossFit Elite':   {'price': 89.0,  'months': 1, 'weight': 0.30},
    'Standard Premium': {'price': 49.0,  'months': 1, 'weight': 0.35},
    'Yoga Flow':        {'price': 59.0,  'months': 1, 'weight': 0.20},
    'Day Pass':         {'price': 15.0,  'months': 0, 'weight': 0.15},  # 0 = 1 jour
}
PLAN_NAMES   = list(PLANS.keys())
PLAN_WEIGHTS = [PLANS[p]['weight'] for p in PLAN_NAMES]

FIRST_M = ['Mohamed','Ahmed','Youssef','Karim','Sami','Bilel',
           'Hamza','Amine','Riadh','Nizar','Tarek','Hedi',
           'Walid','Malek','Zied','Fares','Slim','Bassem']
FIRST_F = ['Sara','Nour','Ines','Yasmine','Rania','Lina',
           'Amira','Fatma','Sonia','Meriem','Salma','Dorra',
           'Cyrine','Olfa','Rim','Hana','Asma','Wafa']
LASTS   = ['Ben Ali','Chaabane','Trabelsi','Mansour','Hamdi',
           'Belhadj','Ayari','Belhaj','Dridi','Farhat',
           'Guesmi','Haddad','Jlassi','Karray','Lassoued',
           'Meddeb','Nasr','Oueslati','Riahi','Saad',
           'Tlili','Turki','Zghal','Zouari','Ben Salem']
CITIES  = ['Tunis','Sfax','Sousse','Monastir','Bizerte',
           'Nabeul','Kairouan','Ariana','Ben Arous','La Marsa']

# ════════════════════════════════════════════════════════
# CONNEXION
# ════════════════════════════════════════════════════════
print("Connexion a MySQL (port 3308)...")
conn   = mysql.connector.connect(**DB_CONFIG)
cursor = conn.cursor()
print("Connecte a gym_smartbell\n")

# ════════════════════════════════════════════════════════
# NETTOYAGE
# ════════════════════════════════════════════════════════
print("Nettoyage des tables...")
cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
TABLES = [
    'loyalty_transactions',
    'course_reservations','event_registrations',
    'payments','subscriptions',
    'complaints','notifications','notification_reads',
    'notification_broadcasts','messages',
    'qr_codes','refresh_tokens',
    'training_program_exercises','training_programs',
    'nutrition_plans','meals',
    'courses','coaches','members',
    'subscription_plans','events','salles','machines',
    'exercises','coupons','users',
]
for t in TABLES:
    try:
        cursor.execute(f"DELETE FROM `{t}`")
        cursor.execute(f"ALTER TABLE `{t}` AUTO_INCREMENT = 1")
        print(f"  OK  {t}")
    except Exception as e:
        print(f"  --  {t} ignoree ({e})")
cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
conn.commit()
print()

# ════════════════════════════════════════════════════════
# HELPER — inspecte les vraies colonnes d'une table
# ════════════════════════════════════════════════════════
def get_columns(table):
    cursor.execute(f"SHOW COLUMNS FROM `{table}`")
    return {row[0] for row in cursor.fetchall()}

# ════════════════════════════════════════════════════════
# 1. SUBSCRIPTION PLANS
#    Colonnes reelles: id, name, description, duration_months, price, active, created_at
# ════════════════════════════════════════════════════════
print("Insertion subscription_plans...")
cols_sp = get_columns('subscription_plans')
print(f"  Colonnes: {cols_sp}")

plans_rows = [
    ('CrossFit Elite',   'Plan CrossFit intensif avec acces illimite', 1, 89.0,  True),
    ('Standard Premium', 'Plan standard avec acces aux equipements',   1, 49.0,  True),
    ('Yoga Flow',        'Plan Yoga avec cours collectifs inclus',      1, 59.0,  True),
    ('Day Pass',         'Acces journalier sans engagement',            1, 15.0,  True),
]

for p in plans_rows:
    name, desc, dur_months, price, active = p
    fields, vals = [], []

    if 'name'            in cols_sp: fields.append('name');            vals.append(name)
    if 'description'     in cols_sp: fields.append('description');     vals.append(desc)
    if 'duration_months' in cols_sp: fields.append('duration_months'); vals.append(dur_months)
    if 'duration_days'   in cols_sp: fields.append('duration_days');   vals.append(dur_months * 30)
    if 'price'           in cols_sp: fields.append('price');           vals.append(price)
    if 'active'          in cols_sp: fields.append('active');          vals.append(active)
    if 'status'          in cols_sp: fields.append('status');          vals.append('ACTIVE')

    ph = ', '.join(['%s'] * len(fields))
    cursor.execute(f"INSERT INTO subscription_plans ({', '.join(fields)}) VALUES ({ph})", vals)

conn.commit()
cursor.execute("SELECT id, name FROM subscription_plans")
plan_id_map = {name: pid for pid, name in cursor.fetchall()}
print(f"  {len(plans_rows)} plans inseres — IDs: {plan_id_map}\n")

# ════════════════════════════════════════════════════════
# 2. COACHES  (users + coaches, heritage JOINED)
#    users:   first_name, last_name, email, password, phone, enabled, role, user_type
#    coaches: user_id, specialization, bio, hire_date, availability_status
# ════════════════════════════════════════════════════════
print("Insertion coaches...")
cols_coaches = get_columns('coaches')
print(f"  Colonnes coaches: {cols_coaches}")

coaches_info = [
    ('Mohamed','Harrabi','CrossFit',    'AVAILABLE','Specialiste CrossFit et HIIT'),
    ('Salma',  'Driri',  'Yoga',        'AVAILABLE','Professeur de Yoga certifie'),
    ('Ahmed',  'Khalil', 'Cardio',      'AVAILABLE','Coach Cardio et Endurance'),
    ('Rania',  'Belhaj', 'Powerlifting','AVAILABLE','Specialiste force et halterophilie'),
    ('Karim',  'Nasri',  'Boxing',      'AVAILABLE','Coach Boxe et Arts Martiaux'),
    ('Ines',   'Triki',  'Dance',       'AVAILABLE','Coach Danse et Pilates'),
    ('Youssef','Miled',  'CrossFit',    'ON_LEAVE', 'CrossFit niveau avance'),
    ('Nour',   'Ayari',  'Yoga',        'AVAILABLE','Yoga et meditation'),
    ('Slim',   'Farhat', 'Cardio',      'AVAILABLE','Running et preparation physique'),
    ('Sara',   'Guesmi', 'Powerlifting','AVAILABLE','Musculation et nutrition sportive'),
]

coach_ids = []
for fn, ln, spec, avail, bio in coaches_info:
    email     = f"{fn.lower()}.{ln.lower().replace(' ','')}@gymcoach.tn"
    phone     = f"+216{random.randint(20,99)}{random.randint(1000000,9999999)}"
    hire_date = (TODAY - timedelta(days=random.randint(180,1200))).strftime('%Y-%m-%d')

    # INSERT users
    cursor.execute("""
        INSERT INTO users
          (first_name, last_name, email, password, phone,
           enabled, role, user_type, created_at, updated_at)
        VALUES (%s,%s,%s,%s,%s, 1,'ROLE_COACH','COACH', NOW(), NOW())
    """, (fn, ln, email, DUMMY_PWD, phone))
    uid = cursor.lastrowid

    # INSERT coaches (colonnes dynamiques)
    c_fields, c_vals = ['user_id'], [uid]
    if 'specialization'     in cols_coaches: c_fields.append('specialization');     c_vals.append(spec)
    if 'speciality'         in cols_coaches: c_fields.append('speciality');         c_vals.append(spec)
    if 'bio'                in cols_coaches: c_fields.append('bio');                c_vals.append(bio)
    if 'hire_date'          in cols_coaches: c_fields.append('hire_date');          c_vals.append(hire_date)
    if 'availability_status'in cols_coaches: c_fields.append('availability_status');c_vals.append(avail)
    if 'status'             in cols_coaches: c_fields.append('status');             c_vals.append('ACTIVE')

    ph = ', '.join(['%s'] * len(c_fields))
    cursor.execute(f"INSERT INTO coaches ({', '.join(c_fields)}) VALUES ({ph})", c_vals)
    coach_ids.append(uid)

conn.commit()
print(f"  {len(coach_ids)} coaches inseres\n")

# ════════════════════════════════════════════════════════
# 3. MEMBERS (users + members, heritage JOINED)
#    users:   first_name, last_name, email, password, phone, address,
#             date_of_birth, gender, enabled, role, user_type
#    members: user_id, membership_status, join_date, loyalty_points
# ════════════════════════════════════════════════════════
print("Insertion 1000 membres (users + members)...")
cols_members = get_columns('members')
print(f"  Colonnes members: {cols_members}")

member_ids = []
for i in range(1, 1001):
    gender = 'MALE' if random.random() < 0.60 else 'FEMALE'
    fname  = random.choice(FIRST_M if gender == 'MALE' else FIRST_F)
    lname  = random.choice(LASTS)

    join_days_ago = random.randint(1, 540)
    join_date     = TODAY - timedelta(days=join_days_ago)
    days_since    = (TODAY - join_date).days

    if days_since < 30:
        mem_status = random.choices(['ACTIVE','INACTIVE'],           weights=[0.80,0.20])[0]
    elif days_since < 365:
        mem_status = random.choices(['ACTIVE','INACTIVE','SUSPENDED'],weights=[0.72,0.22,0.06])[0]
    else:
        mem_status = random.choices(['ACTIVE','INACTIVE','SUSPENDED'],weights=[0.65,0.27,0.08])[0]

    birth = fake.date_of_birth(minimum_age=18, maximum_age=60).strftime('%Y-%m-%d')
    email = f"{fname.lower()}.{lname.lower().replace(' ','').replace('-','')}_{i}@gmail.com"
    phone = f"+216{random.randint(20,99)}{random.randint(1000000,9999999)}"
    addr  = f"{random.randint(1,99)} Rue {fake.last_name()}, {random.choice(CITIES)}"

    # INSERT users
    cursor.execute("""
        INSERT INTO users
          (first_name, last_name, email, password, phone, address,
           date_of_birth, gender, enabled, role, user_type, created_at, updated_at)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s, 1,'ROLE_MEMBER','MEMBER', NOW(), NOW())
    """, (fname, lname, email, DUMMY_PWD, phone, addr, birth, gender))
    uid = cursor.lastrowid

    # INSERT members (colonnes dynamiques)
    m_fields, m_vals = ['user_id'], [uid]
    if 'membership_status' in cols_members: m_fields.append('membership_status'); m_vals.append(mem_status)
    if 'join_date'         in cols_members: m_fields.append('join_date');         m_vals.append(join_date.strftime('%Y-%m-%d'))
    if 'loyalty_points'    in cols_members: m_fields.append('loyalty_points');    m_vals.append(random.randint(0, 500))

    ph = ', '.join(['%s'] * len(m_fields))
    cursor.execute(f"INSERT INTO members ({', '.join(m_fields)}) VALUES ({ph})", m_vals)
    member_ids.append(uid)

    if i % 200 == 0:
        conn.commit()
        print(f"  ... {i}/1000")

conn.commit()
print(f"  1000 membres inseres\n")

# ════════════════════════════════════════════════════════
# 4. SUBSCRIPTIONS
#    Colonnes: user_id, plan_id, start_date, end_date, status
# ════════════════════════════════════════════════════════
print("Insertion subscriptions...")
cols_subs = get_columns('subscriptions')
print(f"  Colonnes: {cols_subs}")

inserted_subs = 0
sub_rows = []  # [(sub_id, plan_price)] pour les payments

for uid in member_ids:
    join_days_ago = random.randint(1, 540)
    current_start = TODAY - timedelta(days=join_days_ago)
    n_subs        = max(1, min(join_days_ago // 30 + random.randint(-1, 1), 18))

    for _ in range(n_subs):
        plan_name = random.choices(PLAN_NAMES, weights=PLAN_WEIGHTS)[0]
        months    = PLANS[plan_name]['months']
        days      = months * 30 if months > 0 else 1
        end_date  = current_start + timedelta(days=days)

        sub_status = 'EXPIRED' if end_date < TODAY else \
                     random.choices(['ACTIVE','CANCELLED'], weights=[0.85,0.15])[0]

        plan_id = plan_id_map.get(plan_name, list(plan_id_map.values())[0])

        s_fields = ['user_id','plan_id','start_date','end_date','status']
        s_vals   = [uid, plan_id,
                    current_start.strftime('%Y-%m-%d'),
                    end_date.strftime('%Y-%m-%d'),
                    sub_status]

        cursor.execute(
            f"INSERT INTO subscriptions ({', '.join(s_fields)}) VALUES ({', '.join(['%s']*len(s_fields))})",
            s_vals
        )
        sub_id = cursor.lastrowid
        sub_rows.append((sub_id, PLANS[plan_name]['price']))
        inserted_subs += 1

        current_start = end_date + timedelta(days=random.randint(0, 5))
        if current_start > TODAY:
            break

    if inserted_subs % 500 == 0:
        conn.commit()

conn.commit()
print(f"  {inserted_subs} abonnements inseres\n")

# ════════════════════════════════════════════════════════
# 5. PAYMENTS
#    Colonnes: subscription_id, amount, payment_date, payment_method, status, transaction_ref
# ════════════════════════════════════════════════════════
print("Insertion payments...")
METHODS  = ['CASH','CARD','BANK_TRANSFER']
METHOD_W = [0.50, 0.35, 0.15]

inserted_pays = 0
for sub_id, price in sub_rows:
    pay_dt = TODAY - timedelta(days=random.randint(0, 30))
    amount = round(price * random.uniform(0.98, 1.02), 2)
    status = random.choices(['COMPLETED','PENDING','FAILED'], weights=[0.85,0.10,0.05])[0]
    method = random.choices(METHODS, weights=METHOD_W)[0]
    ref    = f"TXN{random.randint(100000,999999)}"

    cursor.execute("""
        INSERT INTO payments
          (subscription_id, amount, payment_date, payment_method, status, transaction_ref)
        VALUES (%s,%s,%s,%s,%s,%s)
    """, (sub_id, amount, pay_dt.strftime('%Y-%m-%d %H:%M:%S'), method, status, ref))
    inserted_pays += 1

    if inserted_pays % 500 == 0:
        conn.commit()

conn.commit()
print(f"  {inserted_pays} paiements inseres\n")

# ════════════════════════════════════════════════════════
# 6. COMPLAINTS (100)
#    Colonnes: user_id, subject, description, status, created_at, resolved_at
# ════════════════════════════════════════════════════════
print("Insertion complaints (100)...")
SUBJECTS = [
    'Equipement defectueux','Vestiaires sales','Coach absent',
    'Cours annule sans prevenir','Probleme de facturation',
    'Musique trop forte','Climatisation defaillante',
    'Manque de materiel','Horaires non respectes','Autre',
]
sample_uids = random.sample(member_ids, min(100, len(member_ids)))
inserted_comp = 0

for uid in sample_uids:
    created    = TODAY - timedelta(days=random.randint(1, 180))
    status     = random.choices(['OPEN','IN_PROGRESS','RESOLVED','CLOSED'],
                                weights=[0.25,0.20,0.40,0.15])[0]
    resolved_at = None
    if status in ('RESOLVED','CLOSED'):
        resolved_at = (created + timedelta(days=random.randint(1,14))).strftime('%Y-%m-%d %H:%M:%S')

    cursor.execute("""
        INSERT INTO complaints (user_id, subject, description, status, created_at, resolved_at)
        VALUES (%s,%s,%s,%s,%s,%s)
    """, (uid, random.choice(SUBJECTS), fake.sentence(nb_words=14),
          status, created.strftime('%Y-%m-%d %H:%M:%S'), resolved_at))
    inserted_comp += 1

conn.commit()
print(f"  {inserted_comp} plaintes inserees\n")

# ════════════════════════════════════════════════════════
# RESUME FINAL
# ════════════════════════════════════════════════════════
def count(table):
    cursor.execute(f"SELECT COUNT(*) FROM `{table}`")
    return cursor.fetchone()[0]

print("=" * 52)
print("  IMPORT TERMINE — gym_smartbell")
print("=" * 52)
print(f"  Users total    : {count('users')}")
print(f"  Membres        : {count('members')}")
print(f"  Coaches        : {count('coaches')}")
print(f"  Plans          : {count('subscription_plans')}")
print(f"  Abonnements    : {count('subscriptions')}")
print(f"  Paiements      : {count('payments')}")
print(f"  Plaintes       : {count('complaints')}")
print("=" * 52)

cursor.close()
conn.close()
