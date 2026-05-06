import pymysql
import random
from datetime import datetime, timedelta

random.seed(42)

DB_CONFIG = {
    'host': 'localhost', 'port': 3306,
    'user': 'root', 'password': '',
    'database': 'gym_smartbell', 'charset': 'utf8mb4',
}

TODAY = datetime.now()
PLANS = {
    'CrossFit Elite':   {'price': 89,  'weight': 0.30},
    'Standard Premium': {'price': 49,  'weight': 0.35},
    'Yoga Flow':        {'price': 59,  'weight': 0.20},
    'Day Pass':         {'price': 15,  'weight': 0.15},
}
PLAN_NAMES   = list(PLANS.keys())
PLAN_WEIGHTS = [PLANS[p]['weight'] for p in PLAN_NAMES]

print("💰 Import Payments & Subscriptions")
print("=" * 45)

conn   = pymysql.connect(**DB_CONFIG)
cursor = conn.cursor()
print("✅ Connexion OK")

def get_columns(table):
    cursor.execute(f"DESCRIBE {table}")
    return [row[0] for row in cursor.fetchall()]

def table_exists(table):
    cursor.execute(f"SHOW TABLES LIKE '{table}'")
    return cursor.fetchone() is not None

# Récupère les user_ids des membres
cursor.execute("SELECT user_id FROM members LIMIT 800")
mids = [r[0] for r in cursor.fetchall()]
print(f"   Membres trouvés : {len(mids)}")

# ═══════════════════════════════════════════════════════
# SUBSCRIPTIONS D'ABORD (car payments référence subscription_id)
# ═══════════════════════════════════════════════════════
print("\n📥 Import subscriptions...")
cursor.execute("SELECT COUNT(*) FROM subscriptions")
if cursor.fetchone()[0] >= 100:
    print("   ℹ️  Déjà présents — skip")
else:
    sub_cols = get_columns('subscriptions')
    print(f"   Colonnes : {sub_cols}")
    
    # Trouver plan_id valide si nécessaire
    plan_id = None
    if 'plan_id' in sub_cols:
        cursor.execute("SELECT id FROM subscription_plans LIMIT 1") if table_exists('subscription_plans') else None
        r = cursor.fetchone() if table_exists('subscription_plans') else None
        plan_id = r[0] if r else 1

    n = 0
    sub_ids = {}  # user_id → sub_id
    cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
    
    for mid in mids:
        sd  = TODAY - timedelta(days=random.randint(1, 365))
        ed  = sd + timedelta(days=30)
        # status ENUM : ACTIVE, EXPIRED, CANCELLED
        st  = 'ACTIVE' if ed > TODAY else 'EXPIRED'
        now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

        sc = {
            'user_id':    mid,
            'start_date': sd.strftime('%Y-%m-%d'),
            'end_date':   ed.strftime('%Y-%m-%d'),
            'status':     st,
            'created_at': now,
            'plan_id':    plan_id,
            'coupon_id':  None,
        }

        ic = [c for c in sub_cols if c in sc and sc[c] is not None and c != 'id']
        iv = [sc[c] for c in ic]

        if ic:
            try:
                cursor.execute(
                    f"INSERT INTO subscriptions ({','.join(ic)}) VALUES ({','.join(['%s']*len(ic))})",
                    iv
                )
                sub_id = cursor.lastrowid
                sub_ids[mid] = sub_id
                n += 1
            except Exception as e:
                if n < 3: print(f"   ⚠️  {e}")

    conn.commit()
    cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
    print(f"   ✅ {n} abonnements importés")

# Recharge les sub_ids si déjà existants
if not sub_ids:
    cursor.execute("SELECT user_id, id FROM subscriptions LIMIT 800")
    sub_ids = {r[0]: r[1] for r in cursor.fetchall()}

# ═══════════════════════════════════════════════════════
# PAYMENTS
# ═══════════════════════════════════════════════════════
print("\n📥 Import payments...")
cursor.execute("SELECT COUNT(*) FROM payments")
if cursor.fetchone()[0] >= 100:
    print("   ℹ️  Déjà présents — skip")
else:
    pay_cols = get_columns('payments')
    print(f"   Colonnes : {pay_cols}")

    # ENUM values
    # status  : PENDING, COMPLETED, FAILED, REFUNDED
    # method  : CASH, CARD, BANK_TRANSFER
    PAY_STATUSES = ['COMPLETED','COMPLETED','COMPLETED','COMPLETED','COMPLETED',
                    'PENDING','PENDING','FAILED','REFUNDED']
    PAY_METHODS  = ['CASH','CASH','CASH','CARD','CARD','BANK_TRANSFER']

    n = 0
    cursor.execute("SET FOREIGN_KEY_CHECKS = 0")

    for mid in mids:
        sub_id = sub_ids.get(mid)
        for _ in range(random.randint(2, 8)):
            plan   = random.choices(PLAN_NAMES, weights=PLAN_WEIGHTS)[0]
            amount = round(PLANS[plan]['price'] * random.uniform(0.95, 1.05), 2)
            pdate  = TODAY - timedelta(days=random.randint(1, 500))
            method = random.choice(PAY_METHODS)
            status = random.choice(PAY_STATUSES)
            ref    = f"TXN{random.randint(100000,999999)}"
            now    = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

            pc = {
                'amount':          amount,
                'payment_date':    pdate.strftime('%Y-%m-%d'),
                'payment_method':  method,
                'status':          status,
                'transaction_ref': ref,
                'subscription_id': sub_id,
                'created_at':      now,
                'user_id':         mid,
                'member_id':       mid,
            }

            ic = [c for c in pay_cols if c in pc and pc[c] is not None and c != 'id']
            iv = [pc[c] for c in ic]

            if ic:
                try:
                    cursor.execute(
                        f"INSERT INTO payments ({','.join(ic)}) VALUES ({','.join(['%s']*len(ic))})",
                        iv
                    )
                    n += 1
                except Exception as e:
                    if n < 3: print(f"   ⚠️  {e}")

    conn.commit()
    cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
    print(f"   ✅ {n} paiements importés")

# ═══════════════════════════════════════════════════════
# RÉSUMÉ
# ═══════════════════════════════════════════════════════
print("\n" + "="*45)
print("📊 RÉSUMÉ gym_smartbell")
print("="*45)
for t in ['users','members','coaches','payments','subscriptions','complaints','courses']:
    cursor.execute(f"SHOW TABLES LIKE '{t}'")
    if cursor.fetchone():
        cursor.execute(f"SELECT COUNT(*) FROM {t}")
        print(f"  ✅ {t:<20} → {cursor.fetchone()[0]:>6} lignes")
print("="*45)
print("\n✅ Terminé ! 🚀")

cursor.close()
conn.close()
