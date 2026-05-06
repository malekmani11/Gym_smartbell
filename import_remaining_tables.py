import pymysql
import random
from datetime import datetime, timedelta
from faker import Faker

fake = Faker(['fr_FR'])
random.seed(42)

DB_CONFIG = {
    'host': 'localhost', 'port': 3306,
    'user': 'root', 'password': '',
    'database': 'gym_smartbell', 'charset': 'utf8mb4',
}

TODAY = datetime.now()

print("🏋️  Import tables restantes — gym_smartbell")
print("=" * 50)

conn   = pymysql.connect(**DB_CONFIG)
cursor = conn.cursor()
print("✅ Connexion OK")

def get_columns(table):
    cursor.execute(f"DESCRIBE {table}")
    return [row[0] for row in cursor.fetchall()]

def get_full_desc(table):
    cursor.execute(f"DESCRIBE {table}")
    return cursor.fetchall()

def table_exists(table):
    cursor.execute(f"SHOW TABLES LIKE '{table}'")
    return cursor.fetchone() is not None

def get_enum_values(table, column):
    cursor.execute(f"""SELECT COLUMN_TYPE FROM information_schema.COLUMNS 
                       WHERE TABLE_SCHEMA='gym_smartbell' 
                       AND TABLE_NAME='{table}' AND COLUMN_NAME='{column}'""")
    r = cursor.fetchone()
    if r and 'enum' in r[0]:
        return r[0].replace("enum(","").replace(")","").replace("'","").split(",")
    return []

def get_pk(table):
    cursor.execute(f"SHOW KEYS FROM {table} WHERE Key_name = 'PRIMARY'")
    r = cursor.fetchone()
    return r[4] if r else 'id'

# ═══════════════════════════════════════════════════════
# COURSES
# ═══════════════════════════════════════════════════════
print("\n📥 Import courses...")
if table_exists('courses'):
    course_cols = get_columns('courses')
    desc        = get_full_desc('courses')
    print(f"   Colonnes :")
    for row in desc:
        print(f"   {row[0]:<25} {row[1]:<35} null={row[2]}")

    cursor.execute("SELECT COUNT(*) FROM courses")
    existing = cursor.fetchone()[0]

    if existing >= 5:
        print(f"   ℹ️  {existing} cours déjà présents — skip")
    else:
        # Récupère les user_ids des coachs
        pk_coach = get_pk('coaches')
        cursor.execute(f"SELECT {pk_coach} FROM coaches LIMIT 8")
        coach_ids = [r[0] for r in cursor.fetchall()]
        print(f"   Coach IDs trouvés : {coach_ids}")

        if not coach_ids:
            print("   ⚠️  Aucun coach trouvé — utilise NULL")
            coach_ids = [None]

        courses_data = [
            ('CrossFit WOD',      'MONDAY',    '08:00:00', '09:00:00', 20, coach_ids[0]),
            ('CrossFit Advanced', 'WEDNESDAY', '18:00:00', '19:30:00', 15, coach_ids[0]),
            ('CrossFit Weekend',  'SATURDAY',  '09:00:00', '10:30:00', 18, coach_ids[0]),
            ('Yoga Flow',         'MONDAY',    '09:00:00', '10:30:00', 15, coach_ids[1] if len(coach_ids)>1 else coach_ids[0]),
            ('Yoga Débutant',     'WEDNESDAY', '10:00:00', '11:30:00', 12, coach_ids[1] if len(coach_ids)>1 else coach_ids[0]),
            ('Yoga Weekend',      'SATURDAY',  '10:00:00', '11:30:00', 15, coach_ids[1] if len(coach_ids)>1 else coach_ids[0]),
            ('Cardio HIIT',       'TUESDAY',   '17:00:00', '18:00:00', 25, coach_ids[2] if len(coach_ids)>2 else coach_ids[0]),
            ('Cardio Endurance',  'SATURDAY',  '08:00:00', '09:30:00', 20, coach_ids[2] if len(coach_ids)>2 else coach_ids[0]),
            ('Powerlifting',      'MONDAY',    '19:00:00', '20:30:00', 10, coach_ids[3] if len(coach_ids)>3 else coach_ids[0]),
            ('Powerlifting Adv',  'WEDNESDAY', '19:00:00', '20:30:00', 10, coach_ids[3] if len(coach_ids)>3 else coach_ids[0]),
            ('Boxing Fitness',    'TUESDAY',   '19:00:00', '20:00:00', 16, coach_ids[4] if len(coach_ids)>4 else coach_ids[0]),
            ('Boxing Avancé',     'SATURDAY',  '11:00:00', '12:30:00', 12, coach_ids[4] if len(coach_ids)>4 else coach_ids[0]),
            ('Dance Fitness',     'WEDNESDAY', '17:00:00', '18:00:00', 20, coach_ids[5] if len(coach_ids)>5 else coach_ids[0]),
            ('Dance Weekend',     'SUNDAY',    '10:00:00', '11:30:00', 18, coach_ids[5] if len(coach_ids)>5 else coach_ids[0]),
        ]

        avail_status = get_enum_values('courses', 'active')
        now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

        n = 0
        cursor.execute("SET FOREIGN_KEY_CHECKS = 0")

        for (name, day, start, end, maxp, cid) in courses_data:
            cr = {
                'name':             name,
                'day_of_week':      day,
                'start_time':       start,
                'end_time':         end,
                'max_participants': maxp,
                'coach_id':         cid,
                'description':      f"Cours de {name}",
                'location':         random.choice(['Salle A','Salle B','Salle C','Studio Yoga']),
                'active':           1,
                'created_at':       now,
                'updated_at':       now,
            }

            ic = [c for c in course_cols if c in cr and cr[c] is not None and c != 'id']
            iv = [cr[c] for c in ic]

            if ic:
                try:
                    cursor.execute(
                        f"INSERT INTO courses ({','.join(ic)}) VALUES ({','.join(['%s']*len(ic))})",
                        iv
                    )
                    n += 1
                except Exception as e:
                    print(f"   ⚠️  Course {name}: {e}")

        conn.commit()
        cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
        print(f"   ✅ {n} cours importés")
