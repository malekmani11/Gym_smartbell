import pymysql

conn = pymysql.connect(host='localhost', port=3308, user='root', password='', database='gym_smartbell')
c = conn.cursor()

print('=' * 55)
print('📊 RÉSUMÉ FINAL — gym_smartbell')
print('=' * 55)

c.execute('SHOW TABLES')
tables = [r[0] for r in c.fetchall()]

for t in tables:
    c.execute(f'SELECT COUNT(*) FROM {t}')
    count = c.fetchone()[0]
    icon = '✅' if count > 0 else '⬜'
    print(f'  {icon} {t:<30} → {count:>6} lignes')

print('=' * 55)
print()
print('📈 STATS DÉTAILLÉES')
print('-' * 55)

c.execute('SELECT membership_status, COUNT(*) FROM members GROUP BY membership_status')
print('Members par statut:')
for r in c.fetchall():
    print(f'   {r[0]}: {r[1]}')

c.execute('SELECT status, COUNT(*) FROM payments GROUP BY status')
print('Payments par statut:')
for r in c.fetchall():
    print(f'   {r[0]}: {r[1]}')

c.execute('SELECT status, COUNT(*) FROM subscriptions GROUP BY status')
print('Subscriptions par statut:')
for r in c.fetchall():
    print(f'   {r[0]}: {r[1]}')

c.execute('SELECT availability_status, COUNT(*) FROM coaches GROUP BY availability_status')
print('Coaches par statut:')
for r in c.fetchall():
    print(f'   {r[0]}: {r[1]}')

c.execute('SELECT status, COUNT(*) FROM machines GROUP BY status')
print('Machines par statut:')
for r in c.fetchall():
    print(f'   {r[0]}: {r[1]}')

c.execute('SELECT day_of_week, COUNT(*) FROM courses GROUP BY day_of_week')
print('Cours par jour:')
for r in c.fetchall():
    print(f'   {r[0]}: {r[1]}')

c.execute('SELECT gender, COUNT(*) FROM users GROUP BY gender')
print('Users par genre:')
for r in c.fetchall():
    print(f'   {r[0]}: {r[1]}')

print('=' * 55)
conn.close()
