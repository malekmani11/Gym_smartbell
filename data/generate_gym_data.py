import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta
from faker import Faker
import os

fake = Faker(['fr_FR'])
random.seed(42)
np.random.seed(42)

os.makedirs('/home/claude/data', exist_ok=True)

print("🏋️ GymAdmin — Génération des données (1000 membres)...")

# ═══════════════════════════════════════════════════════
# CONFIG
# ═══════════════════════════════════════════════════════
PLANS = {
    'CrossFit Elite':    {'price': 89,  'weight': 0.30},
    'Standard Premium':  {'price': 49,  'weight': 0.35},
    'Yoga Flow':         {'price': 59,  'weight': 0.20},
    'Day Pass':          {'price': 15,  'weight': 0.15},
}
PLAN_NAMES   = list(PLANS.keys())
PLAN_WEIGHTS = [PLANS[p]['weight'] for p in PLAN_NAMES]

TUNISIAN_FIRST_M = ['Mohamed','Ahmed','Youssef','Karim','Sami','Bilel',
                    'Hamza','Amine','Riadh','Nizar','Tarek','Hedi',
                    'Walid','Malek','Zied','Fares','Slim','Bassem']
TUNISIAN_FIRST_F = ['Sara','Nour','Ines','Yasmine','Rania','Lina',
                    'Amira','Fatma','Sonia','Meriem','Salma','Dorra',
                    'Cyrine','Olfa','Rim','Hana','Asma','Wafa']
TUNISIAN_LAST   = ['Ben Ali','Chaabane','Trabelsi','Mansour','Hamdi',
                   'Belhadj','Ayari','Belhaj','Dridi','Farhat',
                   'Guesmi','Haddad','Jlassi','Karray','Lassoued',
                   'Meddeb','Nasr','Oueslati','Riahi','Saad',
                   'Tlili','Turki','Zghal','Zouari','Ben Salem']
CITIES = ['Tunis','Sfax','Sousse','Monastir','Bizerte',
          'Nabeul','Kairouan','Ariana','Ben Arous','La Marsa']

TODAY      = datetime.now()
START_DATE = TODAY - timedelta(days=540)   # 18 mois

# ═══════════════════════════════════════════════════════
# 1. MEMBERS (1000)
# ═══════════════════════════════════════════════════════
members = []
for i in range(1, 1001):
    gender = 'M' if random.random() < 0.60 else 'F'
    fname  = random.choice(TUNISIAN_FIRST_M if gender == 'M' else TUNISIAN_FIRST_F)
    lname  = random.choice(TUNISIAN_LAST)

    # Saisonnalité : moins d'inscriptions en juil/août
    join_days_ago = random.randint(1, 540)
    join_date     = TODAY - timedelta(days=join_days_ago)
    month         = join_date.month
    if month in [7, 8] and random.random() < 0.4:
        join_date = join_date - timedelta(days=random.randint(30, 60))

    # Statut cohérent avec ancienneté
    days_since = (TODAY - join_date).days
    if days_since < 30:
        status = random.choices(['ACTIVE','PENDING'], weights=[0.7,0.3])[0]
    elif days_since < 365:
        status = random.choices(['ACTIVE','EXPIRED','PENDING'], weights=[0.72,0.20,0.08])[0]
    else:
        status = random.choices(['ACTIVE','EXPIRED','PENDING'], weights=[0.65,0.28,0.07])[0]

    plan = random.choices(PLAN_NAMES, weights=PLAN_WEIGHTS)[0]
    birth_year = random.randint(TODAY.year - 60, TODAY.year - 18)
    birth_date = fake.date_of_birth(minimum_age=18, maximum_age=60)

    members.append({
        'member_id':         i,
        'first_name':        fname,
        'last_name':         lname,
        'full_name':         f"{fname} {lname}",
        'email':             f"{fname.lower()}.{lname.lower().replace(' ','')}_{i}@gmail.com",
        'phone':             f"+216 {random.randint(20,99)} {random.randint(100,999)} {random.randint(100,999)}",
        'gender':            gender,
        'birth_date':        birth_date.strftime('%Y-%m-%d'),
        'join_date':         join_date.strftime('%Y-%m-%d'),
        'membership_status': status,
        'plan_name':         plan,
        'city':              random.choice(CITIES),
        'address':           fake.address().replace('\n', ', '),
    })

