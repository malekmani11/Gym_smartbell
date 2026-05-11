import pymysql

conn = pymysql.connect(host='localhost', port=3308, user='root', password='', database='gym_smartbell', charset='utf8mb4')
c = conn.cursor()

print('=' * 60)
print('DIAGNOSTIC SALLES')
print('=' * 60)

# Check salles table structure
print('\n1. Colonnes de la table salles:')
c.execute('DESCRIBE salles')
for row in c.fetchall():
    print(f'   {row[0]:<25} {row[1]:<30} null={row[2]} default={row[4]}')

# Check actual data in salles
print('\n2. Données dans salles:')
c.execute('SELECT * FROM salles')
rows = c.fetchall()
c.execute('DESCRIBE salles')
cols = [r[0] for r in c.fetchall()]
print(f'   Colonnes: {cols}')
for row in rows:
    print(f'   {dict(zip(cols, row))}')

# Check courses salle_id
print('\n3. Cours et leur salle_id:')
c.execute('SELECT id, name, salle_id, day_of_week FROM courses')
for row in c.fetchall():
    print(f'   id={row[0]} name={row[1]} salle_id={row[2]} day={row[3]}')

# Check if current_occupancy is NULL
print('\n4. Salles avec current_occupancy NULL:')
c.execute("SELECT id, name, current_occupancy, status FROM salles WHERE current_occupancy IS NULL")
nulls = c.fetchall()
if nulls:
    print(f'   {len(nulls)} salles ont current_occupancy=NULL')
    for row in nulls:
        print(f'   id={row[0]} name={row[1]} current_occupancy={row[2]} status={row[3]}')
else:
    print('   Aucune (OK)')

print('\n' + '=' * 60)
print('FIXES')
print('=' * 60)

# Fix 1: Set current_occupancy = 0 where NULL
c.execute("UPDATE salles SET current_occupancy = 0 WHERE current_occupancy IS NULL")
if c.rowcount > 0:
    print(f'   Fixed {c.rowcount} salles: current_occupancy NULL → 0')
else:
    print('   current_occupancy: OK (no nulls)')

# Fix 2: Assign salle_id to courses
print('\n   Assigning salle_id to courses...')
c.execute('SELECT id FROM salles ORDER BY id')
salle_ids = [r[0] for r in c.fetchall()]
print(f'   Salles disponibles: {salle_ids}')

if salle_ids:
    # CrossFit courses → salle_ids[0] (Salle A)
    c.execute("UPDATE courses SET salle_id = %s WHERE name LIKE '%CrossFit%'", (salle_ids[0],))
    print(f'   CrossFit → salle {salle_ids[0]}: {c.rowcount} cours')

    # Cardio HIIT, Cardio → salle_ids[0] (Salle A)
    c.execute("UPDATE courses SET salle_id = %s WHERE name LIKE '%Cardio%'", (salle_ids[0],))
    print(f'   Cardio → salle {salle_ids[0]}: {c.rowcount} cours')

    # Yoga → salle_ids[3] (Studio Yoga) or salle_ids[1]
    yoga_salle = salle_ids[3] if len(salle_ids) > 3 else salle_ids[-1]
    c.execute("UPDATE courses SET salle_id = %s WHERE name LIKE '%Yoga%'", (yoga_salle,))
    print(f'   Yoga → salle {yoga_salle}: {c.rowcount} cours')

    # Powerlifting → salle_ids[2] (Salle C)
    power_salle = salle_ids[2] if len(salle_ids) > 2 else salle_ids[-1]
    c.execute("UPDATE courses SET salle_id = %s WHERE name LIKE '%Powerlifting%'", (power_salle,))
    print(f'   Powerlifting → salle {power_salle}: {c.rowcount} cours')

    # Boxing → salle_ids[4] (Ring Boxe) or last
    boxing_salle = salle_ids[4] if len(salle_ids) > 4 else salle_ids[-1]
    c.execute("UPDATE courses SET salle_id = %s WHERE name LIKE '%Box%'", (boxing_salle,))
    print(f'   Boxing → salle {boxing_salle}: {c.rowcount} cours')

    # Dance → salle_ids[3] (Studio Yoga)
    c.execute("UPDATE courses SET salle_id = %s WHERE name LIKE '%Dance%'", (yoga_salle,))
    print(f'   Dance → salle {yoga_salle}: {c.rowcount} cours')

    # Any remaining NULL salle_id → salle_ids[0]
    c.execute("UPDATE courses SET salle_id = %s WHERE salle_id IS NULL", (salle_ids[0],))
    if c.rowcount > 0:
        print(f'   Remaining → salle {salle_ids[0]}: {c.rowcount} cours')

conn.commit()

# Verify
print('\n' + '=' * 60)
print('VERIFICATION')
print('=' * 60)
c.execute('SELECT id, name, salle_id, day_of_week FROM courses ORDER BY id')
for row in c.fetchall():
    print(f'   course {row[0]} "{row[1]}" → salle_id={row[2]} ({row[3]})')

c.execute('SELECT id, name, status, current_occupancy FROM salles')
print('\nSalles:')
for row in c.fetchall():
    print(f'   salle {row[0]} "{row[1]}" status={row[2]} occupancy={row[3]}')

print('\nDone!')
c.close()
conn.close()
