import pymysql
import random
from datetime import datetime, timedelta
from faker import Faker

fake = Faker(['fr_FR'])
random.seed(42)

DB_CONFIG = {
    'host':     'localhost',
    'port':     3308,
    'user':     'root',
    'password': '',
    'database': 'gym_smartbell',
    'charset':  'utf8mb4',
}

TODAY = datetime.now()

TUNISIAN_FIRST_M = ['Mohamed','Ahmed','Youssef','Karim','Sami','Bilel','Hamza','Amine','Riadh','Nizar','Tarek','Hedi','Walid','Malek','Zied','Fares','Slim','Bassem']
TUNISIAN_FIRST_F = ['Sara','Nour','Ines','Yasmine','Rania','Lina','Amira','Fatma','Sonia','Meriem','Salma','Dorra','Cyrine','Olfa','Rim','Hana','Asma','Wafa']
TUNISIAN_LAST    = ['Ben Ali','Chaabane','Trabelsi','Mansour','Hamdi','Belhadj','Ayari','Belhaj','Dridi','Farhat','Guesmi','Haddad','Jlassi','Karray','Lassoued','Meddeb','Nasr','Oueslati','Riahi','Saad','Tlili','Turki','Zghal','Zouari','Ben Salem']
CITIES           = ['Tunis','Sfax','Sousse','Monastir','Bizerte','Nabeul','Kairouan','Ariana','Ben Arous','La Marsa']

PLANS        = {
    'CrossFit Elite':   {'price': 89,  'weight': 0.30},
    'Standard Premium': {'price': 49,  'weight': 0.35},
    'Yoga Flow':        {'price': 59,  'weight': 0.20},
    'Day Pass':         {'price': 15,  'weight': 0.15},
}
PLAN_NAMES   = list(PLANS.keys())
PLAN_WEIGHTS = [PLANS[p]['weight'] for p in PLAN_NAMES]

print("🏋️  GymAdmin — Import données dans gym_smartbell")
print("=" * 55)

try:
    conn   = pymysql.connect(**DB_CONFIG)
    cursor = conn.cursor()
    print("✅ Connexion MySQL réussie !")
except Exception as e:
    print(f"❌ Erreur connexion : {e}")
    exit(1)

def get_columns(table):
    cursor.execute(f"DESCRIBE {table}")
    return [row[0] for row in cursor.fetchall()]

def get_full_desc(table):
    cursor.execute(f"DESCRIBE {table}")
    return cursor.fetchall()

def table_exists(table):
    cursor.execute(f"SHOW TABLES LIKE '{table}'")
    return cursor.fetchone() is not None

# ═══════════════════════════════════════════════════════
# ANALYSER LES ENUMS ET COLONNES
# ═══════════════════════════════════════════════════════
print("\n🔍 Analyse détaillée de la table users...")
desc = get_full_desc('users')
for row in desc:
    print(f"   {row[0]:<25} type={row[1]:<40} null={row[2]} key={row[3]} default={row[4]}")

print("\n🔍 Analyse détaillée de la table members...")
desc_m = get_full_desc('members')
for row in desc_m:
    print(f"   {row[0]:<25} type={row[1]:<40} null={row[2]} key={row[3]} default={row[4]}")

# Trouver les valeurs ENUM pour role et user_type
print("\n🔍 Valeurs ENUM acceptées...")
cursor.execute("SELECT COLUMN_NAME, COLUMN_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='gym_smartbell' AND TABLE_NAME='users' AND DATA_TYPE='enum'")
enums = cursor.fetchall()
for e in enums:
    print(f"   {e[0]} : {e[1]}")

cursor.execute("SELECT COLUMN_NAME, COLUMN_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='gym_smartbell' AND TABLE_NAME='members' AND DATA_TYPE='enum'")
enums_m = cursor.fetchall()
for e in enums_m:
    print(f"   members.{e[0]} : {e[1]}")

# Récupérer la première valeur ENUM pour role et user_type
def get_first_enum_value(table, column):
    cursor.execute(f"SELECT COLUMN_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='gym_smartbell' AND TABLE_NAME='{table}' AND COLUMN_NAME='{column}'")
    result = cursor.fetchone()
    if result:
        # Parse enum('val1','val2') → val1
        enum_str = result[0]  # ex: enum('ADMIN','MEMBER','COACH')
        values = enum_str.replace("enum(","").replace(")","").replace("'","").split(",")
        return values  # retourne toute la liste
    return []