df_members = pd.DataFrame(members)
df_members.to_csv('/home/claude/data/members.csv', index=False, encoding='utf-8-sig')
print(f"✅ members.csv         → {len(df_members)} lignes")

# ═══════════════════════════════════════════════════════
# 2. SUBSCRIPTIONS (1800)
# ═══════════════════════════════════════════════════════
subscriptions = []
sub_id = 1
for _, m in df_members.iterrows():
    join_date = datetime.strptime(m['join_date'], '%Y-%m-%d')
    days_member = (TODAY - join_date).days
    n_subs = max(1, days_member // 30 + random.randint(-1, 1))
    n_subs = min(n_subs, 18)

    current_start = join_date
    for s in range(n_subs):
        plan      = m['plan_name'] if s == n_subs - 1 else random.choices(PLAN_NAMES, weights=PLAN_WEIGHTS)[0]
        price     = PLANS[plan]['price']
        duration  = 30 if plan != 'Day Pass' else 1
        end_date  = current_start + timedelta(days=duration)
        is_last   = (s == n_subs - 1)

        if is_last and m['membership_status'] == 'ACTIVE':
            status = 'ACTIVE'
            end_date = TODAY + timedelta(days=random.randint(1, 30))
        elif is_last and m['membership_status'] == 'PENDING':
            status = 'PENDING'
        elif end_date < TODAY:
            status = 'EXPIRED'
        else:
            status = 'ACTIVE'

        subscriptions.append({
            'sub_id':         sub_id,
            'member_id':      m['member_id'],
            'plan_name':      plan,
            'price':          price,
            'start_date':     current_start.strftime('%Y-%m-%d'),
            'end_date':       end_date.strftime('%Y-%m-%d'),
            'status':         status,
            'payment_method': random.choices(['CASH','CARD','VIREMENT'], weights=[0.50,0.35,0.15])[0],
        })
        sub_id        += 1
        current_start  = end_date + timedelta(days=random.randint(0, 5))
        if current_start > TODAY:
            break

df_subs = pd.DataFrame(subscriptions)
df_subs.to_csv('/home/claude/data/subscriptions.csv', index=False, encoding='utf-8-sig')
print(f"✅ subscriptions.csv   → {len(df_subs)} lignes")

# ═══════════════════════════════════════════════════════
# 3. PAYMENTS (2500+)
# ═══════════════════════════════════════════════════════
payments = []
pay_id = 1
for _, sub in df_subs.iterrows():
    if sub['plan_name'] == 'Day Pass':
        n_payments = random.randint(1, 4)
    else:
        start = datetime.strptime(sub['start_date'], '%Y-%m-%d')
        end   = datetime.strptime(sub['end_date'],   '%Y-%m-%d')
        n_payments = max(1, (end - start).days // 30)

    for _ in range(n_payments):
        pay_date = datetime.strptime(sub['start_date'], '%Y-%m-%d') + timedelta(days=random.randint(0, 5))
        status   = random.choices(['PAID','PENDING','FAILED'], weights=[0.85,0.10,0.05])[0]
        amount   = sub['price'] * random.uniform(0.95, 1.05)

        payments.append({
            'payment_id':   pay_id,
            'member_id':    sub['member_id'],
            'sub_id':       sub['sub_id'],
            'amount':       round(amount, 2),
            'payment_date': pay_date.strftime('%Y-%m-%d'),
            'month':        pay_date.strftime('%Y-%m'),
            'method':       sub['payment_method'],
            'status':       status,
            'plan_name':    sub['plan_name'],
        })
        pay_id += 1

df_pay = pd.DataFrame(payments)
df_pay.to_csv('/home/claude/data/payments.csv', index=False, encoding='utf-8-sig')
print(f"✅ payments.csv        → {len(df_pay)} lignes")

# ═══════════════════════════════════════════════════════
# 4. COACHES (10)
# ═══════════════════════════════════════════════════════
coaches_data = [
    (1,'Mohamed','Harrabi','CrossFit',   'ACTIVE', 1800),
    (2,'Salma',  'Driri',  'Yoga',       'ACTIVE', 1500),
    (3,'Ahmed',  'Khalil', 'Cardio',     'ACTIVE', 1600),
    (4,'Rania',  'Belhaj', 'Powerlifting','ACTIVE',1700),
    (5,'Karim',  'Nasri',  'Boxing',     'ACTIVE', 1550),
    (6,'Ines',   'Triki',  'Dance',      'ACTIVE', 1450),
    (7,'Youssef','Miled',  'CrossFit',   'ABSENT', 1800),
    (8,'Nour',   'Ayari',  'Yoga',       'ACTIVE', 1500),
    (9,'Slim',   'Farhat', 'Cardio',     'ACTIVE', 1600),
    (10,'Sara',  'Guesmi', 'Powerlifting','ACTIVE',1650),
]
df_coaches = pd.DataFrame(coaches_data, columns=[
    'coach_id','first_name','last_name','speciality','status','monthly_salary'])
df_coaches['full_name']  = df_coaches['first_name'] + ' ' + df_coaches['last_name']
df_coaches['email']      = df_coaches.apply(lambda r: f"{r.first_name.lower()}.{r.last_name.lower()}@gymadmin.tn", axis=1)
df_coaches['hire_date']  = [(TODAY - timedelta(days=random.randint(180,1200))).strftime('%Y-%m-%d') for _ in range(10)]
df_coaches['rating']     = [round(random.uniform(3.8, 5.0), 1) for _ in range(10)]
df_coaches.to_csv('/home/claude/data/coaches.csv', index=False, encoding='utf-8-sig')
print(f"✅ coaches.csv         → {len(df_coaches)} lignes")

# ═══════════════════════════════════════════════════════
# 5. COURSES (20)
# ═══════════════════════════════════════════════════════
DAYS    = ['MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY']
ROOMS   = ['Salle A','Salle B','Salle C','Studio Yoga','Ring Boxe']
courses_list = []
course_configs = [
    ('CrossFit WOD',     1, 'MONDAY',    '08:00','09:00', 20,'CrossFit', 'Salle A'),
    ('CrossFit WOD',     7, 'TUESDAY',   '08:00','09:00', 20,'CrossFit', 'Salle A'),
    ('CrossFit Advanced',1, 'WEDNESDAY', '18:00','19:30', 15,'CrossFit', 'Salle A'),
    ('CrossFit WOD',     7, 'FRIDAY',    '07:00','08:00', 20,'CrossFit', 'Salle A'),
    ('CrossFit Weekend', 1, 'SATURDAY',  '09:00','10:30', 18,'CrossFit', 'Salle A'),
    ('Yoga Flow',        2, 'MONDAY',    '09:00','10:30', 15,'Yoga',     'Studio Yoga'),
    ('Yoga Débutant',    8, 'WEDNESDAY', '10:00','11:30', 12,'Yoga',     'Studio Yoga'),
    ('Yoga Avancé',      2, 'FRIDAY',    '18:30','20:00', 12,'Yoga',     'Studio Yoga'),
    ('Yoga Weekend',     8, 'SATURDAY',  '10:00','11:30', 15,'Yoga',     'Studio Yoga'),
    ('Cardio HIIT',      3, 'TUESDAY',   '17:00','18:00', 25,'Cardio',   'Salle B'),
    ('Cardio HIIT',      9, 'THURSDAY',  '17:00','18:00', 25,'Cardio',   'Salle B'),
    ('Cardio Endurance', 3, 'SATURDAY',  '08:00','09:30', 20,'Cardio',   'Salle B'),
    ('Powerlifting',     4, 'MONDAY',    '19:00','20:30', 10,'Powerlifting','Salle C'),
    ('Powerlifting',     10,'WEDNESDAY', '19:00','20:30', 10,'Powerlifting','Salle C'),
    ('Powerlifting',     4, 'FRIDAY',    '19:00','20:30', 10,'Powerlifting','Salle C'),
    ('Boxing Fitness',   5, 'TUESDAY',   '19:00','20:00', 16,'Boxing',   'Ring Boxe'),
    ('Boxing Fitness',   5, 'THURSDAY',  '19:00','20:00', 16,'Boxing',   'Ring Boxe'),
    ('Boxing Avancé',    5, 'SATURDAY',  '11:00','12:30', 12,'Boxing',   'Ring Boxe'),
    ('Dance Fitness',    6, 'WEDNESDAY', '17:00','18:00', 20,'Dance',    'Salle B'),
    ('Dance Weekend',    6, 'SUNDAY',    '10:00','11:30', 18,'Dance',    'Salle B'),
]
for idx, (name, cid, day, st, et, maxp, ctype, room) in enumerate(course_configs, 1):
    courses_list.append({
        'course_id':            idx,
        'name':                 name,
        'coach_id':             cid,
        'coach_name':           df_coaches.loc[df_coaches['coach_id']==cid,'full_name'].values[0],
        'day_of_week':          day,
        'start_time':           st,
        'end_time':             et,
        'max_participants':     maxp,
        'current_participants': random.randint(int(maxp*0.5), maxp),
        'course_type':          ctype,
        'room':                 room,
    })
df_courses = pd.DataFrame(courses_list)
df_courses.to_csv('/home/claude/data/courses.csv', index=False, encoding='utf-8-sig')
print(f"✅ courses.csv         → {len(df_courses)} lignes")

# ═══════════════════════════════════════════════════════
# 6. ATTENDANCE (8000+)
# ═══════════════════════════════════════════════════════
PEAK_HOURS  = list(range(17, 21))
NORMAL_HOURS= list(range(7, 17))
DAY_MAP     = {'MONDAY':0,'TUESDAY':1,'WEDNESDAY':2,'THURSDAY':3,
               'FRIDAY':4,'SATURDAY':5,'SUNDAY':6}

active_members = df_members[df_members['membership_status'] == 'ACTIVE']['member_id'].tolist()
attendance     = []
att_id         = 1

for _, m in df_members[df_members['membership_status'] == 'ACTIVE'].iterrows():
    join_date  = datetime.strptime(m['join_date'], '%Y-%m-%d')
    start_att  = max(join_date, TODAY - timedelta(days=180))
    days_range = (TODAY - start_att).days

    # Fréquence selon plan
    if m['plan_name'] == 'CrossFit Elite':
        freq = random.uniform(3.5, 5.0)
    elif m['plan_name'] == 'Standard Premium':
        freq = random.uniform(2.0, 3.5)
    elif m['plan_name'] == 'Yoga Flow':
        freq = random.uniform(2.0, 3.0)
    else:
        freq = random.uniform(0.5, 1.5)

    n_sessions = int(days_range * freq / 7)
    if n_sessions == 0:
        continue

    for _ in range(n_sessions):
        att_date = start_att + timedelta(days=random.randint(0, days_range))
        if att_date > TODAY:
            continue

        # Heure de pointe 70%
        if random.random() < 0.70:
            hour = random.choice(PEAK_HOURS)
        else:
            hour = random.choice(NORMAL_HOURS)

        minute    = random.choice([0, 15, 30, 45])
        checkin   = att_date.replace(hour=hour, minute=minute)
        duration  = random.randint(45, 90)
        checkout  = checkin + timedelta(minutes=duration)

        # Cours cohérent avec le jour
        day_name  = ['MONDAY','TUESDAY','WEDNESDAY','THURSDAY',
                     'FRIDAY','SATURDAY','SUNDAY'][att_date.weekday()]
        day_courses = df_courses[df_courses['day_of_week'] == day_name]
        if len(day_courses) == 0:
            course_id = random.choice(df_courses['course_id'].tolist())
        else:
            course_id = random.choice(day_courses['course_id'].tolist())

        attendance.append({
            'attendance_id':   att_id,
            'member_id':       m['member_id'],
            'member_name':     m['full_name'],
            'course_id':       course_id,
            'attendance_date': att_date.strftime('%Y-%m-%d'),
            'day_of_week':     day_name,
            'check_in_time':   checkin.strftime('%H:%M'),
            'check_out_time':  checkout.strftime('%H:%M'),
            'duration_minutes':duration,
            'hour':            hour,
            'month':           att_date.strftime('%Y-%m'),
        })
        att_id += 1

df_att = pd.DataFrame(attendance)
df_att.to_csv('/home/claude/data/attendance.csv', index=False, encoding='utf-8-sig')
print(f"✅ attendance.csv      → {len(df_att)} lignes")

# ═══════════════════════════════════════════════════════
# 7. EQUIPMENT (40)
# ═══════════════════════════════════════════════════════
equipment_list = []
EQUIP_TYPES = [
    ('Tapis de course',     'Cardio',        2500),
    ('Vélo elliptique',     'Cardio',        1800),
    ('Rameur',              'Cardio',        2200),
    ('Barre olympique',     'Musculation',    300),
    ('Haltères 20kg',       'Musculation',    150),
    ('Cage à squat',        'Musculation',   3500),
    ('Presse à cuisses',    'Machines',      4000),
    ('Poulie haute/basse',  'Machines',      3200),
    ('Banc de musculation', 'Musculation',    600),
    ('Corde à sauter',      'Cardio',          30),
]
for eq_id in range(1, 41):
    name, cat, price = random.choice(EQUIP_TYPES)
    purchase = TODAY - timedelta(days=random.randint(30, 1800))
    last_maint = purchase + timedelta(days=random.randint(30, (TODAY-purchase).days))
    status = random.choices(['OPERATIONAL','MAINTENANCE','BROKEN'], weights=[0.75,0.15,0.10])[0]
    equipment_list.append({
        'equipment_id':         eq_id,
        'name':                 f"{name} #{eq_id}",
        'category':             cat,
        'purchase_date':        purchase.strftime('%Y-%m-%d'),
        'last_maintenance_date':last_maint.strftime('%Y-%m-%d'),
        'status':               status,
        'purchase_price':       price,
        'room':                 random.choice(ROOMS),
    })
df_equip = pd.DataFrame(equipment_list)
df_equip.to_csv('/home/claude/data/equipment.csv', index=False, encoding='utf-8-sig')
print(f"✅ equipment.csv       → {len(df_equip)} lignes")

# ═══════════════════════════════════════════════════════
# 8. COMPLAINTS (80)
# ═══════════════════════════════════════════════════════
subjects = [
    'Équipement défectueux','Vestiaires sales','Coach absent',
    'Cours annulé sans prévenir','Problème de facturation',
    'Musique trop forte','Climatisation défaillante',
    'Manque de matériel','Horaires non respectés','Autre',
]
complaints = []
sample_members = df_members.sample(80)['member_id'].tolist()
for c_id, mid in enumerate(sample_members, 1):
    created = TODAY - timedelta(days=random.randint(1, 180))
    status  = random.choices(['OPEN','RESOLVED','PENDING'], weights=[0.25,0.55,0.20])[0]
    resolved_date = None
    if status == 'RESOLVED':
        resolved_date = (created + timedelta(days=random.randint(1, 14))).strftime('%Y-%m-%d')
    complaints.append({
        'complaint_id':  c_id,
        'member_id':     mid,
        'subject':       random.choice(subjects),
        'description':   fake.sentence(nb_words=12),
        'created_date':  created.strftime('%Y-%m-%d'),
        'status':        status,
        'priority':      random.choices(['LOW','MEDIUM','HIGH'], weights=[0.40,0.40,0.20])[0],
        'resolved_date': resolved_date,
    })
df_comp = pd.DataFrame(complaints)
df_comp.to_csv('/home/claude/data/complaints.csv', index=False, encoding='utf-8-sig')
print(f"✅ complaints.csv      → {len(df_comp)} lignes")

# ═══════════════════════════════════════════════════════
# 9. SUMMARY STATS
# ═══════════════════════════════════════════════════════
active_count   = len(df_members[df_members['membership_status']=='ACTIVE'])
expired_count  = len(df_members[df_members['membership_status']=='EXPIRED'])
pending_count  = len(df_members[df_members['membership_status']=='PENDING'])

last_month     = (TODAY.replace(day=1) - timedelta(days=1)).strftime('%Y-%m')
rev_last_month = df_pay[
    (df_pay['month'] == last_month) & (df_pay['status'] == 'PAID')
]['amount'].sum()
rev_6months    = df_pay[
    (df_pay['payment_date'] >= (TODAY - timedelta(days=180)).strftime('%Y-%m-%d')) &
    (df_pay['status'] == 'PAID')
]['amount'].sum()

avg_sessions   = round(len(df_att) / max(active_count, 1), 1)
retention      = round(active_count / len(df_members) * 100, 1)
churn          = round(100 - retention, 1)

top_course     = df_att.merge(df_courses[['course_id','name']], on='course_id')['name'].value_counts().index[0]
busiest_day    = df_att['day_of_week'].value_counts().index[0]
busiest_hour   = df_att['hour'].value_counts().index[0]
top_coach      = df_coaches.loc[df_coaches['rating'].idxmax(), 'full_name']
top_plan       = df_members['plan_name'].value_counts().index[0]

summary = pd.DataFrame([{
    'total_members':          len(df_members),
    'active_members':         active_count,
    'expired_members':        expired_count,
    'pending_members':        pending_count,
    'total_coaches':          len(df_coaches),
    'total_courses':          len(df_courses),
    'total_subscriptions':    len(df_subs),
    'total_payments':         len(df_pay),
    'total_attendance':       len(df_att),
    'total_complaints':       len(df_comp),
    'revenue_last_month_DT':  round(rev_last_month, 2),
    'revenue_last_6months_DT':round(rev_6months, 2),
    'avg_sessions_per_member':avg_sessions,
    'retention_rate_pct':     retention,
    'churn_rate_pct':         churn,
    'most_popular_course':    top_course,
    'busiest_day':            busiest_day,
    'busiest_hour':           f"{busiest_hour}h",
    'top_rated_coach':        top_coach,
    'most_popular_plan':      top_plan,
}])
summary.to_csv('/home/claude/data/summary_stats.csv', index=False, encoding='utf-8-sig')
print(f"✅ summary_stats.csv   → 1 ligne (résumé global)")

# ═══════════════════════════════════════════════════════
# RÉSUMÉ FINAL
# ═══════════════════════════════════════════════════════
print("\n" + "═"*50)
print("📊 RÉSUMÉ FINAL")
print("═"*50)
print(f"  👥 Membres total     : {len(df_members)}")
print(f"  ✅ Actifs            : {active_count} ({retention}%)")
print(f"  ❌ Expirés           : {expired_count} ({churn}%)")
print(f"  📋 Abonnements       : {len(df_subs)}")
print(f"  💰 Paiements         : {len(df_pay)}")
print(f"  🏋️  Présences         : {len(df_att)}")
print(f"  👨‍🏫 Coachs             : {len(df_coaches)}")
print(f"  📅 Cours             : {len(df_courses)}")
print(f"  🔧 Équipements       : {len(df_equip)}")
print(f"  📝 Plaintes          : {len(df_comp)}")
print(f"\n  💵 CA dernier mois   : {round(rev_last_month,2)} DT")
print(f"  💵 CA 6 derniers mois: {round(rev_6months,2)} DT")
print(f"  📈 Rétention         : {retention}%")
print(f"  🏆 Cours populaire   : {top_course}")
print(f"  ⏰ Heure de pointe   : {busiest_hour}h")
print(f"  📅 Jour le + chargé  : {busiest_day}")
print("═"*50)
print(f"\n📁 Fichiers exportés dans : /home/claude/data/")