else:
    print("   ⚠️  Table courses non trouvée")

# ═══════════════════════════════════════════════════════
# MACHINES
# ═══════════════════════════════════════════════════════
print("\n📥 Import machines...")
if table_exists('machines'):
    mach_cols = get_columns('machines')
    desc      = get_full_desc('machines')
    print(f"   Colonnes :")
    for row in desc:
        print(f"   {row[0]:<25} {row[1]:<35} null={row[2]}")

    cursor.execute("SELECT COUNT(*) FROM machines")
    existing = cursor.fetchone()[0]

    if existing >= 10:
        print(f"   ℹ️  {existing} machines déjà présentes — skip")
    else:
        status_vals = get_enum_values('machines', 'status')
        print(f"   status values : {status_vals}")

        def map_status(val, vals):
            if not vals: return val
            mapping = {
                'OPERATIONAL': ['OPERATIONAL','ACTIVE','WORKING','OK','AVAILABLE'],
                'MAINTENANCE': ['MAINTENANCE','IN_MAINTENANCE','REPAIR','REPAIRING'],
                'BROKEN':      ['BROKEN','OUT_OF_ORDER','DAMAGED','INACTIVE','UNAVAILABLE'],
            }
            for v in vals:
                for target in mapping.get(val, [val]):
                    if v.upper() == target.upper():
                        return v
            return vals[0]

        machines_data = [
            ('Tapis de course #1',   'Cardio',      'OPERATIONAL', 2500, 'Salle A'),
            ('Tapis de course #2',   'Cardio',      'OPERATIONAL', 2500, 'Salle A'),
            ('Tapis de course #3',   'Cardio',      'MAINTENANCE', 2500, 'Salle A'),
            ('Vélo elliptique #1',   'Cardio',      'OPERATIONAL', 1800, 'Salle B'),
            ('Vélo elliptique #2',   'Cardio',      'OPERATIONAL', 1800, 'Salle B'),
            ('Rameur #1',            'Cardio',      'OPERATIONAL', 2200, 'Salle A'),
            ('Barre olympique #1',   'Musculation', 'OPERATIONAL',  300, 'Salle C'),
            ('Barre olympique #2',   'Musculation', 'OPERATIONAL',  300, 'Salle C'),
            ('Cage à squat #1',      'Musculation', 'OPERATIONAL', 3500, 'Salle C'),
            ('Cage à squat #2',      'Musculation', 'BROKEN',      3500, 'Salle C'),
            ('Presse à cuisses #1',  'Machines',    'OPERATIONAL', 4000, 'Salle B'),
            ('Presse à cuisses #2',  'Machines',    'OPERATIONAL', 4000, 'Salle B'),
            ('Poulie haute #1',      'Machines',    'OPERATIONAL', 3200, 'Salle B'),
            ('Banc musculation #1',  'Musculation', 'OPERATIONAL',  600, 'Salle C'),
            ('Banc musculation #2',  'Musculation', 'OPERATIONAL',  600, 'Salle C'),
            ('Haltères 20kg x2',     'Musculation', 'OPERATIONAL',  150, 'Salle C'),
            ('Haltères 30kg x2',     'Musculation', 'OPERATIONAL',  200, 'Salle C'),
            ('Tapis yoga x10',       'Yoga',        'OPERATIONAL',   30, 'Studio Yoga'),
            ('Corde à sauter x5',    'Cardio',      'OPERATIONAL',   25, 'Salle A'),
            ('Kettlebell 16kg x4',   'Musculation', 'OPERATIONAL',  120, 'Salle C'),
        ]

        n = 0
        now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        cursor.execute("SET FOREIGN_KEY_CHECKS = 0")

        for (name, category, status, price, room) in machines_data:
            purchase   = TODAY - timedelta(days=random.randint(30, 1800))
            last_maint = purchase + timedelta(days=random.randint(30, (TODAY-purchase).days))
            mapped_st  = map_status(status, status_vals)

            mc = {
                'name':                  name,
                'category':              category,
                'type':                  category,
                'status':                mapped_st,
                'purchase_price':        price,
                'price':                 price,
                'purchase_date':         purchase.strftime('%Y-%m-%d'),
                'last_maintenance_date': last_maint.strftime('%Y-%m-%d'),
                'last_maintenance':      last_maint.strftime('%Y-%m-%d'),
                'maintenance_date':      last_maint.strftime('%Y-%m-%d'),
                'room':                  room,
                'location':              room,
                'salle':                 room,
                'description':           f"Équipement {category}",
                'brand':                 random.choice(['TechnoGym','Life Fitness','Hammer','Generic']),
                'model':                 f"Model-{random.randint(100,999)}",
                'serial_number':         f"SN{random.randint(10000,99999)}",
                'quantity':              1,
                'created_at':            now,
                'updated_at':            now,
                'is_available':          1 if status == 'OPERATIONAL' else 0,
                'available':             1 if status == 'OPERATIONAL' else 0,
            }

            pk = get_pk('machines')
            ic = [c for c in mach_cols if c in mc and mc[c] is not None and c != pk]
            iv = [mc[c] for c in ic]

            if ic:
                try:
                    cursor.execute(
                        f"INSERT INTO machines ({','.join(ic)}) VALUES ({','.join(['%s']*len(ic))})",
                        iv
                    )
                    n += 1
                except Exception as e:
                    print(f"   ⚠️  Machine {name}: {e}")

        conn.commit()
        cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
        print(f"   ✅ {n} machines importées")