role_values    = get_first_enum_value('users', 'role')
utype_values   = get_first_enum_value('users', 'user_type')
status_values  = get_first_enum_value('members', 'membership_status')
gender_values  = get_first_enum_value('users', 'gender')

print(f"\n   role values      : {role_values}")
print(f"   user_type values : {utype_values}")
print(f"   status values    : {status_values}")
print(f"   gender values    : {gender_values}")

# Choisir les bonnes valeurs
def pick_role(values, prefer=['MEMBER','member','USER','user']):
    for p in prefer:
        if p in values: return p
    return values[0] if values else 'MEMBER'

def pick_utype(values, prefer=['MEMBER','member','USER','user']):
    for p in prefer:
        if p in values: return p
    return values[0] if values else 'MEMBER'

def pick_status(values, prefer_active=['ACTIVE','active'], prefer_expired=['EXPIRED','expired'], prefer_pending=['PENDING','pending']):
    active  = next((v for v in values for p in ['ACTIVE','active']  if v==p), values[0] if values else 'ACTIVE')
    expired = next((v for v in values for p in ['EXPIRED','expired'] if v==p), values[0] if values else 'EXPIRED')
    pending = next((v for v in values for p in ['PENDING','pending'] if v==p), values[0] if values else 'PENDING')
    return active, expired, pending

def pick_gender(values, male=['MALE','male','M','m'], female=['FEMALE','female','F','f']):
    m = next((v for v in values for p in male   if v==p), 'MALE')
    f = next((v for v in values for p in female if v==p), 'FEMALE')
    return m, f

ROLE_VAL   = pick_role(role_values)
UTYPE_VAL  = pick_utype(utype_values)
STATUS_ACTIVE, STATUS_EXPIRED, STATUS_PENDING = pick_status(status_values)
GENDER_M, GENDER_F = pick_gender(gender_values)

print(f"\n   → Utilise role='{ROLE_VAL}', user_type='{UTYPE_VAL}'")
print(f"   → Status : ACTIVE='{STATUS_ACTIVE}', EXPIRED='{STATUS_EXPIRED}', PENDING='{STATUS_PENDING}'")
print(f"   → Gender : M='{GENDER_M}', F='{GENDER_F}'")

# ═══════════════════════════════════════════════════════
# IMPORT USERS + MEMBERS
# ═══════════════════════════════════════════════════════
cursor.execute("SELECT COUNT(*) FROM members")
existing_members = cursor.fetchone()[0]

if existing_members >= 50:
    print(f"\n   ℹ️  {existing_members} membres déjà présents — skip")
else:
    print("\n📥 Import users + members (1000)...")
    
    user_cols   = get_columns('users')
    member_cols = get_columns('members')
    
    cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
    inserted_u = 0
    inserted_m = 0
    errors     = 0

    for i in range(1, 1001):
        is_male   = random.random() < 0.6
        gender    = GENDER_M if is_male else GENDER_F
        fname     = random.choice(TUNISIAN_FIRST_M if is_male else TUNISIAN_FIRST_F)
        lname     = random.choice(TUNISIAN_LAST)
        join_date = TODAY - timedelta(days=random.randint(1, 540))
        days_ago  = (TODAY - join_date).days

        if days_ago < 30:
            mem_status = random.choices([STATUS_ACTIVE, STATUS_PENDING], weights=[0.7, 0.3])[0]
        else:
            mem_status = random.choices([STATUS_ACTIVE, STATUS_EXPIRED, STATUS_PENDING], weights=[0.70, 0.22, 0.08])[0]

        birth  = fake.date_of_birth(minimum_age=18, maximum_age=60)
        email  = f"{fname.lower()}.{lname.lower().replace(' ','').replace('-','')}_{i}@gmail.com"
        phone  = f"+216{random.randint(20,99)}{random.randint(1000000,9999999)}"
        city   = random.choice(CITIES)
        now_str = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

        # ── INSERT users ──
        user_id = None
        try:
            uc = {
                'email':            email,
                'password':         '$2a$10$dummyhashedpassword.forpfetesting.xxxxxxxxxxxxx',
                'role':             ROLE_VAL,
                'user_type':        UTYPE_VAL,
                'first_name':       fname,
                'last_name':        lname,
                'phone':            phone,
                'gender':           gender,
                'date_of_birth':    birth.strftime('%Y-%m-%d'),
                'address':          city,
                'enabled':          1,
                'created_at':       now_str,
                'updated_at':       now_str,
                'profile_image_url': '',
            }

            ic = [c for c in user_cols if c in uc and c != 'id']
            iv = [uc[c] for c in ic]

            cursor.execute(
                f"INSERT INTO users ({','.join(ic)}) VALUES ({','.join(['%s']*len(ic))})",
                iv
            )
            user_id = cursor.lastrowid
            inserted_u += 1

        except Exception as e:
            errors += 1
            if errors <= 3:
                print(f"   ⚠️  Erreur user {i}: {e}")
            continue

        # ── INSERT members ──
        if user_id:
            try:
                mc = {
                    'user_id':           user_id,
                    'join_date':         join_date.strftime('%Y-%m-%d'),
                    'membership_status': mem_status,
                    'medical_notes':     '',
                    'emergency_contact': f"{fname} Parent",
                    'emergency_phone':   phone,
                }

                ic2 = [c for c in member_cols if c in mc and mc[c] is not None]
                iv2 = [mc[c] for c in ic2]

                cursor.execute(
                    f"INSERT INTO members ({','.join(ic2)}) VALUES ({','.join(['%s']*len(ic2))})",
                    iv2
                )
                inserted_m += 1

            except Exception as e:
                errors += 1
                if errors <= 3:
                    print(f"   ⚠️  Erreur member {i}: {e}")

        if i % 100 == 0:
            conn.commit()
            print(f"   ... {i}/1000 (users:{inserted_u}, members:{inserted_m}, erreurs:{errors})")

    conn.commit()
    cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
    print(f"\n   ✅ {inserted_u} users + {inserted_m} membres importés")

# ═══════════════════════════════════════════════════════
# PAYMENTS
# ═══════════════════════════════════════════════════════
print("\n📥 Import payments...")
if table_exists('payments'):
    pay_cols = get_columns('payments')
    cursor.execute("SELECT COUNT(*) FROM payments")
    if cursor.fetchone()[0] >= 100:
        print("   ℹ️  Paiements déjà présents — skip")
    else:
        cursor.execute("SELECT user_id FROM members LIMIT 500")
        mids = [r[0] for r in cursor.fetchall()]
        if not mids:
            print("   ⚠️  Aucun membre — skip")
        else:
            # Trouver les valeurs ENUM pour status et payment_method
            pay_status_vals  = get_first_enum_value('payments', 'status')
            pay_method_vals  = get_first_enum_value('payments', 'payment_method')
            print(f"   payment status values : {pay_status_vals}")
            print(f"   payment method values : {pay_method_vals}")

            def map_status(val, vals):
                for v in vals:
                    if v.upper() == val.upper(): return v
                return vals[0] if vals else val

            def map_method(val, vals):
                for v in vals:
                    if v.upper() == val.upper(): return v
                return vals[0] if vals else val

            n = 0
            cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
            for mid in mids:
                for _ in range(random.randint(2, 8)):
                    plan   = random.choices(PLAN_NAMES, weights=PLAN_WEIGHTS)[0]
                    amount = round(PLANS[plan]['price'] * random.uniform(0.95, 1.05), 2)
                    pdate  = TODAY - timedelta(days=random.randint(1, 500))
                    method = random.choices(['CASH','CARD','VIREMENT'], weights=[0.5,0.35,0.15])[0]
                    status = random.choices(['PAID','PENDING','FAILED'], weights=[0.85,0.1,0.05])[0]

                    if pay_method_vals: method = map_method(method, pay_method_vals)
                    if pay_status_vals: status = map_status(status, pay_status_vals)

                    pc = {
                        'member_id':       mid,
                        'user_id':         mid,
                        'amount':          amount,
                        'payment_date':    pdate.strftime('%Y-%m-%d'),
                        'payment_method':  method,
                        'status':          status,
                        'transaction_ref': f"TXN{random.randint(100000,999999)}",
                    }

                    ic = [c for c in pay_cols if c in pc and c != 'id' and c != 'subscription_id']
                    iv = [pc[c] for c in ic]

                    if ic:
                        try:
                            cursor.execute(f"INSERT INTO payments ({','.join(ic)}) VALUES ({','.join(['%s']*len(ic))})", iv)
                            n += 1
                        except: pass

            conn.commit()
            cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
            print(f"   ✅ {n} paiements importés")