else:
    print("   ⚠️  Table machines non trouvée")

# ═══════════════════════════════════════════════════════
# EVENTS
# ═══════════════════════════════════════════════════════
print("\n📥 Import events...")
if table_exists('events'):
    event_cols = get_columns('events')
    desc       = get_full_desc('events')
    print(f"   Colonnes :")
    for row in desc:
        print(f"   {row[0]:<25} {row[1]:<35} null={row[2]}")

    cursor.execute("SELECT COUNT(*) FROM events")
    existing = cursor.fetchone()[0]

    if existing >= 3:
        print(f"   ℹ️  {existing} événements déjà présents — skip")
    else:
        status_vals = get_enum_values('events', 'status')
        type_vals   = get_enum_values('events', 'event_type')
        print(f"   status values     : {status_vals}")
        print(f"   event_type values : {type_vals}")

        def map_ev_status(vals):
            if not vals: return 'UPCOMING'
            for v in vals:
                if v.upper() in ['UPCOMING','ACTIVE','OPEN','PUBLISHED','SCHEDULED']:
                    return v
            return vals[0]

        events_data = [
            ('Tournoi CrossFit SmartBell', 'Compétition interne CrossFit', 30, 50),
            ('Journée Yoga & Bien-être',   'Séance yoga spéciale',         20, 30),
            ('Championnat Powerlifting',   'Compétition powerlifting',     15, 25),
            ('Open Day GymAdmin',          'Portes ouvertes salle',       100, 150),
            ('Séminaire Nutrition Sport',  'Conférence nutrition',         40, 60),
            ('Bootcamp Cardio Intensif',   'Bootcamp cardio',              25, 35),
        ]

        n = 0
        now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        cursor.execute("SET FOREIGN_KEY_CHECKS = 0")

        for idx, (title, desc_text, reg, cap) in enumerate(events_data):
            ev_date = TODAY + timedelta(days=random.randint(7, 90))
            st      = map_ev_status(status_vals)
            et      = type_vals[0] if type_vals else 'SPORT'

            ev = {
                'title':                title,
                'name':                 title,
                'description':          desc_text,
                'event_date':           ev_date.strftime('%Y-%m-%d'),
                'date':                 ev_date.strftime('%Y-%m-%d'),
                'start_date':           ev_date.strftime('%Y-%m-%d'),
                'end_date':             (ev_date + timedelta(days=1)).strftime('%Y-%m-%d'),
                'start_time':           '09:00:00',
                'end_time':             '18:00:00',
                'location':             'SmartBell Gym — Tunis',
                'max_participants':     cap,
                'capacity':             cap,
                'current_participants': reg,
                'registrations_count':  reg,
                'status':               st,
                'event_type':           et,
                'price':                random.choice([0, 20, 30, 50]),
                'is_free':              1 if random.random() < 0.3 else 0,
                'image_url':            '',
                'created_at':           now,
                'updated_at':           now,
            }

            pk = get_pk('events')
            ic = [c for c in event_cols if c in ev and ev[c] is not None and c != pk]
            iv = [ev[c] for c in ic]

            if ic:
                try:
                    cursor.execute(
                        f"INSERT INTO events ({','.join(ic)}) VALUES ({','.join(['%s']*len(ic))})",
                        iv
                    )
                    n += 1
                except Exception as e:
                    print(f"   ⚠️  Event {title}: {e}")

        conn.commit()
        cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
        print(f"   ✅ {n} événements importés")
else:
    print("   ⚠️  Table events non trouvée")

# ═══════════════════════════════════════════════════════
# SALLES
# ═══════════════════════════════════════════════════════
print("\n📥 Import salles...")
if table_exists('salles'):
    salle_cols = get_columns('salles')
    desc       = get_full_desc('salles')
    print(f"   Colonnes :")
    for row in desc:
        print(f"   {row[0]:<25} {row[1]:<35} null={row[2]}")

    cursor.execute("SELECT COUNT(*) FROM salles")
    existing = cursor.fetchone()[0]

    if existing >= 3:
        print(f"   ℹ️  {existing} salles déjà présentes — skip")
    else:
        salles_data = [
            ('Salle A',     'Cardio',      50, 'Rez-de-chaussée'),
            ('Salle B',     'Machines',    40, 'Rez-de-chaussée'),
            ('Salle C',     'Musculation', 35, '1er étage'),
            ('Studio Yoga', 'Yoga',        20, '1er étage'),
            ('Ring Boxe',   'Boxing',      15, '2ème étage'),
        ]

        status_vals = get_enum_values('salles', 'status')
        print(f"   status values : {status_vals}")

        n = 0
        now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        cursor.execute("SET FOREIGN_KEY_CHECKS = 0")

        for (name, stype, cap, floor) in salles_data:
            st = status_vals[0] if status_vals else 'ACTIVE'

            sl = {
                'name':        name,
                'nom':         name,
                'type':        stype,
                'capacity':    cap,
                'capacite':    cap,
                'floor':       floor,
                'etage':       floor,
                'location':    floor,
                'status':      st,
                'description': f"Salle {stype}",
                'created_at':  now,
                'updated_at':  now,
                'is_active':   1,
                'active':      1,
            }

            pk = get_pk('salles')
            ic = [c for c in salle_cols if c in sl and sl[c] is not None and c != pk]
            iv = [sl[c] for c in ic]

            if ic:
                try:
                    cursor.execute(
                        f"INSERT INTO salles ({','.join(ic)}) VALUES ({','.join(['%s']*len(ic))})",
                        iv
                    )
                    n += 1
                except Exception as e:
                    print(f"   ⚠️  Salle {name}: {e}")

        conn.commit()
        cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
        print(f"   ✅ {n} salles importées")
else:
    print("   ⚠️  Table salles non trouvée")

# ═══════════════════════════════════════════════════════
# RÉSUMÉ FINAL
# ═══════════════════════════════════════════════════════
print("\n" + "="*50)
print("📊 RÉSUMÉ FINAL — gym_smartbell")
print("="*50)
cursor.execute("SHOW TABLES")
for t in [r[0] for r in cursor.fetchall()]:
    cursor.execute(f"SELECT COUNT(*) FROM {t}")
    count = cursor.fetchone()[0]
    status = "✅" if count > 0 else "⬜"
    print(f"  {status} {t:<30} → {count:>6} lignes")
print("="*50)
print("\n✅ Import terminé ! 🚀")

cursor.close()
conn.close()