# ═══════════════════════════════════════════════════════
# SUBSCRIPTIONS
# ═══════════════════════════════════════════════════════
print("\n📥 Import subscriptions...")
if table_exists('subscriptions'):
    sub_cols = get_columns('subscriptions')
    cursor.execute("SELECT COUNT(*) FROM subscriptions")
    if cursor.fetchone()[0] >= 100:
        print("   ℹ️  Abonnements déjà présents — skip")
    else:
        cursor.execute("SELECT user_id FROM members LIMIT 500")
        mids = [r[0] for r in cursor.fetchall()]
        if not mids:
            print("   ⚠️  Aucun membre — skip")
        else:
            sub_status_vals = get_first_enum_value('subscriptions', 'status')
            print(f"   subscription status values : {sub_status_vals}")

            def map_sub_status(val, vals):
                for v in vals:
                    if v.upper() == val.upper(): return v
                return vals[0] if vals else val

            n = 0
            cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
            for mid in mids:
                sd  = TODAY - timedelta(days=random.randint(1, 365))
                ed  = sd + timedelta(days=30)
                st  = 'ACTIVE' if ed > TODAY else 'EXPIRED'
                if sub_status_vals: st = map_sub_status(st, sub_status_vals)

                sc = {
                    'user_id':    mid,
                    'start_date': sd.strftime('%Y-%m-%d'),
                    'end_date':   ed.strftime('%Y-%m-%d'),
                    'status':     st,
                    'created_at': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                }

                ic = [c for c in sub_cols if c in sc and c != 'id' and c not in ['coupon_id','plan_id']]
                iv = [sc[c] for c in ic]

                if ic:
                    try:
                        cursor.execute(f"INSERT INTO subscriptions ({','.join(ic)}) VALUES ({','.join(['%s']*len(ic))})", iv)
                        n += 1
                    except: pass

            conn.commit()
            cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
            print(f"   ✅ {n} abonnements importés")

# ═══════════════════════════════════════════════════════
# COMPLAINTS
# ═══════════════════════════════════════════════════════
print("\n📥 Import complaints...")
if table_exists('complaints'):
    comp_cols = get_columns('complaints')
    cursor.execute("SELECT COUNT(*) FROM complaints")
    if cursor.fetchone()[0] >= 20:
        print("   ℹ️  Plaintes déjà présentes — skip")
    else:
        cursor.execute("SELECT user_id FROM members ORDER BY RAND() LIMIT 80")
        mids = [r[0] for r in cursor.fetchall()]

        comp_status_vals = get_first_enum_value('complaints', 'status')
        print(f"   complaint status values : {comp_status_vals}")

        def map_comp_status(val, vals):
            for v in vals:
                if v.upper() == val.upper(): return v
            return vals[0] if vals else val

        subjects = ['Équipement défectueux','Vestiaires sales','Coach absent',
                    'Cours annulé','Problème facturation','Musique trop forte',
                    'Climatisation défaillante']
        n = 0
        cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
        for mid in mids:
            cd = TODAY - timedelta(days=random.randint(1, 180))
            st = random.choices(['OPEN','RESOLVED','PENDING'], weights=[0.25,0.55,0.20])[0]
            if comp_status_vals: st = map_comp_status(st, comp_status_vals)

            cc = {
                'user_id':     mid,
                'subject':     random.choice(subjects),
                'description': fake.sentence(nb_words=10),
                'created_at':  cd.strftime('%Y-%m-%d %H:%M:%S'),
                'status':      st,
                'response':    '',
                'resolved_at': None,
            }

            ic = [c for c in comp_cols if c in cc and cc[c] is not None and c != 'id']
            iv = [cc[c] for c in ic]

            if ic:
                try:
                    cursor.execute(f"INSERT INTO complaints ({','.join(ic)}) VALUES ({','.join(['%s']*len(ic))})", iv)
                    n += 1
                except: pass

        conn.commit()
        cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
        print(f"   ✅ {n} plaintes importées")

# ═══════════════════════════════════════════════════════
# RÉSUMÉ FINAL
# ═══════════════════════════════════════════════════════
print("\n" + "="*55)
print("📊 RÉSUMÉ FINAL — gym_smartbell")
print("="*55)
for t in ['users','members','coaches','payments','subscriptions','complaints','courses','machines','events']:
    if table_exists(t):
        cursor.execute(f"SELECT COUNT(*) FROM {t}")
        print(f"  ✅ {t:<25} → {cursor.fetchone()[0]:>6} lignes")
print("="*55)
print("\n✅ Import terminé ! 🚀")

cursor.close()
conn.close()
